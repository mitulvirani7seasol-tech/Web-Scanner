//
//  RecentChatManager.swift
//  WebScanner
//

import Foundation
import Combine

public struct RecentChatItem: Codable, Identifiable, Equatable {
    public let id: String
    public var phoneNumber: String
    public var message: String
    public var date: Date
    
    public init(id: String = UUID().uuidString, phoneNumber: String, message: String = "", date: Date = Date()) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.message = message
        self.date = date
    }
    
    public var timeAgoFormatted: String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 10 {
            return "Just Now".localized
        } else if diff < 60 {
            return "\(diff) \("Second Ago".localized)"
        } else if diff < 3600 {
            let minutes = max(1, diff / 60)
            return "\(minutes) \("Minute Ago".localized)"
        } else if diff < 86400 {
            let hours = max(1, diff / 3600)
            return "\(hours) \("Hours Ago".localized)"
        } else {
            let days = max(1, diff / 86400)
            return "\(days) \("Days Ago".localized)"
        }
    }
}

@MainActor
public final class RecentChatManager: ObservableObject {
    public static let shared = RecentChatManager()
    private let storageKey = "direct_chat_recent_chats"
    
    @Published public private(set) var recentChats: [RecentChatItem] = []
    
    private init() {
        loadChats()
    }
    
    public func loadChats() {
        let dummyNumbers = ["+91 98765 43210", "+91 91234 56789", "+91 90456 78901", "+91 90678 90123"]
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let list = try? JSONDecoder().decode([RecentChatItem].self, from: data) {
            let cleaned = list.filter { !dummyNumbers.contains($0.phoneNumber) }
            self.recentChats = cleaned
            if cleaned.count != list.count {
                save(cleaned)
            }
        } else {
            self.recentChats = []
        }
    }
    
    public func addChat(phoneNumber: String, message: String) {
        var list = recentChats
        list.removeAll { $0.phoneNumber == phoneNumber }
        let newChat = RecentChatItem(phoneNumber: phoneNumber, message: message, date: Date())
        list.insert(newChat, at: 0)
        save(list)
    }
    
    public func delete(id: String) {
        let list = recentChats.filter { $0.id != id }
        save(list)
    }
    
    public func clearAll() {
        save([])
    }
    
    private func save(_ list: [RecentChatItem]) {
        self.recentChats = list
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
