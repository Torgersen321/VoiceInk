import Foundation
import os

struct TopicProgress: Codable, Identifiable {
    var id: String { topic }
    let topic: String
    var firstSeen: Date
    var lastSeen: Date
    var questionsAsked: Int
    var correctAnswers: Int
    var keyTakeaways: [String]

    var accuracy: Double {
        guard questionsAsked > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAsked)
    }

    var isWeakSpot: Bool {
        questionsAsked >= 2 && accuracy < 0.5
    }
}

@MainActor
class LearningProgress: ObservableObject {
    private let logger = Logger(subsystem: "com.prakashjoshipax.voiceink", category: "LearningProgress")

    @Published var topics: [TopicProgress] = []
    @Published var currentTopic: String?

    private let storageURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.prakashjoshipax.VoiceInk")
        self.storageURL = appSupport.appendingPathComponent("learning_progress.json")
        load()
    }

    // MARK: - Topic Management

    func startTopic(_ topic: String) {
        currentTopic = topic
        if let index = topics.firstIndex(where: { $0.topic.lowercased() == topic.lowercased() }) {
            topics[index].lastSeen = Date()
        } else {
            topics.append(TopicProgress(
                topic: topic,
                firstSeen: Date(),
                lastSeen: Date(),
                questionsAsked: 0,
                correctAnswers: 0,
                keyTakeaways: []
            ))
        }
        save()
    }

    func recordQuizResult(correct: Bool) {
        guard let topic = currentTopic,
              let index = topics.firstIndex(where: { $0.topic.lowercased() == topic.lowercased() }) else { return }
        topics[index].questionsAsked += 1
        if correct {
            topics[index].correctAnswers += 1
        }
        topics[index].lastSeen = Date()
        save()
    }

    func addTakeaway(_ takeaway: String) {
        guard let topic = currentTopic,
              let index = topics.firstIndex(where: { $0.topic.lowercased() == topic.lowercased() }) else { return }
        topics[index].keyTakeaways.append(takeaway)
        save()
    }

    var weakSpots: [TopicProgress] {
        topics.filter { $0.isWeakSpot }
    }

    var recentTopics: [TopicProgress] {
        topics.sorted { $0.lastSeen > $1.lastSeen }.prefix(5).map { $0 }
    }

    /// Summary string to inject into system prompt for context
    func progressSummary() -> String? {
        guard !topics.isEmpty else { return nil }

        var parts: [String] = []

        let weak = weakSpots
        if !weak.isEmpty {
            let names = weak.map { $0.topic }.joined(separator: ", ")
            parts.append("The user has struggled with: \(names). Consider revisiting these if relevant.")
        }

        let recent = recentTopics
        if !recent.isEmpty {
            let summaries = recent.map { t in
                let acc = t.questionsAsked > 0 ? "\(Int(t.accuracy * 100))% accuracy" : "no quizzes yet"
                return "\(t.topic) (\(acc))"
            }
            parts.append("Recent topics: \(summaries.joined(separator: ", ")).")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(topics)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            logger.error("Failed to save learning progress: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            topics = try JSONDecoder().decode([TopicProgress].self, from: data)
        } catch {
            logger.error("Failed to load learning progress: \(error.localizedDescription, privacy: .public)")
        }
    }
}
