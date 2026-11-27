import Foundation
import Darwin

enum DebianArchiveReader {
    enum ArchiveError: LocalizedError {
        case invalidArchive
        case missingControlArchive
        case unsupportedCompression(String)
        case invalidTar
        case controlFileMissing
        case archiveTooLarge
        case decompressionFailed

        var errorDescription: String? {
            switch self {
            case .invalidArchive:
                return "This file is not a valid Debian .deb archive."
            case .missingControlArchive:
                return "The .deb archive does not contain a control archive."
            case .unsupportedCompression(let format):
                return "The control archive uses \(format) compression, which this prototype does not support yet. Gzip and uncompressed control archives are supported."
            case .invalidTar:
                return "The package control archive has an invalid TAR structure."
            case .controlFileMissing:
                return "The package control archive does not contain a control file."
            case .archiveTooLarge:
                return "The selected package is empty or exceeds the 64 MB inspection limit."
            case .decompressionFailed:
                return "Could not decompress the package control archive."
            }
        }
    }

    static func controlText(from deb: Data) throws -> String {
        let bytes = [UInt8](deb)
        guard bytes.count >= 8, Array(bytes[0..<8]) == Array("!<arch>\n".utf8) else {
            throw ArchiveError.invalidArchive
        }

        var offset = 8
        var controlArchive: Data?

        while offset + 60 <= bytes.count {
            let header = Array(bytes[offset..<(offset + 60)])
            guard String(bytes: header[58..<60], encoding: .ascii) == "`\n" else {
                throw ArchiveError.invalidArchive
            }

            let rawName = String(bytes: header[0..<16], encoding: .ascii)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let sizeText = String(bytes: header[48..<58], encoding: .ascii)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let memberSize = Int(sizeText), memberSize >= 0 else {
                throw ArchiveError.invalidArchive
            }

            let dataStart = offset + 60
            let dataEnd = dataStart + memberSize
            guard dataEnd <= bytes.count else { throw ArchiveError.invalidArchive }

            let normalizedName = rawName.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if normalizedizedControlName(normalizedName) {
                controlArchive = Data(bytes[dataStart..<dataEnd])
                break
            }

            offset = dataEnd + (memberSize % 2)
        }

        guard let archive = controlArchive else { throw ArchiveError.missingControlArchive }
        let tarData: Data
        if archive.starts(with: [0x1f, 0x8b]) {
            tarData = try gunzip(archive)
        } else if archive.starts(with: [0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00]) {
            throw ArchiveError.unsupportedCompression("XZ")
        } else if archive.starts(with: [0x28, 0xb5, 0x2f, 0xfd]) {
            throw ArchiveError.unsupportedCompression("Zstandard")
        } else if archive.starts(with: [0x42, 0x5a, 0x68]) {
            throw ArchiveError.unsupportedCompression("Bzip2")
        } else {
            tarData = archive
        }

        return try extractControlFile(from: tarData)
    }

    private static func normalizedizedControlName(_ name: String) -> Bool {
        name == "control.tar" || name == "control.tar.gz" || name == "control.tar.xz" ||
        name == "control.tar.zst" || name == "control.tar.bz2"
    }

    private static func gunzip(_ data: Data) throws -> Data {
        var outputPointer: UnsafeMutablePointer<UInt8>?
        var outputLength = 0
        let status = data.withUnsafeBytes { rawBuffer -> Int32 in
            guard let baseAddress = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return -1
            }
            return urx_gzip_decompress(baseAddress, data.count, &outputPointer, &outputLength)
        }
        guard status == 0, let outputPointer else {
            throw ArchiveError.decompressionFailed
        }
        defer { free(outputPointer) }
        guard outputLength <= 32 * 1024 * 1024 else { throw ArchiveError.archiveTooLarge }
        return Data(bytes: outputPointer, count: outputLength)
    }

    private static func extractControlFile(from tar: Data) throws -> String {
        let bytes = [UInt8](tar)
        var offset = 0

        while offset + 512 <= bytes.count {
            let header = Array(bytes[offset..<(offset + 512)])
            if header.allSatisfy({ $0 == 0 }) { break }

            let name = cString(header[0..<100])
            let prefix = cString(header[345..<500])
            let path = prefix.isEmpty ? name : prefix + "/" + name
            let sizeText = cString(header[124..<136]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let fileSize = Int(sizeText, radix: 8), fileSize >= 0 else {
                throw ArchiveError.invalidTar
            }

            let dataStart = offset + 512
            let dataEnd = dataStart + fileSize
            guard dataEnd <= bytes.count else { throw ArchiveError.invalidTar }

            let typeFlag = header[156]
            if (typeFlag == 0 || typeFlag == 48) && (path == "control" || path == "./control") {
                guard let text = String(data: Data(bytes[dataStart..<dataEnd]), encoding: .utf8) else {
                    throw ArchiveError.invalidTar
                }
                return text
            }

            let paddedSize = ((fileSize + 511) / 512) * 512
            offset = dataStart + paddedSize
        }

        throw ArchiveError.controlFileMissing
    }

    private static func cString(_ bytes: ArraySlice<UInt8>) -> String {
        String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
}
