import Foundation
import Observation

@MainActor
@Observable
final class ZenzaiModelManager {
    static let shared = ZenzaiModelManager()

    static let enabledKey = "zenzai_enabled"
    static let inferenceLimitKey = "zenzai_inference_limit"
    static let defaultInferenceLimit = 3

    static func storedInferenceLimit() -> Int {
        let stored = UserDefaults.standard.integer(forKey: inferenceLimitKey)
        return stored == 0 ? defaultInferenceLimit : max(1, stored)
    }

    private static let modelURLString = "https://huggingface.co/Miwa-Keita/zenz-v3-small-gguf/resolve/main/ggml-model-Q5_K_M.gguf"
    private static let modelFileName = "ggml-model-Q5_K_M.gguf"

    enum DownloadState: Equatable {
        case notDownloaded
        case downloading
        case downloaded
        case error(String)
    }

    private(set) var state: DownloadState = .notDownloaded

    var modelFileURL: URL? {
        let url = Self.modelDirectory.appendingPathComponent(Self.modelFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static var modelDirectory: URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Application Support directory is unavailable")
        }
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
        state = .downloading

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
