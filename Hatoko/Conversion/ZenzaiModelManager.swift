import Foundation
import Observation

@MainActor
@Observable
final class ZenzaiModelManager {
    static let shared = ZenzaiModelManager()

    private static let modelURLString = "https://huggingface.co/Miwa-Keita/zenz-v3-small-gguf/resolve/main/ggml-model-Q5_K_M.gguf"
    private static let modelFileName = "ggml-model-Q5_K_M.gguf"

    enum DownloadState: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case error(String)
    }

    private(set) var state: DownloadState = .notDownloaded

    var modelFileURL: URL? {
        let url = Self.modelDirectory.appendingPathComponent(Self.modelFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static var modelDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return appSupport.appendingPathComponent("Hatoko/Models")
    }

    private init() {
        if modelFileURL != nil {
            state = .downloaded
        }
    }

    func downloadModelIfNeeded() async {
        guard modelFileURL == nil else {
            state = .downloaded
            return
        }
        state = .downloading(progress: 0)

        do {
            try FileManager.default.createDirectory(
                at: Self.modelDirectory,
                withIntermediateDirectories: true
            )

            let destination = Self.modelDirectory.appendingPathComponent(Self.modelFileName)
            guard let modelURL = URL(string: Self.modelURLString) else {
                state = .error("Invalid model URL")
                return
            }
            let (tempURL, response) = try await URLSession.shared.download(from: modelURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                state = .error("Download failed with unexpected status code")
                return
            }

            try FileManager.default.moveItem(at: tempURL, to: destination)
            state = .downloaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func deleteModel() {
        let url = Self.modelDirectory.appendingPathComponent(Self.modelFileName)
        try? FileManager.default.removeItem(at: url)
        state = .notDownloaded
    }
}
