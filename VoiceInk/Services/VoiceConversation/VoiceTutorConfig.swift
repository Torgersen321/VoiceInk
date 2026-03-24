import Foundation

struct TTSModelInfo: Identifiable {
    let id: String
    let displayName: String
    let provider: String
    let speed: Double      // 0-10 scale
    let quality: Double    // 0-10 scale
    let costLabel: String  // "free", "low", "medium", "high"
}

struct LLMModelInfo: Identifiable {
    let id: String
    let displayName: String
    let provider: String   // AIProvider rawValue
    let speed: Double
    let quality: Double
    let costLabel: String
}

@MainActor
class VoiceTutorConfig: ObservableObject {

    // MARK: - Persisted selections

    @Published var sttModelName: String? {
        didSet { UserDefaults.standard.set(sttModelName, forKey: "voiceTutorSTTModel") }
    }

    @Published var llmProvider: String {
        didSet { UserDefaults.standard.set(llmProvider, forKey: "voiceTutorLLMProvider") }
    }

    @Published var llmModel: String {
        didSet { UserDefaults.standard.set(llmModel, forKey: "voiceTutorLLMModel") }
    }

    @Published var ttsProvider: String {
        didSet { UserDefaults.standard.set(ttsProvider, forKey: "voiceTutorTTSProvider") }
    }

    @Published var ttsModel: String {
        didSet { UserDefaults.standard.set(ttsModel, forKey: "voiceTutorTTSModel") }
    }

    init() {
        self.sttModelName = UserDefaults.standard.string(forKey: "voiceTutorSTTModel")
        self.llmProvider = UserDefaults.standard.string(forKey: "voiceTutorLLMProvider") ?? AIProvider.anthropic.rawValue
        self.llmModel = UserDefaults.standard.string(forKey: "voiceTutorLLMModel") ?? "claude-sonnet-4-20250514"
        self.ttsProvider = UserDefaults.standard.string(forKey: "voiceTutorTTSProvider") ?? "elevenLabs"
        self.ttsModel = UserDefaults.standard.string(forKey: "voiceTutorTTSModel") ?? "eleven_turbo_v2_5"
    }

    // MARK: - Available TTS Models

    static let ttsModels: [TTSModelInfo] = [
        TTSModelInfo(id: "eleven_turbo_v2_5", displayName: "ElevenLabs Turbo v2.5", provider: "elevenLabs", speed: 9.5, quality: 8.0, costLabel: "low"),
        TTSModelInfo(id: "eleven_multilingual_v2", displayName: "ElevenLabs Multilingual v2", provider: "elevenLabs", speed: 7.0, quality: 9.5, costLabel: "medium"),
        TTSModelInfo(id: "eleven_monolingual_v1", displayName: "ElevenLabs v1", provider: "elevenLabs", speed: 8.0, quality: 7.0, costLabel: "low"),
        TTSModelInfo(id: "system", displayName: "System Voice (macOS)", provider: "system", speed: 10.0, quality: 5.0, costLabel: "free"),
    ]

    // MARK: - Available LLM Models (for voice conversation)

    static let llmModels: [LLMModelInfo] = [
        // Anthropic
        LLMModelInfo(id: "claude-sonnet-4-20250514", displayName: "Claude Sonnet 4", provider: "Anthropic", speed: 8.0, quality: 9.0, costLabel: "medium"),
        LLMModelInfo(id: "claude-3-5-haiku-20241022", displayName: "Claude 3.5 Haiku", provider: "Anthropic", speed: 9.5, quality: 7.5, costLabel: "low"),
        // OpenAI
        LLMModelInfo(id: "gpt-4o", displayName: "GPT-4o", provider: "OpenAI", speed: 8.0, quality: 9.0, costLabel: "medium"),
        LLMModelInfo(id: "gpt-4o-mini", displayName: "GPT-4o Mini", provider: "OpenAI", speed: 9.5, quality: 7.5, costLabel: "low"),
        // Groq (fast inference)
        LLMModelInfo(id: "llama-3.3-70b-versatile", displayName: "Llama 3.3 70B (Groq)", provider: "Groq", speed: 10.0, quality: 8.0, costLabel: "low"),
        LLMModelInfo(id: "llama-3.1-8b-instant", displayName: "Llama 3.1 8B (Groq)", provider: "Groq", speed: 10.0, quality: 6.5, costLabel: "free"),
        // Cerebras
        LLMModelInfo(id: "llama3.1-70b", displayName: "Llama 3.1 70B (Cerebras)", provider: "Cerebras", speed: 10.0, quality: 8.0, costLabel: "low"),
        // Gemini
        LLMModelInfo(id: "gemini-2.0-flash", displayName: "Gemini 2.0 Flash", provider: "Gemini", speed: 9.0, quality: 8.5, costLabel: "low"),
        // Ollama (local)
        LLMModelInfo(id: "ollama-local", displayName: "Ollama (Local)", provider: "Ollama", speed: 7.0, quality: 7.0, costLabel: "free"),
    ]

    // MARK: - Resolved provider

    var resolvedAIProvider: AIProvider? {
        AIProvider(rawValue: llmProvider)
    }
}
