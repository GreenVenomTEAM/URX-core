#!/usr/bin/env python3
"""Use the portable Swift XZ/LZMA decoder instead of Sileo's macOS-only liblzma stub."""
from pathlib import Path
import stat

root = Path("Vendor/Sileo/Sileo")
c_path = root / "Backend/C Contrib/decompression.c"
h_path = root / "Backend/C Contrib/decompression.h"
swift_path = root / "Backend/Decompression/XZ.swift"

for path in (c_path, h_path, swift_path):
    if not path.is_file():
        raise SystemExit(f"Required Sileo source file not found: {path}")

c = c_path.read_text()
if '#import "lzma.h"' in c:
    c = c.replace('#import "lzma.h"\n', '', 1)
start = c.find("uint8_t decompressXz(")
end = c.find("uint8_t decompressBzip(", start)
if start >= 0 and end > start:
    c = c[:start] + c[end:]
elif start >= 0 or "uint8_t decompressXz(" not in c:
    raise SystemExit("Unexpected decompression.c layout; refusing partial patch.")
c_path.chmod(c_path.stat().st_mode | stat.S_IWUSR)
c_path.write_text(c)

h = h_path.read_text()
h = h.replace("uint8_t decompressXz(FILE *input, FILE *output, uint8_t type);\n", "")
h_path.chmod(h_path.stat().st_mode | stat.S_IWUSR)
h_path.write_text(h)

swift = '''//
// XZ/LZMA decompression for the sandbox build.
// Uses the portable Swift implementation instead of a macOS-only liblzma stub.
//

import Foundation
import SWCompression

public enum XZType: UInt8 {
    case xz = 0
    case lzma = 1
}

final class XZ {
    class func decompress(path: URL, type: XZType) -> Result<URL, XZError> {
        let destinationURL = path.appendingPathExtension("clean")
        do {
            let compressed = try Data(contentsOf: path, options: .mappedIfSafe)
            let decompressed: Data
            switch type {
            case .xz:
                decompressed = try XZArchive.unarchive(archive: compressed)
            case .lzma:
                decompressed = try LZMA.decompress(data: compressed)
            }
            try decompressed.write(to: destinationURL, options: .atomic)
            return .success(destinationURL)
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            return .failure(.corrupt)
        }
    }
}

enum XZError: String, Error {
    case fileLoad = "Failed to load file"
    case allocation = "Memory Allocation Failed"
    case unsupportedFlags = "Unsupported Decompressor Flags"
    case fileRead = "Error Reading File"
    case fileWrite = "Error Writing File"
    case formatError = "Input file is not correct format"
    case corrupt = "Input file is corrupt"
    case unknown = "Unknown Error"

    init(error: UInt8) {
        switch error {
        case 1: self = .allocation
        case 2: self = .unsupportedFlags
        case 3: self = .unknown
        case 4: self = .fileRead
        case 5: self = .fileWrite
        case 8: self = .formatError
        case 9: self = .corrupt
        default: self = .unknown
        }
    }
}
'''
swift_path.chmod(swift_path.stat().st_mode | stat.S_IWUSR)
swift_path.write_text(swift)
print("Replaced Sileo's liblzma calls with SWCompression XZ/LZMA decoding.")
