//
//  QuickReplyData.swift
//  WebScanner
//
//

import Foundation
import Combine

// MARK: - Quick Reply Template Model
public struct QuickReplyTemplate: Identifiable, Hashable {
    public var id: String { "\(category)_\(index)" }
    public let category: String
    public let index: Int
    public let text: String
}

// MARK: - Saved Quick Reply Message Model
public struct SavedQuickReplyMessage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var text: String
    public var category: String
    public var createdAt: Date
    
    public init(id: UUID = UUID(), text: String, category: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.category = category
        self.createdAt = createdAt
    }
}

// MARK: - Quick Reply Manager (Persistence)
public final class QuickReplyManager: ObservableObject {
    public static let shared = QuickReplyManager()
    
    private let userDefaultsKey = "quick_reply_saved_messages_v1"
    
    @Published public var savedMessages: [SavedQuickReplyMessage] = []
    
    private init() {
        loadSavedMessages()
    }
    
    public func loadSavedMessages() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            self.savedMessages = []
            return
        }
        do {
            let decoded = try JSONDecoder().decode([SavedQuickReplyMessage].self, from: data)
            self.savedMessages = decoded
        } catch {
            print("Failed to decode saved quick reply messages: \(error)")
            self.savedMessages = []
        }
    }
    
    public func addMessage(text: String, category: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = SavedQuickReplyMessage(text: trimmed, category: category)
        savedMessages.insert(message, at: 0)
        persist()
    }
    
    public func deleteMessage(id: UUID) {
        savedMessages.removeAll { $0.id == id }
        persist()
    }
    
    private func persist() {
        do {
            let encoded = try JSONEncoder().encode(savedMessages)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } catch {
            print("Failed to encode saved quick reply messages: \(error)")
        }
    }
}

// MARK: - Template Data
public struct QuickReplyData {
    public static let categories: [String] = [
        "Greetings",
        "Festivals",
        "Sales",
        "Birthday",
        "Thanksgiving"
    ]
    
    public static let allTemplates: [QuickReplyTemplate] = {
        var list: [QuickReplyTemplate] = []
        for (catIndex, cat) in categories.enumerated() {
            let messages = messagesForCategory(cat)
            for (idx, msg) in messages.enumerated() {
                list.append(QuickReplyTemplate(category: cat, index: idx + 1, text: msg))
            }
        }
        return list
    }()
    
    public static func templates(for category: String?) -> [QuickReplyTemplate] {
        guard let cat = category, cat != "All" else {
            return allTemplates
        }
        return allTemplates.filter { $0.category == cat }
    }
    
    private static func messagesForCategory(_ category: String) -> [String] {
        switch category {
        case "Greetings":
            return [
                "Hey! How are you?",
                "Good morning! Have a great day.",
                "Hello! Hope you're doing well.",
                "Hi there! Nice to hear from you.",
                "Good evening! How was your day?",
                "Hey buddy! What's up?",
                "Wishing you a wonderful day!",
                "Hello! Stay happy and blessed.",
                "Hi! Sending positive vibes your way.",
                "Hope your day is going great!",
                "Hey! Long time no see.",
                "Hello! Keep smiling always.",
                "Good afternoon! Take care.",
                "Hi friend! Have an amazing day.",
                "Hey! Just checking in on you.",
                "Sending you warm wishes today.",
                "Hello! Hope everything is fine.",
                "Stay safe and keep smiling!",
                "Wishing you peace and happiness.",
                "Hey! Have a fantastic day ahead."
            ]
            
        case "Festivals":
            return [
                "Wishing you a joyful festival!",
                "May your home be filled with happiness.",
                "Happy festivities to you and your family!",
                "Celebrate with love, laughter, and joy.",
                "May this festival bring new beginnings.",
                "Wishing you peace and prosperity.",
                "Have a bright and beautiful celebration!",
                "May your days sparkle with happiness.",
                "Sending you festive love and blessings.",
                "Enjoy every moment of this celebration!",
                "May your wishes come true this festive season.",
                "Let the celebrations begin!",
                "Wishing you endless smiles and sweet memories.",
                "May your life shine with positivity.",
                "Celebrate safely and spread happiness.",
                "Sending warm festive wishes your way.",
                "May joy fill every corner of your home.",
                "Have a wonderful festival with loved ones.",
                "May blessings and good fortune follow you.",
                "Happy festival! Keep spreading love."
            ]
            
        case "Sales":
            return [
                "Great deals are waiting for you!",
                "Shop now and save more!",
                "Don't miss our special offers.",
                "Grab your favorites before they're gone!",
                "Big savings, just for you!",
                "Your next favorite deal is here.",
                "Limited-time offers are available now!",
                "Shop smart and save big.",
                "Special prices, amazing products!",
                "Hurry! Your favorite deals await.",
                "Treat yourself without breaking the bank.",
                "More shopping, more savings!",
                "Discover deals you'll love.",
                "Upgrade your favorites for less.",
                "It's the perfect time to shop!",
                "Amazing offers you don't want to miss.",
                "Save today and smile tomorrow.",
                "Your shopping wishlist just got better.",
                "Find your favorite products at great prices.",
                "Shop today and enjoy the savings!"
            ]
            
        case "Birthday":
            return [
                "Happy Birthday! Have an amazing day.",
                "Wishing you lots of love and happiness!",
                "May all your dreams come true.",
                "Have a wonderful birthday celebration!",
                "Cheers to another fantastic year!",
                "Wishing you health, success, and joy.",
                "Keep smiling and shining always!",
                "May your day be full of surprises.",
                "Sending you warm birthday wishes!",
                "Have the happiest birthday ever!",
                "May this year bring endless opportunities.",
                "Enjoy your special day to the fullest!",
                "Another year, another reason to celebrate!",
                "Wishing you a lifetime of happiness.",
                "May your birthday be as special as you are.",
                "Stay blessed and keep achieving great things.",
                "Sending you hugs and birthday smiles!",
                "Here's to new adventures and beautiful memories.",
                "Have a cake-filled and joyful birthday!",
                "Happy Birthday! Keep shining bright."
            ]
            
        case "Thanksgiving":
            return [
                "Happy Thanksgiving! Stay blessed.",
                "Wishing you a day full of gratitude.",
                "Thankful for wonderful people like you.",
                "May your home be filled with love.",
                "Sending warm Thanksgiving wishes!",
                "Wishing you happiness and abundance.",
                "Enjoy good food and great company!",
                "May gratitude fill your heart today.",
                "Have a peaceful and joyful Thanksgiving.",
                "Thank you for being part of my life.",
                "Wishing you countless reasons to smile.",
                "May your table be full and your heart fuller.",
                "Sending love and blessings this Thanksgiving.",
                "Enjoy every precious moment with family.",
                "Grateful for your kindness and friendship.",
                "May this season bring peace and prosperity.",
                "Wishing you warmth, laughter, and happiness.",
                "Here's to love, gratitude, and togetherness!",
                "May your blessings be many this year.",
                "Happy Thanksgiving! Eat well and smile often."
            ]
            
        default:
            return []
        }
    }
}
