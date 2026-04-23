import SwiftUI

struct TranscriptionView: View {
    @State private var viewModel = TranscriptionViewModel()
    @State private var settings = SettingsViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status bar
                statusBar

                Divider()

                // Chat area
                ChatTranscriptionView(
                    entries: viewModel.entries,
                    currentPartialText: viewModel.currentPartialText,
                    showOriginal: settings.showOriginalText,
                    showPartial: settings.showPartialResults,
                    fontSize: settings.fontSize,
                    conversationMode: settings.conversationMode
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Control bar
                controlBar
            }
            .navigationTitle("Voxcribe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    if !viewModel.entries.isEmpty {
                        Button {
                            viewModel.clearEntries()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
            .onAppear {
                syncSettings()
            }
            .onChange(of: settings.targetLanguage) { syncSettings() }
            .onChange(of: settings.translationEngine) { syncSettings() }
            .onChange(of: settings.ttsEnabled) { syncSettings() }
            .onChange(of: settings.showOriginalText) { syncSettings() }
            .onChange(of: settings.showPartialResults) { syncSettings() }
            .onChange(of: settings.silenceTimeout) { syncSettings() }
            .onChange(of: settings.conversationMode) { syncSettings() }
            .onChange(of: settings.ttsRate) {
                viewModel.ttsService.setRate(settings.ttsRate)
            }
            .task {
                await viewModel.permissionsManager.requestAllPermissions()
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: VoxcribeTokens.Spacing.md) {
            if case .error(let message) = viewModel.state {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else {
                stateIndicator

                Spacer()

                if let detected = viewModel.detectedLanguage {
                    Text(detected.displayName)
                        .languagePill(color: .green)
                }

                AudioLevelIndicator(level: viewModel.audioLevel)
            }
        }
        .padding(.horizontal, VoxcribeTokens.Spacing.lg)
        .padding(.vertical, VoxcribeTokens.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch viewModel.state {
        case .idle:
            Label("Ready", systemImage: "mic.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .listening:
            Label("Listening", systemImage: "waveform")
                .font(.caption)
                .foregroundStyle(.green)
        case .processing:
            Label("Translating", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(.orange)
        case .error:
            EmptyView()
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: VoxcribeTokens.Spacing.lg) {
            // Source language
            languagePicker(
                selection: settings.conversationMode
                    ? $viewModel.conversationController.languageA
                    : $viewModel.sourceLanguage,
                label: settings.conversationMode ? "A" : "From"
            )

            // Swap
            Button {
                viewModel.swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
            }
            .buttonStyle(.plain)

            // Target language
            languagePicker(
                selection: settings.conversationMode
                    ? $viewModel.conversationController.languageB
                    : $viewModel.targetLanguage,
                label: settings.conversationMode ? "B" : "To"
            )

            Spacer()

            // Record button
            Button {
                viewModel.toggleListening()
            } label: {
                Image(systemName: viewModel.state == .listening ? "stop.fill" : "mic.fill")
            }
            .buttonStyle(RecordButtonStyle(isRecording: viewModel.state == .listening))
        }
        .padding(.horizontal, VoxcribeTokens.Spacing.lg)
        .padding(.vertical, VoxcribeTokens.Spacing.md)
        .background(.ultraThinMaterial)
    }

    private func languagePicker(selection: Binding<Language>, label: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Picker(label, selection: selection) {
                ForEach(Language.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .labelsHidden()
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
        }
    }

    // MARK: - Sync

    private func syncSettings() {
        viewModel.targetLanguage = settings.targetLanguage
        viewModel.translationEngine = settings.translationEngine
        viewModel.ttsEnabled = settings.ttsEnabled
        viewModel.showOriginalText = settings.showOriginalText
        viewModel.showPartialResults = settings.showPartialResults
        viewModel.silenceTimeout = settings.silenceTimeout
        viewModel.conversationController.isActive = settings.conversationMode

        if settings.conversationMode {
            viewModel.conversationController.languageA = settings.conversationLanguageA
            viewModel.conversationController.languageB = settings.conversationLanguageB
        }
    }
}
