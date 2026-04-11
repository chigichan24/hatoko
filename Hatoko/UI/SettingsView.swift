import SwiftUI

struct SettingsView: View {

    @State private var apiKey: String = ""
    @State private var selectedBackend: LLMBackend = .current
    @State private var cliPath: String = ""
    @State private var isSaved = false
    @State private var isZenzaiEnabled = UserDefaults.standard.bool(forKey: ZenzaiModelManager.enabledKey)
    @State private var zenzaiInferenceLimit: Int = ZenzaiModelManager.storedInferenceLimit()
    @State private var isDangerousReadEnabled = UserDefaults.standard.bool(
        forKey: DangerousReadModeController.enabledKey
    )
    @State private var dangerousReadDuration: Int = DangerousReadModeController.storedMaxDuration()
    @State private var dangerousReadInterval: Int = DangerousReadModeController.storedCaptureInterval()
    @State private var isAccessibilityTrusted = AccessibilityPermission.isTrusted
    /// Enable this flag when developing with local CLI tools.
    private static let isDevelopmentMode: Bool = true

    private static var availableBackends: [LLMBackend] {
        LLMBackend.allCases.filter { backend in
            if case .cli = backend.configKind {
                return isDevelopmentMode
            }
            return true
        }
    }

    var body: some View {
        Form {
            Section(L10n.Settings.SectionHeader.llmBackend) {
                Picker(L10n.Settings.Picker.backend, selection: $selectedBackend) {
                    ForEach(Self.availableBackends, id: \.self) { backend in
                        VStack(alignment: .leading) {
                            Text(backend.displayName)
                            Text(backend.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(backend)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: selectedBackend) {
                    LLMBackend.current = selectedBackend
                    loadSettingsForBackend(selectedBackend)
                }
            }

            SettingsBackendSection(
                backend: selectedBackend,
                apiKey: $apiKey,
                cliPath: $cliPath,
                isSaved: $isSaved
            )

            Section(L10n.Settings.SectionHeader.zenzai) {
                Toggle(L10n.Settings.Zenzai.enable, isOn: $isZenzaiEnabled)
                    .onChange(of: isZenzaiEnabled) {
                        UserDefaults.standard.set(isZenzaiEnabled, forKey: ZenzaiModelManager.enabledKey)
                        if isZenzaiEnabled {
                            Task {
                                await ZenzaiModelManager.shared.downloadModelIfNeeded()
                            }
                        }
                    }

                Text(L10n.Settings.Zenzai.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isZenzaiEnabled {
                    zenzaiStatusView
                    zenzaiOptionsView
                }
            }

            Section(L10n.Settings.SectionHeader.dangerousRead) {
                Toggle(L10n.Settings.DangerousRead.enable, isOn: $isDangerousReadEnabled)
                    .onChange(of: isDangerousReadEnabled) {
                        UserDefaults.standard.set(isDangerousReadEnabled, forKey: DangerousReadModeController.enabledKey)
                    }

                Text(L10n.Settings.DangerousRead.warning)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)

                if isDangerousReadEnabled {
                    Picker(L10n.Settings.DangerousRead.duration, selection: $dangerousReadDuration) {
                        Text("1 min").tag(60)
                        Text("3 min").tag(180)
                        Text("5 min").tag(300)
                        Text("10 min").tag(600)
                    }
                    .onChange(of: dangerousReadDuration) {
                        UserDefaults.standard.set(dangerousReadDuration, forKey: DangerousReadModeController.maxDurationKey)
                    }

                    Picker(L10n.Settings.DangerousRead.interval, selection: $dangerousReadInterval) {
                        Text("1 sec").tag(1)
                        Text("3 sec").tag(3)
                        Text("5 sec").tag(5)
                    }
                    .onChange(of: dangerousReadInterval) {
                        UserDefaults.standard.set(
                            dangerousReadInterval, forKey: DangerousReadModeController.captureIntervalKey
                        )
                    }
                }

                HStack {
                    Button(L10n.Settings.DangerousRead.checkPermission) {
                        AccessibilityPermission.requestTrust()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isAccessibilityTrusted = AccessibilityPermission.isTrusted
                        }
                    }
                    if isAccessibilityTrusted {
                        Text(L10n.Settings.DangerousRead.permissionGranted)
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(L10n.Settings.DangerousRead.permissionNotGranted)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section(L10n.Settings.SectionHeader.keybinding) {
                Text(L10n.Settings.Keybinding.llmAssist)
                    .foregroundStyle(.secondary)
                Text(L10n.Settings.Keybinding.toggleLanguage)
                    .foregroundStyle(.secondary)
                Text(L10n.Settings.Keybinding.dangerousRead)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 600, idealWidth: 600, minHeight: 600, idealHeight: 800)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            isAccessibilityTrusted = AccessibilityPermission.isTrusted
        }
        .onAppear {
            let current = LLMBackend.current
            if Self.availableBackends.contains(current) {
                selectedBackend = current
            } else {
                selectedBackend = .foundationModels
                LLMBackend.current = .foundationModels
            }
            loadSettingsForBackend(selectedBackend)
            isAccessibilityTrusted = AccessibilityPermission.isTrusted
        }
    }

    @ViewBuilder
    private var zenzaiStatusView: some View {
        switch ZenzaiModelManager.shared.state {
        case .notDownloaded:
            Text(L10n.Settings.Zenzai.modelNotDownloaded)
                .font(.caption)
                .foregroundStyle(.orange)
        case .downloading(let progress):
            ProgressView(value: progress)
            Text(L10n.Settings.Zenzai.downloading)
                .font(.caption)
        case .downloaded:
            Text(L10n.Settings.Zenzai.modelReady)
                .font(.caption)
                .foregroundStyle(.green)
        case .error(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var zenzaiOptionsView: some View {
        Picker(L10n.Settings.Zenzai.inferenceLimit, selection: $zenzaiInferenceLimit) {
            Text("1 (\(L10n.Settings.Zenzai.fast))").tag(1)
            Text("3 (\(L10n.Settings.Zenzai.balanced))").tag(3)
            Text("5").tag(5)
            Text("10 (\(L10n.Settings.Zenzai.highQuality))").tag(10)
        }
        .onChange(of: zenzaiInferenceLimit) {
            UserDefaults.standard.set(zenzaiInferenceLimit, forKey: ZenzaiModelManager.inferenceLimitKey)
        }

        if ZenzaiModelManager.shared.state == .downloaded {
            Button(L10n.Settings.Zenzai.deleteModel, role: .destructive) {
                ZenzaiModelManager.shared.deleteModel()
                isZenzaiEnabled = false
                UserDefaults.standard.set(false, forKey: ZenzaiModelManager.enabledKey)
            }
        }
    }

    private func loadSettingsForBackend(_ backend: LLMBackend) {
        isSaved = false
        switch backend.configKind {
        case .disabled, .onDevice:
            apiKey = ""
            cliPath = ""
        case .api(let keychainKey, _):
            cliPath = ""
            Task.detached {
                let loaded = KeychainHelper.load(key: keychainKey) ?? ""
                await MainActor.run { apiKey = loaded }
            }
        case .cli(let defaultsKey):
            apiKey = ""
            cliPath = UserDefaults.standard.string(forKey: defaultsKey) ?? ""
        }
    }
}
