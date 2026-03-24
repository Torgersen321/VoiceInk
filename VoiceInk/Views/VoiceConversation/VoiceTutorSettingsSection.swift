import SwiftUI
import KeyboardShortcuts

struct VoiceTutorSettingsSection: View {
    @ObservedObject var config: VoiceTutorConfig
    @EnvironmentObject var transcriptionModelManager: TranscriptionModelManager

    @State private var expandedPicker: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18))
                    .foregroundStyle(.purple)
                Text("Voice Tutor")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }

            // STT Picker
            modelPickerSection(
                title: "Speech-to-Text",
                icon: "mic.fill",
                currentSelection: sttDisplayName,
                pickerId: "stt"
            ) {
                sttModelList
            }

            // LLM Picker
            modelPickerSection(
                title: "AI Model (LLM)",
                icon: "brain",
                currentSelection: llmDisplayName,
                pickerId: "llm"
            ) {
                llmModelList
            }

            // TTS Picker
            modelPickerSection(
                title: "Text-to-Speech",
                icon: "speaker.wave.2.fill",
                currentSelection: ttsDisplayName,
                pickerId: "tts"
            ) {
                ttsModelList
            }

            // Keyboard shortcut
            Divider().opacity(0.5)

            HStack {
                Label("Shortcut", systemImage: "keyboard")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                KeyboardShortcuts.Recorder(for: .voiceConversation)
                    .fixedSize()
            }
        }
        .padding(20)
        .background(CardBackground(isSelected: false, cornerRadius: 16))
    }

    // MARK: - Picker Section

    private func modelPickerSection<Content: View>(
        title: String,
        icon: String,
        currentSelection: String,
        pickerId: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedPicker = expandedPicker == pickerId ? nil : pickerId
                }
            } label: {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(currentSelection)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Image(systemName: expandedPicker == pickerId ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            if expandedPicker == pickerId {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - STT Model List

    private var sttDisplayName: String {
        if let name = config.sttModelName {
            return transcriptionModelManager.allAvailableModels.first { $0.name == name }?.displayName ?? name
        }
        return "App Default"
    }

    @ViewBuilder
    private var sttModelList: some View {
        VStack(spacing: 4) {
            // "Use app default" option
            modelRow(
                name: "App Default",
                detail: transcriptionModelManager.currentTranscriptionModel?.displayName ?? "None",
                isSelected: config.sttModelName == nil,
                speed: nil, quality: nil
            ) {
                config.sttModelName = nil
                expandedPicker = nil
            }

            ForEach(transcriptionModelManager.allAvailableModels, id: \.id) { model in
                modelRow(
                    name: model.displayName,
                    detail: model.provider.rawValue,
                    isSelected: config.sttModelName == model.name,
                    speed: nil, quality: nil
                ) {
                    config.sttModelName = model.name
                    expandedPicker = nil
                }
            }
        }
    }

    // MARK: - LLM Model List

    private var llmDisplayName: String {
        VoiceTutorConfig.llmModels.first { $0.id == config.llmModel }?.displayName ?? config.llmModel
    }

    @ViewBuilder
    private var llmModelList: some View {
        VStack(spacing: 4) {
            ForEach(VoiceTutorConfig.llmModels) { model in
                modelRow(
                    name: model.displayName,
                    detail: model.costLabel,
                    isSelected: config.llmModel == model.id,
                    speed: model.speed, quality: model.quality
                ) {
                    config.llmModel = model.id
                    config.llmProvider = model.provider
                    expandedPicker = nil
                }
            }
        }
    }

    // MARK: - TTS Model List

    private var ttsDisplayName: String {
        VoiceTutorConfig.ttsModels.first { $0.id == config.ttsModel }?.displayName ?? config.ttsModel
    }

    @ViewBuilder
    private var ttsModelList: some View {
        VStack(spacing: 4) {
            ForEach(VoiceTutorConfig.ttsModels) { model in
                modelRow(
                    name: model.displayName,
                    detail: model.costLabel,
                    isSelected: config.ttsModel == model.id,
                    speed: model.speed, quality: model.quality
                ) {
                    config.ttsModel = model.id
                    config.ttsProvider = model.provider
                    expandedPicker = nil
                }
            }
        }
    }

    // MARK: - Model Row

    private func modelRow(
        name: String,
        detail: String,
        isSelected: Bool,
        speed: Double?,
        quality: Double?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary.opacity(0.4))
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(detail)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        if let speed = speed {
                            HStack(spacing: 3) {
                                Text("Speed")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                progressDotsWithNumber(value: speed)
                            }
                        }
                        if let quality = quality {
                            HStack(spacing: 3) {
                                Text("Quality")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                progressDotsWithNumber(value: quality)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.blue.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
