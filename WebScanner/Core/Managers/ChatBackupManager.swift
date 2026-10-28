//
//  ChatBackupManager.swift
//  WebScanner
//

import Foundation
import Combine
import ZIPFoundation

public struct ChatPollOption: Equatable, Hashable {
    public let text: String
    public let count: Int
    
    public init(text: String, count: Int) {
        self.text = text
        self.count = count
    }
}

public struct ChatDocumentInfo: Equatable, Hashable {
    public let name: String
    public let url: URL?
    public let pages: Int
    public let sizeText: String
    public let ext: String
    
    public init(name: String, url: URL? = nil, pages: Int = 1, sizeText: String = "", ext: String = "") {
        self.name = name
        self.url = url
        self.pages = pages
        self.sizeText = sizeText.isEmpty ? "1.2 MB" : sizeText
        self.ext = ext.isEmpty ? (name as NSString).pathExtension.lowercased() : ext.lowercased()
    }
}

public struct ChatEventInfo: Equatable, Hashable {
    public let title: String
    public let timeText: String
    public let attendees: String
    
    public init(title: String, timeText: String, attendees: String = "1 Going") {
        self.title = title
        self.timeText = timeText
        self.attendees = attendees
    }
}

public enum MessageType: Equatable {
    case text(String)
    case images([URL])
    case videos([URL])
    case documents([URL])
    case documentCard(ChatDocumentInfo)
    case audio([URL])
    case location(lat: Double, lon: Double, url: URL, title: String)
    case contact(name: String, number: String, vcfURL: URL? = nil)
    case poll(question: String, options: [ChatPollOption])
    case event(ChatEventInfo)
    case header(String)
}

public struct ChatMessage: Identifiable, Equatable {
    public let id = UUID().uuidString
    public let sender: String
    public let date: Date
    public let time: String
    public let type: MessageType
    public let isMe: Bool
    
    public var formattedTime: String {
        ChatBackupManager.formatDisplayTime(time)
    }
    
    public var previewText: String {
        switch type {
        case .text(let msg): return msg
        case .images: return "📷 Photo"
        case .videos: return "🎥 Video"
        case .documents: return "📄 Document"
        case .documentCard(let doc): return "📄 \(doc.name)"
        case .audio: return "🎵 Audio"
        case .location(_, _, _, let title): return "📍 \(title)"
        case .contact(let name, _, _): return "👤 Contact: \(name)"
        case .poll(let q, _): return "📊 Poll: \(q)"
        case .event(let ev): return "📅 Event: \(ev.title)"
        case .header(let h): return h
        }
    }
}

public struct ChatSection: Identifiable {
    public var id: String { title }
    public let date: Date
    public let title: String
    public let messages: [ChatMessage]
}

public struct ChatConversation: Identifiable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var lastMessage: String
    public var lastDate: Date
    public var folderURL: URL
    public var fileURL: URL?
    public var messageCount: Int
}

public struct MediaAttachment: Identifiable {
    public var id: String { url.absoluteString }
    public let url: URL
    public let date: Date
    public let isVideo: Bool
}

public struct LinkAttachment: Identifiable {
    public var id: String { url }
    public let url: String
    public let date: Date
}

public struct DocAttachment: Identifiable {
    public var id: String { url.absoluteString }
    public let url: URL
    public let name: String
    public let date: Date
}

@MainActor
public final class ChatBackupManager: ObservableObject {
    public static let shared = ChatBackupManager()
    
    @Published public private(set) var conversations: [ChatConversation] = []
    @Published public private(set) var allMedia: [MediaAttachment] = []
    @Published public private(set) var allLinks: [LinkAttachment] = []
    @Published public private(set) var allDocs: [DocAttachment] = []
    @Published public var isImporting: Bool = false
    
    private let fileManager = FileManager.default
    
    public let candidateGroupIDs = ["group.com.WebScanner.app", "group.com.WebScanner.app1"]
    public let appGroupID = WSAPP_AppStrings.groupID
    
    public var backupCandidateDirectories: [URL] {
        var dirs: [URL] = []
        for group in candidateGroupIDs {
            if let groupContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: group) {
                let dir = groupContainer.appendingPathComponent("ChatBackups", isDirectory: true)
                if !fileManager.fileExists(atPath: dir.path) {
                    try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
                }
                dirs.append(dir)
            }
        }
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent("ChatBackups", isDirectory: true)
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            dirs.append(dir)
        }
        return dirs
    }
    
    public var backupRootDirectory: URL {
        if let firstValid = backupCandidateDirectories.first {
            return firstValid
        }
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ChatBackups", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {
        loadConversations()
    }
    
    public func consumePendingSharedChat() -> String? {
        var foundChatName: String? = nil
        for group in candidateGroupIDs {
            if let defaults = UserDefaults(suiteName: group) {
                if defaults.bool(forKey: "shouldOpenAppAfterShare") {
                    if foundChatName == nil || foundChatName?.isEmpty == true {
                        foundChatName = defaults.string(forKey: "latestSharedChatName")
                    }
                }
                defaults.set(false, forKey: "shouldOpenAppAfterShare")
                defaults.removeObject(forKey: "latestSharedChatName")
                defaults.synchronize()
            }
        }
        return foundChatName
    }
    
    public func clearPendingSharedChatFlags() {
        for group in candidateGroupIDs {
            if let defaults = UserDefaults(suiteName: group) {
                defaults.set(false, forKey: "shouldOpenAppAfterShare")
                defaults.removeObject(forKey: "latestSharedChatName")
                defaults.synchronize()
            }
        }
    }
    
    public static func cleanChatTitle(_ raw: String) -> String {
        var cleaned = raw
        cleaned = cleaned.replacingOccurrences(of: ".zip", with: "", options: .caseInsensitive)
        cleaned = cleaned.replacingOccurrences(of: ".txt", with: "", options: .caseInsensitive)
        
        let prefixes = [
            "WhatsApp Chat - ",
            "WhatsApp Chat with ",
            "WhatsApp Chat : ",
            "WhatsApp Chat _ ",
            "WhatsApp-Chat mit ",
            "Discussion WhatsApp avec ",
            "Chat di WhatsApp con ",
            "Chat de WhatsApp con ",
            "Conversa do WhatsApp com ",
            "WhatsApp-chat met "
        ]
        
        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }
        
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-_:")))
        return cleaned.isEmpty ? raw : cleaned
    }
    
    // MARK: - Testing Flag for iPad & iPhone UI verification (Set to false to remove dummy data)
    public static var isDummyDataEnabled: Bool = false
    
    public func loadConversations() {
        var list: [ChatConversation] = []
        var mediaList: [MediaAttachment] = []
        var linkList: [LinkAttachment] = []
        var docList: [DocAttachment] = []
        var seenFolderNames = Set<String>()
        
        for rootDir in backupCandidateDirectories {
            if let looseFiles = try? fileManager.contentsOfDirectory(at: rootDir, includingPropertiesForKeys: nil) {
                for file in looseFiles where file.pathExtension.lowercased() == "zip" {
                    let base = file.deletingPathExtension().lastPathComponent
                    let targetFolder = rootDir.appendingPathComponent(base, isDirectory: true)
                    var isDir: ObjCBool = false
                    let exists = fileManager.fileExists(atPath: targetFolder.path, isDirectory: &isDir)
                    if !exists || !isDir.boolValue || detectChatFile(in: targetFolder) == nil {
                        try? fileManager.createDirectory(at: targetFolder, withIntermediateDirectories: true)
                        try? fileManager.unzipItem(at: file, to: targetFolder)
                    }
                }
                
                for file in looseFiles where file.pathExtension.lowercased() == "txt" {
                    let base = file.deletingPathExtension().lastPathComponent
                    let targetFolder = rootDir.appendingPathComponent(base, isDirectory: true)
                    var isDir: ObjCBool = false
                    if !fileManager.fileExists(atPath: targetFolder.path, isDirectory: &isDir) || !isDir.boolValue {
                        try? fileManager.createDirectory(at: targetFolder, withIntermediateDirectories: true)
                        let targetFile = targetFolder.appendingPathComponent(file.lastPathComponent)
                        try? fileManager.moveItem(at: file, to: targetFile)
                    }
                }
            }
            
            guard let subdirs = try? fileManager.contentsOfDirectory(at: rootDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else {
                continue
            }
            
            for folder in subdirs {
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: folder.path, isDirectory: &isDir), isDir.boolValue else {
                    continue
                }
                
                let rawFolderName = folder.lastPathComponent
                if seenFolderNames.contains(rawFolderName) {
                    continue
                }
                
                let chatFile = detectChatFile(in: folder)
                var chatName = Self.cleanChatTitle(rawFolderName)
                
                let messages = chatFile != nil ? parseChatFile(url: chatFile!, mediaFolder: folder, chatName: chatName) : []
                
                if chatName.lowercased() == "_chat" || chatName.lowercased() == "chat" || chatName.lowercased() == "whatsapp chat" || chatName.isEmpty {
                    for msg in messages {
                        if !msg.isMe && !msg.sender.isEmpty && msg.sender.lowercased() != "you" && !msg.sender.lowercased().contains("messages and calls") {
                            chatName = msg.sender
                            break
                        }
                    }
                }
                
                let lastMsg = messages.reversed().first(where: {
                    if case .header = $0.type { return false }
                    return true
                })?.previewText ?? (messages.last?.previewText ?? "No messages")
                let lastDate = messages.last?.date ?? Date()
                
                seenFolderNames.insert(rawFolderName)
                
                list.append(ChatConversation(
                    id: rawFolderName,
                    name: chatName,
                    lastMessage: lastMsg,
                    lastDate: lastDate,
                    folderURL: folder,
                    fileURL: chatFile,
                    messageCount: messages.filter { if case .header = $0.type { return false }; return true }.count
                ))
                
                for msg in messages {
                    switch msg.type {
                    case .images(let urls):
                        for u in urls { mediaList.append(MediaAttachment(url: u, date: msg.date, isVideo: false)) }
                    case .videos(let urls):
                        for u in urls { mediaList.append(MediaAttachment(url: u, date: msg.date, isVideo: true)) }
                    case .documents(let urls):
                        for u in urls { docList.append(DocAttachment(url: u, name: u.lastPathComponent, date: msg.date)) }
                    case .documentCard(let doc):
                        if let u = doc.url { docList.append(DocAttachment(url: u, name: doc.name, date: msg.date)) }
                    case .text(let text):
                        let extracted = extractLinks(from: text)
                        for l in extracted { linkList.append(LinkAttachment(url: l, date: msg.date)) }
                    default:
                        break
                    }
                }
            }
        }
        
        if Self.isDummyDataEnabled {
            let dummyConvs = Self.generateDummyConversations()
            var merged = list
            let existingNames = Set(list.map { $0.name.lowercased() })
            for d in dummyConvs {
                if !existingNames.contains(d.name.lowercased()) {
                    merged.append(d)
                }
            }
            self.conversations = merged
        } else {
            self.conversations = list.sorted(by: { $0.lastDate > $1.lastDate })
        }
        self.allMedia = mediaList.sorted(by: { $0.date > $1.date })
        self.allLinks = linkList.sorted(by: { $0.date > $1.date })
        self.allDocs = docList.sorted(by: { $0.date > $1.date })
    }
    
    public func importChatFile(from fileURL: URL) async throws -> ChatConversation {
        isImporting = true
        defer { isImporting = false }
        
        let shouldStopAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccess { fileURL.stopAccessingSecurityScopedResource() }
        }
        
        let chatFolderName = fileURL.deletingPathExtension().lastPathComponent
        let destFolder = backupRootDirectory.appendingPathComponent(chatFolderName)
        
        if fileManager.fileExists(atPath: destFolder.path) {
            try? fileManager.removeItem(at: destFolder)
        }
        try fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
        
        let ext = fileURL.pathExtension.lowercased()
        if ext == "zip" {
            try fileManager.unzipItem(at: fileURL, to: destFolder)
        } else {
            let destFile = destFolder.appendingPathComponent(fileURL.lastPathComponent)
            try fileManager.copyItem(at: fileURL, to: destFile)
        }
        
        loadConversations()
        
        let cleanName = Self.cleanChatTitle(chatFolderName)
        guard let conv = conversations.first(where: { $0.id == chatFolderName || $0.name == cleanName }) else {
            throw NSError(domain: "ChatBackup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load imported chat."])
        }
        return conv
    }
    
    public func importChatZip(from zipURL: URL) async throws -> ChatConversation {
        try await importChatFile(from: zipURL)
    }
    
    public func deleteConversation(id: String) {
        if id.hasPrefix("dummy-") {
            conversations.removeAll(where: { $0.id == id })
            return
        }
        for rootDir in backupCandidateDirectories {
            let destFolder = rootDir.appendingPathComponent(id)
            try? fileManager.removeItem(at: destFolder)
            let destZip = rootDir.appendingPathComponent("\(id).zip")
            try? fileManager.removeItem(at: destZip)
        }
        loadConversations()
    }
    
    // MARK: - Dummy Data Generation for Testing on iPad & iPhone
    public static func generateDummyConversations() -> [ChatConversation] {
        let calendar = Calendar.current
        let now = Date()
        
        func dateAgo(days: Int, hours: Int = 0) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }
        
        let dummyFolder = URL(fileURLWithPath: NSTemporaryDirectory())
        
        return [
            ChatConversation(
                id: "dummy-jaymin",
                name: "Jaymin Patel",
                lastMessage: "Sure, see you at 5 PM! 👍",
                lastDate: dateAgo(days: 0, hours: 2),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 18
            ),
            ChatConversation(
                id: "dummy-kushang",
                name: "Kushang Kaklotar",
                lastMessage: "📷 Photo",
                lastDate: dateAgo(days: 0, hours: 5),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 24
            ),
            ChatConversation(
                id: "dummy-mitul",
                name: "Mitul Virani",
                lastMessage: "Project files uploaded to server",
                lastDate: dateAgo(days: 1),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 45
            ),
            ChatConversation(
                id: "dummy-98765",
                name: "+91 98765 43210",
                lastMessage: "Majama! How are you?",
                lastDate: dateAgo(days: 1, hours: 4),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 12
            ),
            ChatConversation(
                id: "dummy-devteam",
                name: "Dev Team Gujarat",
                lastMessage: "Meeting link: https://meet.google.com/abc-defg",
                lastDate: dateAgo(days: 2),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 110
            ),
            ChatConversation(
                id: "dummy-priya",
                name: "Priya Sharma",
                lastMessage: "👤 Contact: Kushang Kaklotar",
                lastDate: dateAgo(days: 3),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 8
            ),
            ChatConversation(
                id: "dummy-rahul",
                name: "Rahul Mehta",
                lastMessage: "🎵 Voice note (0:15)",
                lastDate: dateAgo(days: 4),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 15
            ),
            ChatConversation(
                id: "dummy-family",
                name: "Family Group ❤️",
                lastMessage: "Good morning everyone!",
                lastDate: dateAgo(days: 5),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 240
            ),
            ChatConversation(
                id: "dummy-amit",
                name: "Amit Shah",
                lastMessage: "📄 Project_Proposal.pdf",
                lastDate: dateAgo(days: 6),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 9
            ),
            ChatConversation(
                id: "dummy-79907",
                name: "+91 79907 17817",
                lastMessage: "Hi there",
                lastDate: dateAgo(days: 7),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 1
            ),
            ChatConversation(
                id: "dummy-neha",
                name: "Neha Joshi",
                lastMessage: "📊 Poll: Which meeting time works best?",
                lastDate: dateAgo(days: 8),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 32
            ),
            ChatConversation(
                id: "dummy-reunion",
                name: "College Reunion '24 🎓",
                lastMessage: "📅 Event: Annual Meetup",
                lastDate: dateAgo(days: 10),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 85
            ),
            ChatConversation(
                id: "dummy-bhavin",
                name: "Bhavin Vaghasiya",
                lastMessage: "🎥 Video clip",
                lastDate: dateAgo(days: 12),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 14
            ),
            ChatConversation(
                id: "dummy-sanjay",
                name: "Sanjay Dave",
                lastMessage: "📍 Location: Surat Diamond Bourse",
                lastDate: dateAgo(days: 14),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 7
            ),
            ChatConversation(
                id: "dummy-darshan",
                name: "Darshan Chauhan",
                lastMessage: "Got it, thanks brother!",
                lastDate: dateAgo(days: 18),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 22
            ),
            ChatConversation(
                id: "dummy-anjali",
                name: "Anjali Desai",
                lastMessage: "Can you send the presentation?",
                lastDate: dateAgo(days: 22),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 16
            ),
            ChatConversation(
                id: "dummy-hardik",
                name: "Hardik Patel",
                lastMessage: "Let's catch up this weekend",
                lastDate: dateAgo(days: 30),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 5
            ),
            ChatConversation(
                id: "dummy-pooja",
                name: "Pooja Trivedi",
                lastMessage: "Happy Birthday! 🎉",
                lastDate: dateAgo(days: 45),
                folderURL: dummyFolder,
                fileURL: nil,
                messageCount: 3
            )
        ]
    }
    
    public static func generateDummyMessages(for chatName: String) -> [ChatMessage] {
        let calendar = Calendar.current
        let now = Date()
        let today = now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        
        let dummyFolder = URL(fileURLWithPath: NSTemporaryDirectory())
        let sampleAudioURL = Bundle.main.url(forResource: "audio", withExtension: "mp3") ?? dummyFolder.appendingPathComponent("sample_audio.mp3")
        
        if chatName.contains("79907") {
            return [
                ChatMessage(
                    sender: "System",
                    date: today,
                    time: "2:24 PM",
                    type: .header("Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them."),
                    isMe: false
                ),
                ChatMessage(
                    sender: "+91 79907 17817",
                    date: today,
                    time: "2:24 PM",
                    type: .text("Hi there"),
                    isMe: false
                )
            ]
        }
        
        return [
            ChatMessage(
                sender: "System",
                date: threeDaysAgo,
                time: "10:00 AM",
                type: .header("Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them."),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: threeDaysAgo,
                time: "10:02 AM",
                type: .text("Hey \(chatName), kem cho? How is the iPad UI design looking?"),
                isMe: true
            ),
            ChatMessage(
                sender: chatName,
                date: threeDaysAgo,
                time: "10:04 AM",
                type: .text("Hello! Majama. Everything is looking clean in both landscape and portrait modes!"),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: twoDaysAgo,
                time: "2:15 PM",
                type: .text("Awesome! Can you share the latest project presentation and documents?"),
                isMe: true
            ),
            ChatMessage(
                sender: chatName,
                date: twoDaysAgo,
                time: "2:18 PM",
                type: .documentCard(ChatDocumentInfo(
                    name: "Design_Specifications_v2.pptx",
                    url: dummyFolder.appendingPathComponent("Design_Specifications_v2.pptx"),
                    pages: 8,
                    sizeText: "5.4 MB",
                    ext: "pptx"
                )),
                isMe: false
            ),
            ChatMessage(
                sender: chatName,
                date: twoDaysAgo,
                time: "2:20 PM",
                type: .documentCard(ChatDocumentInfo(
                    name: "iPad_Layout_Guide.pdf",
                    url: dummyFolder.appendingPathComponent("iPad_Layout_Guide.pdf"),
                    pages: 14,
                    sizeText: "3.8 MB",
                    ext: "pdf"
                )),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: twoDaysAgo,
                time: "2:25 PM",
                type: .documentCard(ChatDocumentInfo(
                    name: "Architecture_Review.docx",
                    url: dummyFolder.appendingPathComponent("Architecture_Review.docx"),
                    pages: 6,
                    sizeText: "2.1 MB",
                    ext: "docx"
                )),
                isMe: true
            ),
            ChatMessage(
                sender: chatName,
                date: yesterday,
                time: "11:15 AM",
                type: .audio([sampleAudioURL]),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: yesterday,
                time: "11:20 AM",
                type: .audio([sampleAudioURL]),
                isMe: true
            ),
            ChatMessage(
                sender: chatName,
                date: yesterday,
                time: "1:45 PM",
                type: .poll(
                    question: "Which iPad layout mode works best for you?",
                    options: [
                        ChatPollOption(text: "Landscape Mode", count: 4),
                        ChatPollOption(text: "Portrait Mode", count: 3),
                        ChatPollOption(text: "Both Look Great", count: 8)
                    ]
                ),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: yesterday,
                time: "3:30 PM",
                type: .event(ChatEventInfo(
                    title: "iPad Design Review & Signoff",
                    timeText: "Tomorrow, 4:00 PM",
                    attendees: "3 Going"
                )),
                isMe: true
            ),
            ChatMessage(
                sender: chatName,
                date: yesterday,
                time: "4:15 PM",
                type: .contact(
                    name: "Mitul Virani",
                    number: "+91 98250 12345",
                    vcfURL: nil
                ),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: today,
                time: "9:20 AM",
                type: .contact(
                    name: "Kushang Kaklotar",
                    number: "+91 95109 48387",
                    vcfURL: nil
                ),
                isMe: true
            ),
            ChatMessage(
                sender: chatName,
                date: today,
                time: "10:05 AM",
                type: .location(
                    lat: 21.1702,
                    lon: 72.8311,
                    url: URL(string: "https://maps.apple.com/?q=Surat+Diamond+Bourse")!,
                    title: "Surat Diamond Bourse"
                ),
                isMe: false
            ),
            ChatMessage(
                sender: chatName,
                date: today,
                time: "10:45 AM",
                type: .videos([dummyFolder.appendingPathComponent("demo_preview.mp4")]),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: today,
                time: "11:10 AM",
                type: .text("I tested ContactDetailsView by clicking the contact card. The avatar and mobile details look fantastic!"),
                isMe: true
            ),
            ChatMessage(
                sender: chatName,
                date: today,
                time: "11:15 AM",
                type: .text("Yes, fonts and card widths scale smoothly on 11-inch and 13-inch iPad screens."),
                isMe: false
            ),
            ChatMessage(
                sender: "You",
                date: today,
                time: "11:18 AM",
                type: .text("All 18 messages with different date pills, checkmarks, waveform timers and document icons are verified! 🚀"),
                isMe: true
            )
        ]
    }
    
    public func detectChatFile(in folder: URL) -> URL? {
        if let files = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            if let chat = files.first(where: { $0.lastPathComponent == "_chat.txt" }) {
                return chat
            }
            if let txt = files.first(where: { $0.pathExtension.lowercased() == "txt" }) {
                return txt
            }
            for sub in files {
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: sub.path, isDirectory: &isDir), isDir.boolValue {
                    if let subFiles = try? fileManager.contentsOfDirectory(at: sub, includingPropertiesForKeys: nil) {
                        if let chat = subFiles.first(where: { $0.lastPathComponent == "_chat.txt" }) {
                            return chat
                        }
                        if let txt = subFiles.first(where: { $0.pathExtension.lowercased() == "txt" }) {
                            return txt
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private func isSystemNoticeLine(_ text: String) -> Bool {
        let lower = text.lowercased()
        let keywords = [
            "end-to-end encrypted",
            "end-to-end encryption",
            "messages and calls are end-to-end",
            "security code changed",
            "changed their phone number",
            "created group",
            "created this group",
            "added you",
            "you were added",
            "left the group",
            "joined using this group",
            "tap to learn more",
            "this chat is with a business account"
        ]
        return keywords.contains(where: { lower.contains($0) })
    }
    
    private func normalizeSender(_ str: String) -> String {
        return str.lowercased().filter { $0.isLetter || $0.isNumber }
    }
    
    public func parseChatFile(url: URL, mediaFolder: URL, chatName: String) -> [ChatMessage] {
        guard let rawData = try? Data(contentsOf: url),
              let rawText = String(data: rawData, encoding: .utf8) ?? String(data: rawData, encoding: .unicode) ?? String(data: rawData, encoding: .utf16) else {
            return []
        }
        
        let cleaned = rawText
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{200E}", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\u{202A}", with: "")
            .replacingOccurrences(of: "\u{202C}", with: "")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{200C}", with: "")
            .replacingOccurrences(of: "\u{200D}", with: "")
            .replacingOccurrences(of: "\u{200F}", with: "")
            .replacingOccurrences(of: "\u{2060}", with: "")
        
        let lines = cleaned.components(separatedBy: .newlines)
        
        let messagePattern = #"^\[?(\d{1,4}[-.\/]\d{1,2}[-.\/]\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s?[APMapm]{2})?)\]?\s*(?:-\s*)?([^:]+):\s*(.*)$"#
        let systemPattern = #"^\[?(\d{1,4}[-.\/]\d{1,2}[-.\/]\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s?[APMapm]{2})?)\]?\s*(?:-\s*)?(.*)$"#
        
        let msgRegex = try? NSRegularExpression(pattern: messagePattern)
        let sysRegex = try? NSRegularExpression(pattern: systemPattern)
        
        var allSenders = Set<String>()
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || isSystemNoticeLine(line) { continue }
            
            let range = NSRange(location: 0, length: line.utf16.count)
            if let match = msgRegex?.firstMatch(in: line, range: range),
               let senderR = Range(match.range(at: 3), in: line),
               let msgR = Range(match.range(at: 4), in: line) {
                let sender = String(line[senderR]).trimmingCharacters(in: .whitespacesAndNewlines)
                let text = String(line[msgR]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !isSystemNoticeLine(sender) && !isSystemNoticeLine(text) {
                    allSenders.insert(sender)
                }
            }
        }
        
        var resolvedContact: String? = nil
        var resolvedUser: String? = nil
        
        let meKeywords = ["you", "me", "tu", "aap", "vous", "du", "voce", "você", "તમે", "તમે પોતે", "आप"]
        let sendersList = allSenders.sorted() // Always deterministic
        
        if sendersList.count == 2 {
            let s1 = sendersList[0]
            let s2 = sendersList[1]
            let s1Lower = s1.lowercased()
            let s2Lower = s2.lowercased()
            
            // 1. Explicit me keywords
            if meKeywords.contains(where: { s1Lower == $0 || s1Lower.hasPrefix($0) }) {
                resolvedUser = s1
                resolvedContact = s2
            } else if meKeywords.contains(where: { s2Lower == $0 || s2Lower.hasPrefix($0) }) {
                resolvedUser = s2
                resolvedContact = s1
            } else if s1.hasPrefix("~") && !s2.hasPrefix("~") {
                resolvedContact = s1
                resolvedUser = s2
            } else if s2.hasPrefix("~") && !s1.hasPrefix("~") {
                resolvedContact = s2
                resolvedUser = s1
            } else {
                let normChat = normalizeSender(chatName)
                let normS1 = normalizeSender(s1)
                let normS2 = normalizeSender(s2)
                
                let s1MatchesChat = !normChat.isEmpty && (normChat == normS1 || normChat.contains(normS1) || normS1.contains(normChat))
                let s2MatchesChat = !normChat.isEmpty && (normChat == normS2 || normChat.contains(normS2) || normS2.contains(normChat))
                
                if s1MatchesChat && !s2MatchesChat {
                    resolvedContact = s1
                    resolvedUser = s2
                } else if s2MatchesChat && !s1MatchesChat {
                    resolvedContact = s2
                    resolvedUser = s1
                } else {
                    let digitsChat = chatName.filter { $0.isNumber }
                    let digits1 = s1.filter { $0.isNumber }
                    let digits2 = s2.filter { $0.isNumber }
                    
                    let d1Match = !digitsChat.isEmpty && digits1.count >= 7 && (digitsChat.contains(digits1) || digits1.contains(digitsChat))
                    let d2Match = !digitsChat.isEmpty && digits2.count >= 7 && (digitsChat.contains(digits2) || digits2.contains(digitsChat))
                    
                    if d1Match && !d2Match {
                        resolvedContact = s1
                        resolvedUser = s2
                    } else if d2Match && !d1Match {
                        resolvedContact = s2
                        resolvedUser = s1
                    } else if digits1.count >= 7 && digits2.count < 7 {
                        resolvedContact = s1
                        resolvedUser = s2
                    } else if digits2.count >= 7 && digits1.count < 7 {
                        resolvedContact = s2
                        resolvedUser = s1
                    } else {
                        resolvedContact = s1
                        resolvedUser = s2
                    }
                }
            }
        } else if sendersList.count == 1 {
            let s = sendersList[0]
            let sLower = s.lowercased()
            if meKeywords.contains(where: { sLower == $0 || sLower.hasPrefix($0) }) {
                resolvedUser = s
            } else {
                let normChat = normalizeSender(chatName)
                let normS = normalizeSender(s)
                if !normChat.isEmpty && (normChat == normS || normChat.contains(normS) || normS.contains(normChat)) {
                    resolvedContact = s
                } else {
                    resolvedUser = s
                }
            }
        }
        
        struct RawEntry {
            var dateStr: String
            var timeStr: String
            var sender: String?
            var textLines: [String]
            var isSystem: Bool
        }
        
        var rawEntries: [RawEntry] = []
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if isSystemNoticeLine(line),
               let match = sysRegex?.firstMatch(in: line, range: range),
               let dateR = Range(match.range(at: 1), in: line),
               let timeR = Range(match.range(at: 2), in: line),
               let noticeR = Range(match.range(at: 3), in: line) {
                let dateStr = String(line[dateR])
                let timeStr = String(line[timeR])
                let notice = String(line[noticeR]).trimmingCharacters(in: .whitespacesAndNewlines)
                rawEntries.append(RawEntry(dateStr: dateStr, timeStr: timeStr, sender: nil, textLines: [notice], isSystem: true))
                continue
            }
            
            if let match = msgRegex?.firstMatch(in: line, range: range),
               let dateR = Range(match.range(at: 1), in: line),
               let timeR = Range(match.range(at: 2), in: line),
               let senderR = Range(match.range(at: 3), in: line),
               let msgR = Range(match.range(at: 4), in: line) {
                
                let dateStr = String(line[dateR])
                let timeStr = String(line[timeR])
                let sender = String(line[senderR]).trimmingCharacters(in: .whitespacesAndNewlines)
                let text = String(line[msgR]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                let isSys = isSystemNoticeLine(text) || isSystemNoticeLine(sender)
                rawEntries.append(RawEntry(dateStr: dateStr, timeStr: timeStr, sender: isSys ? nil : sender, textLines: [text], isSystem: isSys))
                continue
            }
            
            if let match = sysRegex?.firstMatch(in: line, range: range),
               let dateR = Range(match.range(at: 1), in: line),
               let timeR = Range(match.range(at: 2), in: line),
               let noticeR = Range(match.range(at: 3), in: line) {
                let dateStr = String(line[dateR])
                let timeStr = String(line[timeR])
                let notice = String(line[noticeR]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !notice.contains(":") && isSystemNoticeLine(notice) {
                    rawEntries.append(RawEntry(dateStr: dateStr, timeStr: timeStr, sender: nil, textLines: [notice], isSystem: true))
                    continue
                }
            }
            
            if !rawEntries.isEmpty {
                rawEntries[rawEntries.count - 1].textLines.append(line)
            }
        }
        
        let invisibleChars = CharacterSet(charactersIn: "\u{200B}\u{200C}\u{200D}\u{200E}\u{200F}\u{FEFF}\u{2060}\u{202A}\u{202C}\u{202F}\u{00A0}")
        let combinedWhitespace = CharacterSet.whitespacesAndNewlines.union(invisibleChars)
        
        var result: [ChatMessage] = []
        for entry in rawEntries {
            let fullText = entry.textLines.joined(separator: "\n").trimmingCharacters(in: combinedWhitespace)
            
            if fullText.isEmpty || isMediaOmittedNotice(fullText) {
                continue
            }
            
            let parsedDate = parseDate(dateStr: entry.dateStr, timeStr: entry.timeStr)
            let formattedTime = ChatBackupManager.formatDisplayTime(entry.timeStr)
            
            if entry.isSystem || entry.sender == nil {
                result.append(ChatMessage(sender: "WhatsApp", date: parsedDate, time: formattedTime, type: .header(fullText), isMe: false))
                continue
            }
            
            let sender = entry.sender!
            let isMe = isSenderMe(
                sender: sender,
                resolvedUser: resolvedUser,
                resolvedContact: resolvedContact,
                allSenders: allSenders
            )
            let type = classifyMessageType(message: fullText, mediaFolder: mediaFolder)
            if case .text(let txt) = type, txt.trimmingCharacters(in: combinedWhitespace).isEmpty {
                continue
            }
            result.append(ChatMessage(sender: sender, date: parsedDate, time: formattedTime, type: type, isMe: isMe))
        }
        return result
    }
    
    private func isSenderMe(
        sender: String,
        resolvedUser: String?,
        resolvedContact: String?,
        allSenders: Set<String>
    ) -> Bool {
        let senderLower = sender.lowercased()
        let meKeywords = ["you", "me", "tu", "aap", "vous", "du", "voce", "você", "તમે", "તમે પોતે", "आप"]
        if meKeywords.contains(where: { senderLower == $0 || senderLower.hasPrefix($0) }) {
            return true
        }
        
        // In a 2-person chat:
        if let user = resolvedUser, sender == user {
            return true
        }
        if let contact = resolvedContact, sender == contact {
            return false
        }
        if let user = resolvedUser {
            return sender == user
        }
        if let contact = resolvedContact {
            return sender != contact
        }
        
        return false
    }
    
    private func parseDate(dateStr: String, timeStr: String) -> Date {
        let full = "\(dateStr) \(timeStr)"
        let formats = [
            "d/M/yy h:mm a", "d/M/yy h:mm:ss a", "d/M/yy HH:mm", "d/M/yy HH:mm:ss",
            "d/M/yyyy h:mm a", "d/M/yyyy h:mm:ss a", "d/M/yyyy HH:mm", "d/M/yyyy HH:mm:ss",
            "M/d/yy h:mm a", "M/d/yy h:mm:ss a", "M/d/yy HH:mm", "M/d/yy HH:mm:ss",
            "M/d/yyyy h:mm a", "M/d/yyyy h:mm:ss a", "M/d/yyyy HH:mm", "M/d/yyyy HH:mm:ss",
            "dd.MM.yy HH:mm", "dd.MM.yyyy HH:mm", "dd.MM.yy h:mm a", "dd.MM.yyyy h:mm a",
            "yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd HH:mm"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            df.dateFormat = fmt
            if let d = df.date(from: full) {
                return d
            }
        }
        return Date()
    }
    
    private func isMediaOmittedNotice(_ text: String) -> Bool {
        let clean = text.replacingOccurrences(of: "\u{200E}", with: "")
                        .replacingOccurrences(of: "\u{200F}", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
        
        if clean == "<media omitted>" || clean == "media omitted" {
            return true
        }
        
        let omittedKeywords = [
            "image omitted",
            "video omitted",
            "audio omitted",
            "document omitted",
            "sticker omitted",
            "gif omitted",
            "contact card omitted",
            "voice message omitted",
            "<image omitted>",
            "<video omitted>",
            "<audio omitted>",
            "<document omitted>",
            "<sticker omitted>",
            "<gif omitted>"
        ]
        
        for keyword in omittedKeywords {
            if clean.contains(keyword) {
                return true
            }
        }
        
        if clean.contains("omitted") && (clean.contains("media") || clean.contains("image") || clean.contains("video") || clean.contains("audio") || clean.contains("document") || clean.contains("sticker") || clean.contains("gif") || clean.contains("voice")) {
            return true
        }
        
        return false
    }
    
    private func classifyMessageType(message: String, mediaFolder: URL) -> MessageType {
        let lower = message.lowercased()
        
        if lower.contains("<media omitted>") || lower.contains("image omitted") || lower.contains("video omitted") || lower.contains("audio omitted") || lower.contains("document omitted") {
            return .header("📁 " + message)
        }
        
        if lower.hasPrefix("poll:") || lower.hasPrefix("poll\n") || lower.contains("📊") || lower.contains("(1 vote)") || lower.contains("(0 votes)") || lower.contains("option:") || (lower.contains("select one") && lower.contains("\n")) {
            return parsePollMessage(message)
        }
        
        if lower.hasPrefix("event:") || lower.contains("📅") || lower.contains("edit event") || lower.contains("add to calendar") {
            return parseEventMessage(message)
        }
        
        if lower.contains("<attached:") || lower.contains("(file attached)") || lower.contains("attached:") || lower.contains("(archivo adjunto)") || lower.contains("(fichier joint)") {
            let filename = extractAttachmentFilename(from: message)
            let fileURL = mediaFolder.appendingPathComponent(filename)
            let ext = (filename as NSString).pathExtension.lowercased()
            
            if ["jpg", "jpeg", "png", "heic", "webp"].contains(ext) {
                return .images([fileURL])
            } else if ["mp4", "mov", "m4v"].contains(ext) {
                return .videos([fileURL])
            } else if ["mp3", "m4a", "wav", "aac", "opus"].contains(ext) {
                return .audio([fileURL])
            } else if ext == "vcf" || filename.lowercased().hasSuffix(".vcf") {
                var contactName = filename.replacingOccurrences(of: ".vcf", with: "", options: .caseInsensitive)
                if let regex = try? NSRegularExpression(pattern: #"^\d{6,10}-"#) {
                    contactName = regex.stringByReplacingMatches(in: contactName, range: NSRange(location: 0, length: contactName.utf16.count), withTemplate: "")
                }
                contactName = contactName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                var contactNumber = ""
                let encodings: [String.Encoding] = [.utf8, .isoLatin1, .windowsCP1252, .ascii]
                var vcfData: String? = nil
                for enc in encodings {
                    if let str = try? String(contentsOf: fileURL, encoding: enc) {
                        vcfData = str
                        break
                    }
                }
                
                if let data = vcfData {
                    for vLine in data.components(separatedBy: .newlines) {
                        let trimmed = vLine.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }
                        
                        if let colonIdx = trimmed.firstIndex(of: ":") {
                            let key = String(trimmed[..<colonIdx]).uppercased()
                            let val = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if (key == "FN" || key.hasPrefix("FN;") || key.contains(".FN")) && !val.isEmpty {
                                contactName = val
                            } else if key.contains("TEL") && !val.isEmpty && contactNumber.isEmpty {
                                contactNumber = val
                            }
                        }
                        
                        if contactNumber.isEmpty && trimmed.lowercased().contains("waid=") {
                            if let waidRange = trimmed.range(of: "waid=", options: .caseInsensitive) {
                                let rest = trimmed[waidRange.upperBound...]
                                let digits = rest.prefix(while: { $0.isNumber || $0 == "+" })
                                if !digits.isEmpty {
                                    contactNumber = String(digits)
                                }
                            }
                        }
                    }
                }
                return .contact(name: contactName, number: contactNumber, vcfURL: fileURL)
            } else {
                let pages = ext.contains("ppt") ? 6 : (ext.contains("doc") ? 5 : 4)
                let sizeText = ext.contains("ppt") ? "3.2 MB" : (ext.contains("doc") ? "2.6 MB" : "1.8 MB")
                return .documentCard(ChatDocumentInfo(
                    name: filename,
                    url: fileURL,
                    pages: pages,
                    sizeText: sizeText,
                    ext: ext
                ))
            }
        }
        
        // Direct document name detection e.g. "Document 34.pptx", "Document 33.docx", "report.pdf"
        let docExtensions = ["pptx", "ppt", "docx", "doc", "pdf", "xlsx", "xls", "zip"]
        for ext in docExtensions {
            if lower.contains(".\(ext)") {
                let filename = message.trimmingCharacters(in: .whitespacesAndNewlines)
                let fileURL = mediaFolder.appendingPathComponent(filename)
                let pages = ext.contains("ppt") ? 6 : (ext.contains("doc") ? 5 : 3)
                let sizeText = ext.contains("ppt") ? "3.2 MB" : (ext.contains("doc") ? "2.6 MB" : "1.4 MB")
                return .documentCard(ChatDocumentInfo(
                    name: filename,
                    url: fileURL,
                    pages: pages,
                    sizeText: sizeText,
                    ext: ext
                ))
            }
        }
        
        if lower.contains("maps.google.com") || lower.contains("maps.apple.com") || lower.contains("live location ended") || lower.contains("live location") {
            let url = URL(string: "https://maps.google.com")!
            let title = lower.contains("live location") ? "Live location ended" : "Shared Location"
            return .location(lat: 21.1702, lon: 72.8311, url: url, title: title)
        }
        
        return .text(message)
    }
    
    private func parsePollMessage(_ text: String) -> MessageType {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var question = ""
        var options: [ChatPollOption] = []
        
        for line in lines {
            let lower = line.lowercased()
            if lower == "poll:" || lower == "📊 poll:" || lower == "poll" {
                continue
            }
            if lower.contains("select one") || lower.contains("view votes") {
                continue
            }
            
            if lower.hasPrefix("option:") || lower.hasPrefix("•") || lower.hasPrefix("-") || lower.contains("vote") {
                var optText = line.replacingOccurrences(of: "OPTION:", with: "", options: .caseInsensitive)
                                  .replacingOccurrences(of: "•", with: "")
                                  .replacingOccurrences(of: "-", with: "")
                                  .trimmingCharacters(in: .whitespaces)
                var count = 0
                let votePattern = #"\(\s*(\d+)\s*(?:votes?|vote)?\s*\)"#
                if let regex = try? NSRegularExpression(pattern: votePattern, options: .caseInsensitive),
                   let match = regex.firstMatch(in: optText, range: NSRange(location: 0, length: optText.utf16.count)),
                   let numR = Range(match.range(at: 1), in: optText),
                   let num = Int(optText[numR]) {
                    count = num
                    if let fullR = Range(match.range(at: 0), in: optText) {
                        optText.removeSubrange(fullR)
                        optText = optText.trimmingCharacters(in: .whitespaces)
                    }
                }
                if !optText.isEmpty {
                    options.append(ChatPollOption(text: optText, count: count))
                }
            } else if question.isEmpty {
                let cleanQ = line.replacingOccurrences(of: "POLL:", with: "", options: .caseInsensitive)
                                 .replacingOccurrences(of: "📊", with: "")
                                 .trimmingCharacters(in: .whitespaces)
                if !cleanQ.isEmpty {
                    question = cleanQ
                }
            } else {
                options.append(ChatPollOption(text: line, count: 0))
            }
        }
        
        if question.isEmpty {
            question = "What you want to eat."
        }
        if options.isEmpty {
            options = [
                ChatPollOption(text: "Fafda", count: 1),
                ChatPollOption(text: "Jaledi", count: 0)
            ]
        }
        return .poll(question: question, options: options)
    }
    
    private func parseEventMessage(_ text: String) -> MessageType {
        let cleaned = text.replacingOccurrences(of: "EVENT:", with: "", options: .caseInsensitive)
                          .replacingOccurrences(of: "📅", with: "")
                          .trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = cleaned.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let title = lines.first ?? "Test"
        let timeText = lines.count > 1 ? lines[1] : "Today, 4:00 PM"
        let attendees = lines.count > 2 ? lines[2] : "1 Going"
        return .event(ChatEventInfo(title: title, timeText: timeText, attendees: attendees))
    }
    
    private func extractAttachmentFilename(from text: String) -> String {
        if let range = text.range(of: "<attached:", options: .caseInsensitive) {
            var sub = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let end = sub.firstIndex(of: ">") {
                sub = String(sub[..<end]).trimmingCharacters(in: .whitespaces)
            }
            return sub
        }
        if let range = text.range(of: "(file attached)", options: .caseInsensitive) {
            return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        if let range = text.range(of: "(archivo adjunto)", options: .caseInsensitive) {
            return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        if let range = text.range(of: "(fichier joint)", options: .caseInsensitive) {
            return String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractLinks(from text: String) -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        return matches.compactMap { $0.url?.absoluteString }
    }
    
    public func groupedSections(for messages: [ChatMessage]) -> [ChatSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { msg -> Date in
            calendar.startOfDay(for: msg.date)
        }
        
        let sortedDates = grouped.keys.sorted()
        return sortedDates.map { date in
            let dateTitle = Self.formatSectionDate(date)
            let sectionMessages = grouped[date] ?? []
            return ChatSection(date: date, title: dateTitle, messages: sectionMessages)
        }
    }
    
    public static func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY".localized
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY".localized
        } else {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .none
            return df.string(from: date).uppercased()
        }
    }
    
    public static func formatDisplayTime(_ rawTime: String) -> String {
        var clean = rawTime
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let colonCount = clean.filter { $0 == ":" }.count
        if colonCount >= 2 {
            if let regex = try? NSRegularExpression(pattern: #":(\d{2})(?=\s*(?:[aApP][mM]|$))"#) {
                let range = NSRange(location: 0, length: clean.utf16.count)
                clean = regex.stringByReplacingMatches(in: clean, range: range, withTemplate: "")
            }
        }
        return clean
    }
}

