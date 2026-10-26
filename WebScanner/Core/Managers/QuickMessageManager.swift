//
//  QuickMessageManager.swift
//  WebScanner
//
//

import Foundation
import Combine

public struct QuickMessageItem: Codable, Identifiable, Equatable {
    public let id: String
    public var title: String
    public var message: String
    
    public init(id: String = UUID().uuidString, title: String, message: String) {
        self.id = id
        self.title = title
        self.message = message
    }
}

@MainActor
public final class QuickMessageManager: ObservableObject {
    public static let shared = QuickMessageManager()
    
    public static let defaultMessages: [String] = [
        "Hello!",
        "Hi there!",
        "Hey!",
        "How are you?",
        "How’s it going?",
        "What’s up?",
        "Good morning!",
        "Good afternoon!",
        "Good evening!",
        "Hey, how are you?",
        "How have you been?",
        "Nice to see you!",
        "Hope you’re doing well!",
        "How’s everything?",
        "What’s new?",
        "Hi, how’s life?",
        "Hey there!",
        "How are things?",
        "Glad to see you!",
        "Hi, how are you doing?"
    ]
    
    @Published public private(set) var messages: [String] = defaultMessages
    
    private init() {
        self.messages = Self.defaultMessages
    }
}
