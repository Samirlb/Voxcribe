import SwiftUI

struct TranscriptionView: View {
    @State private var viewModel = TranscriptionViewModel()
    @State private var settings = SettingsViewModel()
    @State private var showSettings = false

    private var isActive: Bool {
        viewModel.state == .listening || viewModel.state == .processing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                backgroundGradient

                VStack(spacing: 0) {
                    statusBar
                        .padding(.horizontal, VoxcribeTokens.Spacing.lg)
                        .padding(.top, VoxcribeTokens.Spacing.sm)

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

                    controlBar
                        .padding(.horizontal, VoxcribeTokens.Spacing.lg)
                        .padding(.bottom, VoxcribeTokens.Spacing.md)
                }
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
                        Image(systemName: "gearshape")
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                ToolbarItem(placement: .automatic) {
                    if !viewModel.entries.isEmpty {
                        Button {
                            viewModel.clearEntries()
                        } label: {
                            Image(systemName: "trash")
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
            .onAppear { syncSettings() }
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

    // MARK: - Background

    private var backgroundGradient: some View {
        #if os(iOS)
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        #else
        LinearGradient(
            colors: [
                Color(.windowBackgroundColor),
                Color(.windowBackgroundColor).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        #endif
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
                        .transition(.scale.combined(with: .opacity))
                }

                if viewModel.ttsService.isSpeaking {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .symbolEffect(.variableColor.iterative)
                }

                AudioLevelIndicator(level: viewModel.audioService.audioLevel)
            }
        }
        .padding(.horizontal, VoxcribeTokens.Spacing.md)
        .padding(.vertical, VoxcribeTokens.Spacing.sm)
        .glassCard(cornerRadius: VoxcribeTokens.CornerRadius.md)
        .animation(VoxcribeTokens.Animation.standard, value: viewModel.state)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch viewModel.state {
        case .idle:
            Label("Ready", systemImage: "mic.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .listening:
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: .green.opacity(0.6), radius: 3)
                Text("Listening")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        case .processing:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Translating…")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        case .error:
            EmptyView()
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: VoxcribeTokens.Spacing.md) {
            // Source language
            languagePicker(
                selection: settings.conversationMode
                    ? $viewModel.conversationController.languageA
                    : $viewModel.sourceLanguage,
                label: settings.conversationMode ? "A" : "From"
            )

            Button {
                withAnimation(VoxcribeTokens.Animation.smooth) {
                    viewModel.swapLanguages()
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.ultraThinMaterial))
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
                withAnimation(VoxcribeTokens.Animation.smooth) {
                    viewModel.toggleListening()
                }
            } label: {
                Image(systemName: isActive ? "stop.fill" : "mic.fill")
            }
            .buttonStyle(RecordButtonStyle(isRecording: isActive))
        }
        .padding(.horizontal, VoxcribeTokens.Spacing.md)
        .padding(.vertical, VoxcribeTokens.Spacing.md)
        .glassCard()
    }

    private func languagePicker(selection: Binding<Language>, label: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Picker(label, selection: selection) {
                ForEach(Language.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .labelsHidden()
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
            .tint(.primary)
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
