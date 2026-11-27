import Foundation

/// A data-only view of one entry from a Debian dpkg status database.
/// This model never invokes dpkg or package maintainer scripts.
struct URXDPKGStatusRecord: Identifiable, Codable, Hashable {
    let package: String
    let version: String
    let architecture: String
    let status: String
    let description: String
    let fields: [String: String]

    var id: String { package }

    var isInstalled: Bool {
        let parts = status.split(whereSeparator: { $0.isWhitespace })
        return parts.count == 3 && parts[2] == "installed"
    }

    var isHeld: Bool {
        let parts = status.split(whereSeparator: { $0.isWhitespace })
        return parts.count == 3 && parts[0] == "hold"
    }
}

enum URXDPKGStatusParser {
    static func parse(_ source: String) throws -> [URXDPKGStatusRecord] {
        let normalized = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let paragraphs = normalized.components(separatedBy: "\n\n")
        var records: [URXDPKGStatusRecord] = []

        for (paragraphIndex, paragraph) in paragraphs.enumerated() {
            var fields: [String: String] = [:]
            var currentKey: String?

            for line in paragraph.components(separatedBy: "\n") {
                if line.isEmpty { continue }
                if line.hasPrefix(" ") || line.hasPrefix("\t") {
                    guard let key = currentKey else {
                        throw URXDPKGStatusError.malformedEntry(paragraphIndex + 1)
                    }
                    fields[key, default: ""] += "\n" + String(line.dropFirst())
                    continue
                }

                guard let separator = line.firstIndex(of: ":") else {
                    throw URXDPKGStatusError.malformedEntry(paragraphIndex + 1)
                }
                let key = line[..<separator].trimmingCharacters(in: .whitespaces).lowercased()
                let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else {
                    throw URXDPKGStatusError.malformedEntry(paragraphIndex + 1)
                }
                fields[key] = value
                currentKey = key
            }

            if fields.isEmpty { continue }
            guard let package = fields["package"], !package.isEmpty,
                  let version = fields["version"], !version.isEmpty,
                  let status = fields["status"], isValidStatus(status) else {
                throw URXDPKGStatusError.missingRequiredField(paragraphIndex + 1)
            }

            records.append(URXDPKGStatusRecord(
                package: package,
                version: version,
                architecture: fields["architecture"] ?? "all",
                status: status,
                description: normalizeDescription(fields["description"] ?? ""),
                fields: fields
            ))
        }

        return records
    }

    private static func isValidStatus(_ value: String) -> Bool {
        let parts = value.split(whereSeparator: { $0.isWhitespace })
        guard parts.count == 3 else { return false }
        let validWant = ["unknown", "install", "hold", "deinstall", "purge"]
        let validFlag = ["ok", "reinstreq"]
        let validState = [
            "not-installed", "config-files", "half-installed", "unpacked",
            "half-configured", "triggers-awaited", "triggers-pending", "installed"
        ]
        return validWant.contains(String(parts[0]))
            && validFlag.contains(String(parts[1]))
            && validState.contains(String(parts[2]))
    }

    private static func normalizeDescription(_ source: String) -> String {
        source.components(separatedBy: "\n").map { $0 == "." ? "" : $0 }
            .joined(separator: "\n")
            .trimmingCharacters(in: .newlines)
    }
}

enum URXDPKGStatusError: LocalizedError {
    case malformedEntry(Int)
    case missingRequiredField(Int)

    var errorDescription: String? {
        switch self {
        case .malformedEntry(let entry):
            return "The dpkg status database contains a malformed entry near paragraph \(entry)."
        case .missingRequiredField(let entry):
            return "The dpkg status entry near paragraph \(entry) is missing Package, Version, or a valid Status field."
        }
    }
}

/// Reads and writes only a status file located inside URX's own app container.
enum URXDPKGStatusStore {
    static func load(from url: URL) throws -> [URXDPKGStatusRecord] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        guard let source = String(data: data, encoding: .utf8) else {
            throw URXDPKGStatusError.malformedEntry(1)
        }
        return try URXDPKGStatusParser.parse(source)
    }

    static func save(_ records: [URXDPKGStatusRecord], to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let paragraphs = records.sorted {
            $0.package.localizedCaseInsensitiveCompare($1.package) == .orderedAscending
        }.map { record -> String in
            let orderedKeys = ["package", "status", "version", "architecture", "maintainer", "description"]
            var emitted = Set<String>()
            var lines: [String] = []

            for key in orderedKeys {
                guard let value = record.fields[key] else { continue }
                lines.append(contentsOf: fieldLines(key: key, value: value))
                emitted.insert(key)
            }
            for key in record.fields.keys.sorted() where !emitted.contains(key) {
                if let value = record.fields[key] {
                    lines.append(contentsOf: fieldLines(key: key, value: value))
                }
            }
            return lines.joined(separator: "\n")
        }

        let output = paragraphs.joined(separator: "\n\n") + (paragraphs.isEmpty ? "" : "\n")
        try Data(output.utf8).write(to: url, options: .atomic)
    }

    private static func fieldLines(key: String, value: String) -> [String] {
        let components = value.components(separatedBy: "\n")
        guard let first = components.first else { return ["\(key):"] }
        return ["\(key): \(first)"] + components.dropFirst().map { " \($0)" }
    }
}
