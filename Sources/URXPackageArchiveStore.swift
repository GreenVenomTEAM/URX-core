import Foundation
import CryptoKit

/// Downloads a repository archive into the URX guest filesystem without unpacking or executing it.
enum URXPackageArchiveStore {
    private static let maximumArchiveSize = 512 * 1024 * 1024

    enum ArchiveError: LocalizedError {
        case missingRepositoryOrigin
        case missingFilename
        case invalidFilename
        case insecureRepository
        case missingChecksum
        case invalidResponse
        case invalidSize
        case checksumMismatch

        var errorDescription: String? {
            switch self {
            case .missingRepositoryOrigin: return "This package has no repository origin. Refresh an APT source to enable archive downloads."
            case .missingFilename: return "The repository did not provide a package archive filename."
            case .invalidFilename: return "The package archive path is invalid or unsafe."
            case .insecureRepository: return "Package archives can only be downloaded from HTTPS repositories."
            case .missingChecksum: return "The repository did not provide a valid SHA-256 checksum. The archive was not downloaded."
            case .invalidResponse: return "The repository returned an invalid response for this package archive."
            case .invalidSize: return "The package archive is empty, exceeds the 512 MB limit, or does not match the advertised size."
            case .checksumMismatch: return "The downloaded archive does not match the SHA-256 checksum in the package index."
            }
        }
    }

    static func download(package: URXPackageRecord) async throws -> URL {
        guard let baseURL = package.repositoryBaseURL else { throw ArchiveError.missingRepositoryOrigin }
        guard !package.filename.isEmpty else { throw ArchiveError.missingFilename }
        guard isSafeRelativeFilename(package.filename) else { throw ArchiveError.invalidFilename }
        guard baseURL.scheme?.lowercased() == "https",
              baseURL.user == nil, baseURL.password == nil else {
            throw ArchiveError.insecureRepository
        }
        guard let expectedHash = package.sha256?.lowercased(),
              expectedHash.count == 64,
              expectedHash.allSatisfy({ $0.isHexDigit }) else {
            throw ArchiveError.missingChecksum
        }

        var baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        if let path = baseComponents?.percentEncodedPath, !path.hasSuffix("/") {
            baseComponents?.percentEncodedPath = path + "/"
        }
        guard let normalizedBase = baseComponents?.url,
              let archiveURL = URL(string: package.filename, relativeTo: normalizedBase)?.absoluteURL,
              archiveURL.scheme?.lowercased() == "https",
              archiveURL.user == nil, archiveURL.password == nil else {
            throw ArchiveError.invalidFilename
        }

        let destinationDirectory = try archiveDirectory()
        let destination = destinationDirectory.appendingPathComponent(safeArchiveName(package))
        if FileManager.default.fileExists(atPath: destination.path),
           (try? verifyFile(destination, package: package, expectedHash: expectedHash)) != nil {
            return destination
        }
        try? FileManager.default.removeItem(at: destination)

        var request = URLRequest(url: archiveURL)
        request.timeoutInterval = 180
        request.setValue("application/vnd.debian.binary-package, application/octet-stream", forHTTPHeaderField: "Accept")
        let (temporaryURL, response) = try await URLSession.shared.download(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              response.url?.scheme?.lowercased() == "https" else {
            throw ArchiveError.invalidResponse
        }

        try verifyFile(temporaryURL, package: package, expectedHash: expectedHash)
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    private static func verifyFile(_ url: URL, package: URXPackageRecord, expectedHash: String) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let actualSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
        guard actualSize > 0, actualSize <= maximumArchiveSize,
              package.size == nil || package.size == actualSize else {
            throw ArchiveError.invalidSize
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        let actualHash = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        guard actualHash == expectedHash else { throw ArchiveError.checksumMismatch }
    }

    private static func archiveDirectory() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support
            .appendingPathComponent("URXSandbox", isDirectory: true)
            .appendingPathComponent("var", isDirectory: true)
            .appendingPathComponent("cache", isDirectory: true)
            .appendingPathComponent("apt", isDirectory: true)
            .appendingPathComponent("archives", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func isSafeRelativeFilename(_ filename: String) -> Bool {
        guard !filename.isEmpty,
              !filename.hasPrefix("/"),
              !filename.contains("\\"),
              !filename.contains("?"),
              !filename.contains("#"),
              let decoded = filename.removingPercentEncoding else { return false }
        let components = decoded.split(separator: "/", omittingEmptySubsequences: false)
        return !components.isEmpty &&
            components.allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." } &&
            decoded.hasSuffix(".deb")
    }

    private static func safeArchiveName(_ package: URXPackageRecord) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._+-"))
        let raw = "\(package.id)_\(package.version).deb"
        let safe = String(raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
        return safe.hasSuffix(".deb") ? safe : safe + ".deb"
    }
}
