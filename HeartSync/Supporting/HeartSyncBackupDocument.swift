import SwiftUI
import UniformTypeIdentifiers

struct HeartSyncBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static let maximumByteCount = 5_000_000

    let data: Data
    // Kept in memory only; never included in the file wrapper.
    let sourceState: Data?

    init(data: Data, sourceState: Data? = nil) {
        self.data = data
        self.sourceState = sourceState
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw BackupFileError.notAFile }
        _ = try Self.text(from: data)
        self.init(data: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        _ = try Self.text(from: data)
        return FileWrapper(regularFileWithContents: data)
    }

    static func text(from data: Data) throws -> String {
        guard data.count <= maximumByteCount else { throw BackupFileError.tooLarge }
        guard let text = String(data: data, encoding: .utf8) else { throw BackupFileError.notUTF8 }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw BackupFileError.empty }
        return text
    }

    /// Bounded reading is also enforced after the size check, in case the file changes.
    static func readContents(from url: URL) throws -> String {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true else { throw BackupFileError.notAFile }
        if let size = values.fileSize, size > maximumByteCount { throw BackupFileError.tooLarge }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        var data = Data()
        while data.count <= maximumByteCount {
            let chunk = try file.read(upToCount: min(65536, maximumByteCount + 1 - data.count)) ?? Data()
            if chunk.isEmpty { break }
            data.append(chunk)
        }
        return try text(from: data)
    }
}

enum BackupFileError: LocalizedError {
    case tooLarge, notUTF8, empty, notAFile, invalidBackup

    var errorDescription: String? {
        switch self {
        case .tooLarge: return "Choose a JSON backup no larger than 5 MB."
        case .notUTF8: return "The file is not readable UTF-8 JSON text."
        case .empty: return "The backup file is empty."
        case .notAFile: return "Choose a JSON file, not a folder."
        case .invalidBackup: return "This is not a valid or supported HeartSync backup."
        }
    }
}
