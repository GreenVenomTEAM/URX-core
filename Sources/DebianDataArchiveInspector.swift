import Foundation
import Darwin

enum DebianDataArchiveInspector {
    enum InspectionError: LocalizedError {
        case invalidDeb
        case missingDataArchive
        case unsupportedCompression(String)
        case invalidTar
        case tooManyEntries

        var errorDescription: String? {
            switch self {
            case .invalidDeb: return "The selected file is not a valid Debian archive."
            case .missingDataArchive: return "No data.tar* member was found in the Debian archive. This may be a metadata-only package or use an unrecognized archive layout."
            case .unsupportedCompression(let format):
                return "The data archive uses \(format) compression. This build can list uncompressed and gzip TAR archives only."
            case .invalidTar: return "The package data archive has an invalid TAR structure."
            case .tooManyEntries: return "The archive contains too many entries to display safely."
            }
        }
    }

    static func fileEntries(from deb: Data) throws -> [String] {
        let bytes = [UInt8](deb)
        guard bytes.count >= 8, Array(bytes[0..<8]) == Array("!<arch>\n".utf8) else {
            throw InspectionError.invalidDeb
        }

        var offset = 8
        var dataArchive: Data?
        var dataName = ""

        while offset + 60 <= bytes.count {
            let header = Array(bytes[offset..<(offset + 60)])
            guard String(bytes: header[58..<60], encoding: .ascii) == "`\n" else {
                throw InspectionError.invalidDeb
            }
            let rawName = String(bytes: header[0..<16], encoding: .ascii)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let sizeText = String(bytes: header[48..<58], encoding: .ascii)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard let size = Int(sizeText), size >= 0 else { throw InspectionError.invalidDeb }
            let start = offset + 60
            let end = start + size
            guard end <= bytes.count else { throw InspectionError.invalidDeb }

            let name = rawName.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if name.hasPrefix("data.tar") {
                dataArchive = Data(bytes[start..<end])
                dataName = name
                break
            }
            offset = end + (size % 2)
        }

        guard let archive = dataArchive else { throw InspectionError.missingDataArchive }
        let tar: Data
        if dataName == "data.tar" {
            tar = archive
        } else if dataName == "data.tar.gz" {
            var output: UnsafeMutablePointer<UInt8>?
            var length = 0
            let status = archive.withUnsafeBytes { raw -> Int32 in
                guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return -1 }
                return urx_gzip_decompress(base, archive.count, &output, &length)
            }
            guard status == 0, let output else {
                throw InspectionError.invalidTar
            }
            defer { free(output) }
            tar = Data(bytes: output, count: length)
        } else {
            let format = dataName.hasSuffix(".xz") ? "XZ" : dataName.hasSuffix(".zst") ? "Zstandard" : dataName.hasSuffix(".bz2") ? "Bzip2" : dataName.hasSuffix(".lzma") || dataName.hasSuffix(".lz") ? "LZMA" : "unknown (" + dataName + ")"
            throw InspectionError.unsupportedCompression(format)
        }

        return try listTarEntries(tar)
    }

    private static func listTarEntries(_ tar: Data) throws -> [String] {
        let bytes = [UInt8](tar)
        var offset = 0
        var entries: [String] = []

        while offset + 512 <= bytes.count {
            let header = Array(bytes[offset..<(offset + 512)])
            if header.allSatisfy({ $0 == 0 }) { break }

            let name = cString(header[0..<100])
            let prefix = cString(header[345..<500])
            let path = prefix.isEmpty ? name : prefix + "/" + name
            let sizeText = cString(header[124..<136]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let size = Int(sizeText, radix: 8), size >= 0 else { throw InspectionError.invalidTar }
            let type = header[156]
            let padded = ((size + 511) / 512) * 512
            guard offset + 512 + padded <= bytes.count else { throw InspectionError.invalidTar }

            if !path.isEmpty && (type == 0 || type == 48 || type == 53) {
                entries.append(path + (type == 53 ? "/" : ""))
                if entries.count > 2000 { throw InspectionError.tooManyEntries }
            }
            offset += 512 + padded
        }

        return entries.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func cString(_ bytes: ArraySlice<UInt8>) -> String {
        String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
}
