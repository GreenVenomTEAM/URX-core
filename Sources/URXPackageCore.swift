import Foundation

/// Data-only APT package model. This layer never extracts archives or executes package scripts.
struct URXPackageRecord: Identifiable, Hashable {
    let id: String
    let version: String
    let architecture: String
    let maintainer: String
    let description: String
    let filename: String
    let size: Int?
    let sha256: String?
    let preDependencies: [[URXPackageDependency]]
    let dependencies: [[URXPackageDependency]]
    let provides: [URXPackageDependency]
    let fields: [String: String]

    var packageID: String { id }
}

struct URXPackageDependency: Hashable {
    let package: String
    let relation: String?
    let version: String?

    var display: String {
        guard let relation, let version else { return package }
        return "\(package) (\(relation) \(version))"
    }
}

enum URXPackageIndexError: LocalizedError {
    case malformedField(Int)
    case missingField(String)
    case invalidSize(String)

    var errorDescription: String? {
        switch self {
        case .malformedField(let line): return "Malformed package index near line \(line)."
        case .missingField(let name): return "Package index entry is missing \(name)."
        case .invalidSize(let value): return "Invalid package size: \(value)."
        }
    }
}

enum URXPackageIndexParser {
    static func parse(_ source: String) throws -> [URXPackageRecord] {
        let normalized = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let paragraphs = normalized.components(separatedBy: "\n\n")
        var records: [URXPackageRecord] = []

        for paragraph in paragraphs {
            let lines = paragraph.components(separatedBy: "\n")
            var fields: [String: String] = [:]
            var currentKey: String?

            for (offset, line) in lines.enumerated() {
                if line.isEmpty { continue }
                if line.hasPrefix(" ") || line.hasPrefix("\t") {
                    guard let key = currentKey else { throw URXPackageIndexError.malformedField(offset + 1) }
                    let continuation = String(line.dropFirst())
                    fields[key, default: ""] += "\n" + continuation
                    continue
                }
                guard let colon = line.firstIndex(of: ":") else {
                    throw URXPackageIndexError.malformedField(offset + 1)
                }
                let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
                let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else { throw URXPackageIndexError.malformedField(offset + 1) }
                fields[key] = value
                currentKey = key
            }

            if fields.isEmpty { continue }
            func required(_ key: String) throws -> String {
                guard let value = fields[key], !value.isEmpty else {
                    throw URXPackageIndexError.missingField(key)
                }
                return value
            }

            let size: Int?
            if let rawSize = fields["size"], !rawSize.isEmpty {
                guard let parsedSize = Int(rawSize), parsedSize >= 0 else {
                    throw URXPackageIndexError.invalidSize(rawSize)
                }
                size = parsedSize
            } else {
                size = nil
            }

            records.append(URXPackageRecord(
                id: try required("package"),
                version: try required("version"),
                architecture: fields["architecture"] ?? "all",
                maintainer: fields["maintainer"] ?? "",
                description: normalizeDescription(fields["description"] ?? ""),
                filename: fields["filename"] ?? "",
                size: size,
                sha256: fields["sha256"],
                preDependencies: try parseDependencies(fields["pre-depends"] ?? ""),
                dependencies: try parseDependencies(fields["depends"] ?? ""),
                provides: try parseDependencies(fields["provides"] ?? "").flatMap { $0 },
                fields: fields
            ))
        }
        return records
    }

    private static func normalizeDescription(_ source: String) -> String {
        source.components(separatedBy: "\n").map { line in
            line == "." ? "" : line
        }.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }

    private static func parseDependencies(_ source: String) throws -> [[URXPackageDependency]] {
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return try split(source, separator: ",").map { group in
            try split(group, separator: "|").map { raw in
                let rawValue = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !rawValue.isEmpty else { throw URXPackageIndexError.malformedField(1) }
                let value = rawValue.components(separatedBy: "[" )[0].components(separatedBy: "<")[0].trimmingCharacters(in: .whitespaces)
                let packageToken = value.components(separatedBy: " ").first ?? value
                let packageName = packageToken.components(separatedBy: ":").first ?? packageToken
                guard let open = value.firstIndex(of: "(") else {
                    return URXPackageDependency(package: packageName, relation: nil, version: nil)
                }
                guard let close = value[open...].firstIndex(of: ")") else {
                    throw URXPackageIndexError.malformedField(1)
                }
                let nameToken = value[..<open].trimmingCharacters(in: .whitespaces)
                let name = nameToken.components(separatedBy: ":").first ?? nameToken
                let constraint = value[value.index(after: open)..<close]
                    .trimmingCharacters(in: .whitespaces)
                let parts = constraint.split(maxSplits: 1, whereSeparator: { $0.isWhitespace })
                guard !name.isEmpty, parts.count == 2 else {
                    throw URXPackageIndexError.malformedField(1)
                }
                let relation = String(parts[0])
                guard [">>", ">=", "=", "<=", "<<"].contains(relation) else {
                    throw URXPackageIndexError.malformedField(1)
                }
                return URXPackageDependency(package: name, relation: relation, version: String(parts[1]))
            }
        }
    }

    private static func split(_ source: String, separator: Character) -> [String] {
        var output: [String] = []
        var current = ""
        var depth = 0
        for character in source {
            if character == "(" || character == "[" { depth += 1 }
            if character == ")" || character == "]" { depth = max(0, depth - 1) }
            if character == separator && depth == 0 {
                output.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(character)
            }
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output
    }
}

/// Debian version ordering (epoch, upstream version, Debian revision).
enum URXDebianVersion {
    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = components(lhs)
        let right = components(rhs)
        let epochResult = compareNumericStrings(left.epoch, right.epoch)
        if epochResult != .orderedSame { return epochResult }
        let upstreamResult = comparePart(left.upstream, right.upstream)
        if upstreamResult != .orderedSame { return upstreamResult }
        return comparePart(left.revision, right.revision)
    }

    private static func components(_ value: String) -> (epoch: String, upstream: String, revision: String) {
        var rest = value
        var epoch = "0"
        if let colon = rest.firstIndex(of: ":") {
            let candidate = String(rest[..<colon])
            if !candidate.isEmpty && candidate.allSatisfy(\.isNumber) {
                epoch = candidate
                rest = String(rest[rest.index(after: colon)...])
            }
        }
        let revision: String
        if let dash = rest.lastIndex(of: "-") {
            revision = String(rest[rest.index(after: dash)...])
            rest = String(rest[..<dash])
        } else {
            revision = "0"
        }
        return (epoch, rest, revision)
    }

    private static func compareNumericStrings(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let a = String(lhs.drop(while: { $0 == "0" }))
        let b = String(rhs.drop(while: { $0 == "0" }))
        if a.count != b.count { return a.count < b.count ? .orderedAscending : .orderedDescending }
        if a == b { return .orderedSame }
        return a < b ? .orderedAscending : .orderedDescending
    }

    private static func order(_ character: Character?) -> Int {
        guard let character else { return 0 }
        if character == "~" { return -1 }
        if character.isLetter, let scalar = character.asciiValue { return Int(scalar) }
        if character.isNumber { return 0 }
        if let scalar = character.asciiValue { return Int(scalar) + 256 }
        return 512
    }

    private static func comparePart(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let a = Array(lhs)
        let b = Array(rhs)
        var i = 0
        var j = 0

        while i < a.count || j < b.count {
            while (i < a.count && !a[i].isNumber) || (j < b.count && !b[j].isNumber) {
                let ac = i < a.count && !a[i].isNumber ? a[i] : nil
                let bc = j < b.count && !b[j].isNumber ? b[j] : nil
                let ao = order(ac)
                let bo = order(bc)
                if ao != bo { return ao < bo ? .orderedAscending : .orderedDescending }
                if ac != nil { i += 1 }
                if bc != nil { j += 1 }
            }

            while i < a.count && a[i] == "0" { i += 1 }
            while j < b.count && b[j] == "0" { j += 1 }
            let startI = i
            let startJ = j
            while i < a.count && a[i].isNumber { i += 1 }
            while j < b.count && b[j].isNumber { j += 1 }
            let lengthA = i - startI
            let lengthB = j - startJ
            if lengthA != lengthB { return lengthA < lengthB ? .orderedAscending : .orderedDescending }
            if lengthA > 0 {
                let numberA = String(a[startI..<i])
                let numberB = String(b[startJ..<j])
                if numberA != numberB { return numberA < numberB ? .orderedAscending : .orderedDescending }
            }
        }
        return .orderedSame
    }

    static func satisfies(installed: String, relation: String?, required: String?) -> Bool {
        guard let relation, let required else { return true }
        let result = compare(installed, required)
        switch relation {
        case ">>": return result == .orderedDescending
        case ">=": return result != .orderedAscending
        case "=": return result == .orderedSame
        case "<=": return result != .orderedDescending
        case "<<": return result == .orderedAscending
        default: return false
        }
    }
}

enum URXDependencyResolutionError: LocalizedError {
    case packageNotFound(String)
    case dependencyNotFound(String)
    case dependencyCycle(String)

    var errorDescription: String? {
        switch self {
        case .packageNotFound(let name): return "Package not found in configured indexes: \(name)."
        case .dependencyNotFound(let name): return "No available package satisfies dependency: \(name)."
        case .dependencyCycle(let name): return "Dependency cycle detected at: \(name)."
        }
    }
}

/// Produces an install order only. It does not download, unpack, install, or execute anything.
struct URXDependencyResolver {
    let available: [URXPackageRecord]
    let installedVersions: [String: String]
    let supportedArchitectures: Set<String>

    func plan(for requestedPackageIDs: [String]) throws -> [URXPackageRecord] {
        var result: [URXPackageRecord] = []
        var completed = Set<String>()
        var visiting = Set<String>()

        func candidate(for dependency: URXPackageDependency) -> URXPackageRecord? {
            available
                .filter { package in
                    guard supportedArchitectures.contains(package.architecture) || package.architecture == "all" else { return false }
                    if package.id == dependency.package {
                        return URXDebianVersion.satisfies(installed: package.version, relation: dependency.relation, required: dependency.version)
                    }
                    return package.provides.contains { provided in
                        guard provided.package == dependency.package else { return false }
                        if dependency.relation == nil { return true }
                        guard let providedVersion = provided.version else { return false }
                        return URXDebianVersion.satisfies(installed: providedVersion, relation: dependency.relation, required: dependency.version)
                    }
                }
                .sorted {
                    if $0.id == dependency.package && $1.id != dependency.package { return true }
                    if $1.id == dependency.package && $0.id != dependency.package { return false }
                    return URXDebianVersion.compare($0.version, $1.version) == .orderedDescending
                }
                .first
        }

        func resolve(_ package: URXPackageRecord) throws {
            if completed.contains(package.id) { return }
            if visiting.contains(package.id) { throw URXDependencyResolutionError.dependencyCycle(package.id) }
            visiting.insert(package.id)

            for group in package.preDependencies + package.dependencies {
                var selected: URXPackageRecord?
                var alreadyInstalled = false
                for alternative in group {
                    if let installed = installedVersions[alternative.package],
                       URXDebianVersion.satisfies(installed: installed, relation: alternative.relation, required: alternative.version) {
                        alreadyInstalled = true
                        break
                    }
                    if let match = candidate(for: alternative) {
                        selected = match
                        break
                    }
                }
                if alreadyInstalled { continue }
                guard let dependency = selected else {
                    throw URXDependencyResolutionError.dependencyNotFound(group.map(\.display).joined(separator: " | "))
                }
                try resolve(dependency)
            }

            visiting.remove(package.id)
            completed.insert(package.id)
            if installedVersions[package.id] != package.version { result.append(package) }
        }

        for requestedID in requestedPackageIDs {
            guard let package = available
                .filter({ $0.id == requestedID && (supportedArchitectures.contains($0.architecture) || $0.architecture == "all") })
                .sorted(by: { URXDebianVersion.compare($0.version, $1.version) == .orderedDescending })
                .first else {
                throw URXDependencyResolutionError.packageNotFound(requestedID)
            }
            try resolve(package)
        }
        return result
    }
}
