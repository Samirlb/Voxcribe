import Foundation
import Translation
import OSLog

@Observable
final class TranslationService {
    var isTranslating = false

    private var cache = LRUCache<String, String>(capacity: 80)
    private let localTimeout: TimeInterval = 20
    private let onlineTimeout: TimeInterval = 15

    func translate(
        _ text: String,
        from source: Language,
        to target: Language,
        engine: TranslationEngine = .auto
    ) async -> String? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard source != target else { return text }

        let cacheKey = "\(source.rawValue):\(target.rawValue):\(text)"
        if let cached = cache.get(cacheKey) {
            return cached
        }

        isTranslating = true
        defer { isTranslating = false }

        var result: String?

        switch engine {
        case .local:
            result = await translateLocal(text, from: source, to: target)
        case .online:
            result = await translateOnline(text, from: source, to: target)
        case .auto:
            result = await translateLocal(text, from: source, to: target)
            if result == nil {
                AppLogger.translation.info("Local failed, falling back to online")
                result = await translateOnline(text, from: source, to: target)
            }
        }

        if let result {
            cache.set(cacheKey, value: result)
        }

        return result
    }

    func clearCache() {
        cache.clear()
    }

    // MARK: - Local (Apple Translation)

    private func translateLocal(_ text: String, from source: Language, to target: Language) async -> String? {
        do {
            let session = TranslationSession(
                installedSource: source.translationLocaleLanguage,
                target: target.translationLocaleLanguage
            )

            let response = try await withThrowingTaskGroup(of: TranslationSession.Response.self) { group in
                group.addTask {
                    try await session.translate(text)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(self.localTimeout))
                    throw VoxcribeTranslationError.timeout
                }

                let result = try await group.next()!
                group.cancelAll()
                return result
            }

            AppLogger.translation.debug("Local: \(text.prefix(30)) → \(response.targetText.prefix(30))")
            return response.targetText
        } catch is CancellationError {
            return nil
        } catch {
            AppLogger.translation.error("Local translation failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Online (MyMemory)

    private func translateOnline(_ text: String, from source: Language, to target: Language) async -> String? {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        let sourceLang = String(source.rawValue.prefix(2))
        let targetLang = String(target.rawValue.prefix(2))
        let urlString = "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=\(sourceLang)|\(targetLang)"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await withThrowingTaskGroup(of: (Data, URLResponse).self) { group in
                group.addTask {
                    try await URLSession.shared.data(from: url)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(self.onlineTimeout))
                    throw VoxcribeTranslationError.timeout
                }

                let result = try await group.next()!
                group.cancelAll()
                return result
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let decoded = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
            guard decoded.responseStatus == 200,
                  let translatedText = decoded.responseData?.translatedText,
                  !translatedText.isEmpty else {
                return nil
            }

            AppLogger.translation.debug("Online: \(text.prefix(30)) → \(translatedText.prefix(30))")
            return translatedText
        } catch is CancellationError {
            return nil
        } catch {
            AppLogger.translation.error("Online translation failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Models

private struct MyMemoryResponse: Codable {
    let responseData: ResponseData?
    let responseStatus: Int

    struct ResponseData: Codable {
        let translatedText: String
        let match: Double?
    }
}

enum VoxcribeTranslationError: LocalizedError {
    case timeout
    case unavailable
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .timeout: "Translation timed out"
        case .unavailable: "Translation service unavailable"
        case .invalidResponse: "Invalid translation response"
        }
    }
}

// MARK: - LRU Cache

final class LRUCache<Key: Hashable, Value>: @unchecked Sendable {
    private var cache: [Key: Value] = [:]
    private var order: [Key] = []
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
    }

    func get(_ key: Key) -> Value? {
        guard let value = cache[key] else { return nil }
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }

    func set(_ key: Key, value: Value) {
        if cache[key] != nil {
            order.removeAll { $0 == key }
        } else if cache.count >= capacity {
            if let oldest = order.first {
                cache.removeValue(forKey: oldest)
                order.removeFirst()
            }
        }
        cache[key] = value
        order.append(key)
    }

    func clear() {
        cache.removeAll()
        order.removeAll()
    }
}
