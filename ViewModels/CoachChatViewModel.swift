import Foundation

@MainActor
final class CoachChatViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var config: CoachPublicConfig?
    @Published var isLoadingConfig = false
    @Published var isSending = false
    @Published var errorBanner: String?
    @Published private(set) var bubbles: [CoachChatBubble] = []

    var isAPIConfigured: Bool { ExerciseAPIConfiguration.isConfigured }

    private func describe(_ error: Error) -> String {
        if let e = error as? LocalizedError, let d = e.errorDescription, !d.isEmpty {
            return d
        }
        return error.localizedDescription
    }

    func loadConfigIfNeeded() async {
        guard isAPIConfigured else {
            config = nil
            return
        }
        guard config == nil else { return }
        isLoadingConfig = true
        errorBanner = nil
        defer { isLoadingConfig = false }
        do {
            config = try await CoachAPIService.shared.fetchPublicConfig()
        } catch let e as CoachAPIError {
            config = CoachPublicConfig.default()
            errorBanner = e.localizedDescription
        } catch {
            config = CoachPublicConfig.default()
            errorBanner = describe(error)
        }
    }

    func sendMessage(userFirstName: String?) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending, isAPIConfigured else { return }

        isSending = true
        errorBanner = nil
        defer { isSending = false }

        let userBubble = CoachChatBubble(role: .user, text: trimmed)
        bubbles.append(userBubble)
        inputText = ""

        var payload: [CoachChatTurn] = bubbles.map(\.chatTurn)

        do {
            let reply = try await CoachAPIService.shared.sendChat(userName: userFirstName, messages: payload)
            bubbles.append(CoachChatBubble(role: .assistant, text: reply))
        } catch let e as CoachAPIError {
            bubbles.removeLast()
            inputText = trimmed
            errorBanner = e.localizedDescription
        } catch {
            bubbles.removeLast()
            inputText = trimmed
            errorBanner = describe(error)
        }
    }

    func sendChipPrompt(_ prompt: String, userFirstName: String?) async {
        inputText = prompt
        await sendMessage(userFirstName: userFirstName)
    }
}

struct CoachChatBubble: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String

    var chatTurn: CoachChatTurn {
        switch role {
        case .user:
            CoachChatTurn(role: "user", content: text)
        case .assistant:
            CoachChatTurn(role: "assistant", content: text)
        }
    }
}
