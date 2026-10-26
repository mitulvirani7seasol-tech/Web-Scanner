//
//  ChatConversationView.swift
//  WebScanner
//
//

import SwiftUI
import QuickLook
import AVKit
import AVFoundation
import Combine

// MARK: - Authentic WhatsApp Bubble Shape
struct WhatsAppBubbleShape: Shape {
    let isMe: Bool
    var cornerRadius: CGFloat = 14
    var tailRadius: CGFloat = 3
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = cornerRadius
        let tr = cornerRadius
        let bl = isMe ? cornerRadius : tailRadius
        let br = isMe ? tailRadius : cornerRadius
        
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        return path
    }
}

// MARK: - Bottom Anchor Preference Key
private struct BottomAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Anchor Helper
fileprivate extension View {
    @ViewBuilder
    func scrollAnchorIfAvailable(_ anchor: UnitPoint?) -> some View {
        if #available(iOS 17.0, *) {
            self.defaultScrollAnchor(anchor)
        } else {
            self
        }
    }
}

// MARK: - Chat Audio Player Manager
final class ChatAudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var playingURL: URL? = nil
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var progress: Double = 0.0
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var durationCache: [URL: Double] = [:]
    
    override init() {
        super.init()
    }
    
    func getDuration(for url: URL) -> Double {
        if let cached = durationCache[url], cached > 0 {
            return cached
        }
        if playingURL == url && duration > 0 {
            return duration
        }
        let asset = AVURLAsset(url: url)
        let cmDuration = asset.duration
        let sec = CMTimeGetSeconds(cmDuration)
        if !sec.isNaN && sec > 0 {
            durationCache[url] = sec
            return sec
        }
        if let p = try? AVAudioPlayer(contentsOf: url) {
            durationCache[url] = p.duration
            return p.duration
        }
        return 0.0
    }
    
    func toggle(url: URL) {
        if playingURL == url {
            if isPlaying {
                pause()
            } else {
                resume()
            }
        } else {
            play(url: url)
        }
    }
    
    func play(url: URL) {
        stop()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.prepareToPlay()
            
            self.player = p
            self.playingURL = url
            self.duration = max(0.1, p.duration)
            self.durationCache[url] = self.duration
            self.currentTime = 0.0
            self.progress = 0.0
            
            if p.play() {
                self.isPlaying = true
                startTimer()
            }
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func resume() {
        guard let p = player else { return }
        if p.play() {
            isPlaying = true
            startTimer()
        }
    }
    
    func stop() {
        stopTimer()
        player?.stop()
        player = nil
        isPlaying = false
        playingURL = nil
        currentTime = 0.0
        progress = 0.0
        duration = 0.0
    }
    
    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let p = self.player else { return }
            if p.isPlaying {
                self.currentTime = p.currentTime
                self.progress = self.duration > 0 ? min(1.0, p.currentTime / self.duration) : 0.0
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stopTimer()
            self.isPlaying = false
            self.currentTime = 0.0
            self.progress = 0.0
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.stop()
        }
    }
    
    deinit {
        stop()
    }
}

// MARK: - Contact Card Info
public struct ContactCardInfo: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let number: String
    public let vcfURL: URL?
    
    public init(name: String, number: String, vcfURL: URL? = nil) {
        self.name = name
        self.number = number
        self.vcfURL = vcfURL
    }
}

public struct ChatConversationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    public let conversation: ChatConversation
    
    @State private var messages: [ChatMessage] = []
    @State private var isScrollableContent: Bool = false
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var previewItemURL: URL?
    @StateObject private var audioManager = ChatAudioPlayerManager()
    @State private var navigateToContact: ContactCardInfo? = nil
    @State private var showScrollToBottomButton: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(conversation: ChatConversation) {
        self.conversation = conversation
        if let fileURL = conversation.fileURL {
            let loaded = ChatBackupManager.shared.parseChatFile(
                url: fileURL,
                mediaFolder: conversation.folderURL,
                chatName: conversation.name
            )
            _messages = State(initialValue: loaded)
            let sections = ChatBackupManager.shared.groupedSections(for: loaded)
            _isScrollableContent = State(initialValue: Self.estimateIsScrollable(messages: loaded, sectionCount: sections.count))
        } else if ChatBackupManager.isDummyDataEnabled {
            let loaded = ChatBackupManager.generateDummyMessages(for: conversation.name)
            _messages = State(initialValue: loaded)
            let sections = ChatBackupManager.shared.groupedSections(for: loaded)
            _isScrollableContent = State(initialValue: Self.estimateIsScrollable(messages: loaded, sectionCount: sections.count))
        } else {
            _messages = State(initialValue: [])
            _isScrollableContent = State(initialValue: false)
        }
    }
    
    private static func estimateIsScrollable(messages: [ChatMessage], sectionCount: Int) -> Bool {
        if messages.isEmpty { return false }
        
        // Base overhead: Encryption banner (~85pt) + bottom spacing (75pt) + top/bottom padding (30pt)
        var estimatedHeight: CGFloat = 190
        estimatedHeight += CGFloat(sectionCount) * 40 // date pills
        
        for msg in messages {
            switch msg.type {
            case .text(let txt):
                let lines = max(1, CGFloat(txt.count) / 30.0)
                estimatedHeight += max(45, lines * 20 + 26) + 10
            case .images, .videos:
                estimatedHeight += 220 + 10
            case .audio:
                estimatedHeight += 78 + 10
            case .contact, .documentCard, .poll, .event:
                estimatedHeight += 140 + 10
            case .header:
                estimatedHeight += 38 + 10
            default:
                estimatedHeight += 55 + 10
            }
        }
        
        let screenH = UIScreen.main.bounds.height
        let viewportH = (screenH > 0 ? screenH : 844) - 150
        return estimatedHeight > viewportH
    }
    
    // WhatsApp Colors
    private var whatsappBackground: Color {
        colorScheme == .dark ? Color(hex: "#0B141A") : Color(hex: "#EFEAE2")
    }
    
    private var whatsappHeaderBg: Color {
        colorScheme == .dark ? Color(hex: "#202C33") : Color(hex: "#F0F2F5")
    }
    
    private var outgoingBubbleColor: Color {
        colorScheme == .dark ? Color(hex: "#005C4B") : Color(hex: "#D9FDD3")
    }
    
    private var incomingBubbleColor: Color {
        colorScheme == .dark ? Color(hex: "#1F2C34") : Color(hex: "#FFFFFF")
    }
    
    private var messageTextColor: Color {
        colorScheme == .dark ? Color(hex: "#E9EDEF") : Color(hex: "#111B21")
    }
    
    private var timestampColor: Color {
        colorScheme == .dark ? Color(hex: "#8696A0") : Color(hex: "#667781")
    }
    
    private var whatsappCheckmarkBlue: Color {
        Color(hex: "#53BDEB")
    }
    
    private var filteredMessages: [ChatMessage] {
        let base: [ChatMessage]
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            base = messages
        } else {
            base = messages.filter { msg in
                switch msg.type {
                case .text(let txt):
                    return txt.localizedCaseInsensitiveContains(searchText)
                case .contact(let name, let num, _):
                    return name.localizedCaseInsensitiveContains(searchText) || num.localizedCaseInsensitiveContains(searchText)
                case .documentCard(let doc):
                    return doc.name.localizedCaseInsensitiveContains(searchText)
                case .poll(let q, _):
                    return q.localizedCaseInsensitiveContains(searchText)
                case .event(let ev):
                    return ev.title.localizedCaseInsensitiveContains(searchText)
                default:
                    return false
                }
            }
        }
        // Exclude duplicate encryption notices since it is pinned in the official WhatsApp banner at top
        return base.filter { msg in
            if case .header(let txt) = msg.type, txt.lowercased().contains("end-to-end") {
                return false
            }
            return true
        }
    }
    
    private var groupedSections: [ChatSection] {
        ChatBackupManager.shared.groupedSections(for: filteredMessages)
    }
    
    private var contactAvatarImage: UIImage? {
        let fileManager = FileManager.default
        let possibleNames = ["avatar.jpg", "avatar.png", "profile.jpg", "profile.png", "photo.jpg"]
        for name in possibleNames {
            let fileURL = conversation.folderURL.appendingPathComponent(name)
            if fileManager.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let img = UIImage(data: data) {
                return img
            }
        }
        return nil
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // 1. Screen Main Background (Assets: BG and BG_Dark)
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // WhatsApp Header matching Images
                    whatsappHeader
                    
                    // Chat Messages Container with Chat BG
                    ZStack {
                        // Authentic WhatsApp Pattern Background (Assets: Chat BG / Chat_BG and Chat_BG_Dark)
                        Image(colorScheme == .dark ? "Chat_BG_Dark" : "Chat_BG")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .ignoresSafeArea(edges: .bottom)
                        
                        // Messages list grouped by date
                        if messages.isEmpty {
                            emptyChatView
                        } else {
                            GeometryReader { containerGeo in
                                ScrollViewReader { proxy in
                                    ZStack(alignment: .bottomTrailing) {
                                        ScrollView(.vertical, showsIndicators: true) {
                                            VStack(spacing: 10.scaled) {
                                                // WhatsApp End-to-End Encryption Banner (Image 4)
                                                encryptionNoticeBanner
                                                    .padding(.top, 10.scaled)
                                                    .padding(.bottom, 4.scaled)
                                                
                                                ForEach(groupedSections) { section in
                                                    // WhatsApp Sticky Date Pill
                                                    datePill(for: section.title)
                                                        .padding(.vertical, 6)
                                                    
                                                    ForEach(section.messages) { msg in
                                                        if case .header(let title) = msg.type {
                                                            systemMessagePill(title)
                                                                .id(msg.id)
                                                        } else {
                                                            messageBubble(for: msg)
                                                                .id(msg.id)
                                                        }
                                                    }
                                                }
                                                
                                                // Dedicated bottom space so the last message is NEVER hidden or cut off
                                                Color.clear
                                                    .frame(height: 75.scaled)
                                                    .id("BOTTOM_SCROLL_ANCHOR")
                                                    .background(
                                                        GeometryReader { anchorGeo in
                                                            Color.clear.preference(
                                                                key: BottomAnchorPreferenceKey.self,
                                                                value: anchorGeo.frame(in: .named("CHAT_SCROLL_COORDINATE_SPACE")).maxY
                                                            )
                                                        }
                                                    )
                                            }
                                            .padding(.horizontal, isIPad ? 32 : 12.scaled)
                                            .padding(.top, 6)
                                            .frame(maxWidth: .infinity)
                                        }
                                        .scrollAnchorIfAvailable(isScrollableContent ? .bottom : .top)
                                        .coordinateSpace(name: "CHAT_SCROLL_COORDINATE_SPACE")
                                        .onPreferenceChange(BottomAnchorPreferenceKey.self) { anchorMaxY in
                                            let isFarFromBottom = isScrollableContent && (anchorMaxY > (containerGeo.size.height + 120))
                                            if showScrollToBottomButton != isFarFromBottom {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showScrollToBottomButton = isFarFromBottom
                                                }
                                            }
                                        }
                                        
                                        // Floating Scroll-to-Bottom Button - visible only when scrolled away from bottom
                                        if showScrollToBottomButton {
                                            Button(action: {
                                                HapticFeedback.generate(.light)
                                                scrollToBottom(proxy: proxy, animated: true)
                                            }) {
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(timestampColor)
                                                    .frame(width: 36.scaled, height: 36.scaled)
                                                    .background(
                                                        Circle()
                                                            .fill(colorScheme == .dark ? Color(hex: "#202C33") : Color.white)
                                                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                                    )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.trailing, 16.scaled)
                                            .padding(.bottom, 16.scaled)
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .onAppear {
                                        if #unavailable(iOS 17.0) {
                                            if isScrollableContent {
                                                DispatchQueue.main.async {
                                                    proxy.scrollTo("BOTTOM_SCROLL_ANCHOR", anchor: .bottom)
                                                }
                                            }
                                        }
                                    }
                                    .onChange(of: messages.count) { _ in
                                        if isScrollableContent {
                                            DispatchQueue.main.async {
                                                proxy.scrollTo("BOTTOM_SCROLL_ANCHOR", anchor: .bottom)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .navigationDestination(isPresented: Binding(
            get: { navigateToContact != nil },
            set: { if !$0 { navigateToContact = nil } }
        )) {
            if let contact = navigateToContact {
                ContactDetailsView(contact: contact)
            }
        }
        .onAppear {
            TabBarManager.shared.isHidden = true
            loadMessages()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenContactDetailsNotification"))) { _ in
            let num = conversation.name.contains("+") ? conversation.name : "+91 98765 43210"
            navigateToContact = ContactCardInfo(name: conversation.name, number: num)
        }
        .onChange(of: conversation.id) { _ in
            loadMessages()
        }
        .onDisappear {
            audioManager.stop()
        }
        .quickLookPreview($previewItemURL)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareItems)
        }
    }
    
    // MARK: - WhatsApp Navigation Header (Clean Chevron & Contact info)
    private var whatsappHeader: some View {
        HStack(spacing: 8.scaled) {
            // Clean Back Chevron Button (matching Images)
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Contact Avatar & Name Button (Tap to open ContactDetailsView)
            Button(action: {
                HapticFeedback.generate(.light)
                let num = conversation.name.contains("+") ? conversation.name : "+91 98765 43210"
                navigateToContact = ContactCardInfo(name: conversation.name, number: num)
            }) {
                HStack(spacing: 10.scaled) {
                    // Avatar Circle
                    ZStack {
                        Circle()
                            .fill(Color(hex: colorScheme == .dark ? "#2A3942" : "#DFE5E7"))
                            .frame(width: isIPad ? 42 : 36.scaled, height: isIPad ? 42 : 36.scaled)
                        
                        if let avatarImg = contactAvatarImage {
                            Image(uiImage: avatarImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: isIPad ? 42 : 36.scaled, height: isIPad ? 42 : 36.scaled)
                                .clipShape(Circle())
                        } else if let firstChar = conversation.name.first, firstChar.isLetter {
                            Text(String(firstChar).uppercased())
                                .font(.system(size: isIPad ? 18 : 15, weight: .bold))
                                .foregroundColor(AppColors.primaryGreen)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: isIPad ? 20 : 16))
                                .foregroundColor(Color(hex: "#8696A0"))
                        }
                    }
                    
                    // Contact Name
                    Text(conversation.name)
                        .font(.system(size: isIPad ? 17 : 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineLimit(1)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal, isIPad ? 24 : 12.scaled)
        .padding(.top, isIPad ? 10 : 6.scaled)
        .padding(.bottom, isIPad ? 10 : 8.scaled)
        .background(Color.clear)
    }
    
    
    // MARK: - WhatsApp Encryption Banner (Image 4)
    private var encryptionNoticeBanner: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: colorScheme == .dark ? "#E9EDEF" : "#54656F"))
                .padding(.top, 2)
            
            Text("Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them.".localized)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundColor(Color(hex: colorScheme == .dark ? "#E9EDEF" : "#54656F"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: colorScheme == .dark ? "#182229" : "#FCF4CB"))
                .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        )
        .padding(.horizontal, 28)
    }
    
    // MARK: - Date Pill Badge
    private func datePill(for title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(timestampColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(hex: colorScheme == .dark ? "#182229" : "#FFFFFF").opacity(0.92))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 2, y: 1)
            )
    }
    
    // MARK: - System Notice Pill
    private func systemMessagePill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11.5, weight: .regular))
            .italic()
            .foregroundColor(timestampColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(hex: colorScheme == .dark ? "#182229" : "#FFFFFF").opacity(0.75))
            )
            .padding(.horizontal, 32)
            .padding(.vertical, 2)
    }
    
    // MARK: - Message Bubble
    private func messageBubble(for msg: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 6.scaled) {
            if msg.isMe {
                Spacer(minLength: isIPad ? 100 : 45.scaled)
                
                // Forward button next to outgoing documents/cards (Image 3)
                if case .documentCard(let doc) = msg.type {
                    forwardButton(for: doc.url)
                }
            }
            
            VStack(alignment: msg.isMe ? .trailing : .leading, spacing: 3.scaled) {
                // Sender name if incoming in group
                if !msg.isMe && conversation.messageCount > 1 {
                    Text(msg.sender)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Color(hex: "#00A884"))
                        .padding(.top, 1)
                }
                
                // Bubble Body Content
                bubbleContent(for: msg)
                
                // Timestamp & WhatsApp Double Checkmark
                HStack(spacing: 3) {
                    Text(msg.formattedTime)
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundColor(timestampColor)
                    
                    if msg.isMe {
                        // WhatsApp Read Receipts (Double Blue Checkmark)
                        HStack(spacing: -5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(whatsappCheckmarkBlue)
                    }
                }
                .padding(.top, 1)
            }
            .padding(.horizontal, 10.scaled)
            .padding(.vertical, 6.scaled)
            .background(
                WhatsAppBubbleShape(isMe: msg.isMe)
                    .fill(msg.isMe ? outgoingBubbleColor : incomingBubbleColor)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: 2, x: 0, y: 1)
            )
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = msg.previewText
                    HapticFeedback.generate(.success)
                }) {
                    Label("Copy Text", systemImage: "doc.on.doc")
                }
                
                Button(action: {
                    shareItems = [msg.previewText]
                    showShareSheet = true
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            
            if !msg.isMe {
                // Forward button next to incoming documents/cards
                if case .documentCard(let doc) = msg.type {
                    forwardButton(for: doc.url)
                }
                
                Spacer(minLength: isIPad ? 100 : 45.scaled)
            }
        }
        .frame(maxWidth: .infinity, alignment: msg.isMe ? .trailing : .leading)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = false) {
        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("BOTTOM_SCROLL_ANCHOR", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("BOTTOM_SCROLL_ANCHOR", anchor: .bottom)
        }
    }
    
    // MARK: - Forward Button (Image 3)
    private func forwardButton(for url: URL?) -> some View {
        Button(action: {
            if let u = url {
                shareItems = [u]
                showShareSheet = true
            }
        }) {
            Image(systemName: "arrowshape.turn.up.right.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(timestampColor)
                .frame(width: 30.scaled, height: 30.scaled)
                .background(
                    Circle()
                        .fill(Color(hex: colorScheme == .dark ? "#202C33" : "#E2E8EB"))
                        .shadow(color: Color.black.opacity(0.1), radius: 1, y: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Bubble Content by Type
    @ViewBuilder
    private func bubbleContent(for msg: ChatMessage) -> some View {
        switch msg.type {
        case .text(let text):
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(messageTextColor)
                .textSelection(.enabled)
            
        case .images(let urls):
            ForEach(urls, id: \.self) { url in
                if let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 240.scaled, maxHeight: 220.scaled)
                        .clipShape(RoundedRectangle(cornerRadius: 8.scaled))
                        .onTapGesture {
                            previewItemURL = url
                        }
                } else {
                    Label("Photo", systemImage: "photo")
                        .font(.system(size: 13))
                        .foregroundColor(timestampColor)
                }
            }
            
        case .videos(let urls):
            ForEach(urls, id: \.self) { url in
                ZStack {
                    RoundedRectangle(cornerRadius: 8.scaled)
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 200.scaled, height: 140.scaled)
                    
                    VStack(spacing: 6.scaled) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 38.scaled))
                            .foregroundColor(.white)
                        
                        Text("Video")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .onTapGesture {
                    previewItemURL = url
                }
            }
            
        case .audio(let urls):
            ForEach(urls, id: \.self) { url in
                whatsappVoiceNoteRow(url: url, isMe: msg.isMe)
            }
            
        case .documents(let urls):
            ForEach(urls, id: \.self) { url in
                let ext = url.pathExtension.lowercased()
                let docInfo = ChatDocumentInfo(
                    name: url.lastPathComponent,
                    url: url,
                    pages: ext.contains("ppt") ? 6 : (ext.contains("doc") ? 5 : 4),
                    sizeText: ext.contains("ppt") ? "3.2 MB" : (ext.contains("doc") ? "2.6 MB" : "1.8 MB"),
                    ext: ext
                )
                documentCardView(doc: docInfo)
            }
            
        case .documentCard(let doc):
            documentCardView(doc: doc)
            
        case .poll(let question, let options):
            pollCardView(question: question, options: options)
            
        case .event(let ev):
            eventCardView(ev: ev)
            
        case .contact(let name, let number, let vcfURL):
            contactCardView(name: name, number: number, vcfURL: vcfURL)
            
        case .location(_, _, let url, let title):
            locationCardView(title: title, url: url)
            
        case .header(let title):
            Text(title)
                .font(.system(size: 12))
                .italic()
                .foregroundColor(timestampColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Document Card View (Images 3 & 4)
    private func documentCardView(doc: ChatDocumentInfo) -> some View {
        VStack(spacing: 0) {
            // Document Layout / Slide Preview Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 6.scaled)
                    .fill(Color(hex: colorScheme == .dark ? "#262D31" : "#E2E8EB"))
                    .frame(height: 84.scaled)
                
                if doc.ext.contains("ppt") {
                    // Presentation slide placeholder graphic
                    VStack(alignment: .leading, spacing: 5.scaled) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#E25736").opacity(0.8))
                            .frame(width: 80.scaled, height: 8.scaled)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 140.scaled, height: 5.scaled)
                        HStack(spacing: 6.scaled) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60.scaled, height: 35.scaled)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60.scaled, height: 35.scaled)
                        }
                    }
                    .padding(8.scaled)
                } else if doc.ext.contains("doc") {
                    // Word text document placeholder graphic
                    VStack(alignment: .leading, spacing: 4.scaled) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#185ABD").opacity(0.8))
                            .frame(width: 90.scaled, height: 7.scaled)
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.35))
                                .frame(maxWidth: .infinity, maxHeight: 4.scaled)
                        }
                    }
                    .padding(10.scaled)
                } else {
                    // Generic document / PDF graphic
                    VStack(spacing: 6.scaled) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 28.scaled))
                            .foregroundColor(Color(hex: doc.ext == "pdf" ? "#E03E3E" : "#00A884"))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6.scaled))
            
            // Bottom Info Bar
            HStack(spacing: 8.scaled) {
                // Application Icon Square
                ZStack {
                    RoundedRectangle(cornerRadius: 4.scaled)
                        .fill(docAppColor(for: doc.ext))
                        .frame(width: 32.scaled, height: 32.scaled)
                    
                    Text(docAppLetter(for: doc.ext))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2.scaled) {
                    Text(doc.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(messageTextColor)
                        .lineLimit(1)
                    
                    Text("\(doc.pages) pages • \(doc.sizeText) • \(doc.ext)")
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundColor(timestampColor)
                }
                
                Spacer(minLength: 4)
            }
            .padding(.top, 6.scaled)
            .padding(.horizontal, 2.scaled)
        }
        .frame(width: isIPad ? 280 : 230.scaled)
        .padding(.vertical, 2.scaled)
        .contentShape(Rectangle())
        .onTapGesture {
            if let u = doc.url {
                previewItemURL = u
            }
        }
    }
    
    private func docAppColor(for ext: String) -> Color {
        if ext.contains("ppt") { return Color(hex: "#E25736") }
        if ext.contains("doc") { return Color(hex: "#185ABD") }
        if ext.contains("xls") { return Color(hex: "#107C41") }
        if ext == "pdf" { return Color(hex: "#E03E3E") }
        return Color(hex: "#00A884")
    }
    
    private func docAppLetter(for ext: String) -> String {
        if ext.contains("ppt") { return "P" }
        if ext.contains("doc") { return "W" }
        if ext.contains("xls") { return "X" }
        if ext == "pdf" { return "PDF" }
        return "DOC"
    }
    
    // MARK: - Contact Card View (WhatsApp Authentic Style - Whole Card Clickable)
    private func contactCardView(name: String, number: String, vcfURL: URL?) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            navigateToContact = ContactCardInfo(name: name, number: number, vcfURL: vcfURL)
        }) {
            VStack(spacing: 0) {
                // Top Section: Avatar + Name + Chevron
                HStack(spacing: 12.scaled) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: colorScheme == .dark ? "#374248" : "#CFD6DA"))
                            .frame(width: 44.scaled, height: 44.scaled)
                        Image(systemName: "person.fill")
                            .font(.system(size: 22.scaled))
                            .foregroundColor(Color(hex: colorScheme == .dark ? "#8696A0" : "#667781"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2.scaled) {
                        Text(name.isEmpty ? "Contact" : name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(messageTextColor)
                            .lineLimit(1)
                        
                        if !number.isEmpty {
                            Text(number)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(timestampColor)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(timestampColor)
                }
                .padding(.horizontal, 14.scaled)
                .padding(.top, 12.scaled)
                .padding(.bottom, 12.scaled)
                
                // Divider
                Rectangle()
                    .fill(Color(hex: colorScheme == .dark ? "#263238" : "#E2E8EB"))
                    .frame(height: 1)
                
                // Bottom Action Buttons: Message | Add contact (Whole Card is Clickable)
                HStack(spacing: 0) {
                    Text("Message".localized)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#00A884"))
                        .frame(maxWidth: .infinity, minHeight: 38.scaled)
                    
                    Rectangle()
                        .fill(Color(hex: colorScheme == .dark ? "#263238" : "#E2E8EB"))
                        .frame(width: 1, height: 26.scaled)
                    
                    Text("Add contact".localized)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#00A884"))
                        .frame(maxWidth: .infinity, minHeight: 38.scaled)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
        .frame(minWidth: 240.scaled)
    }

    // MARK: - Poll Card View (WhatsApp Authentic Style - Image 4)
    private func pollCardView(question: String, options: [ChatPollOption]) -> some View {
        let totalVotes = max(1, options.reduce(0) { $0 + $1.count })
        
        return VStack(alignment: .leading, spacing: 8.scaled) {
            // Question Title
            Text(question)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(messageTextColor)
                .padding(.top, 2.scaled)
            
            // Subtitle: Checkmark circle + Select one
            HStack(spacing: 5.scaled) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(timestampColor)
                Text("Select one".localized)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(timestampColor)
            }
            .padding(.bottom, 4.scaled)
            
            // Options List
            VStack(spacing: 12.scaled) {
                ForEach(options, id: \.text) { opt in
                    VStack(alignment: .leading, spacing: 6.scaled) {
                        HStack(spacing: 10.scaled) {
                            if opt.count > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: colorScheme == .dark ? "#FFFFFF" : "#00A884"))
                                        .frame(width: 20.scaled, height: 20.scaled)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Color(hex: colorScheme == .dark ? "#121B22" : "#FFFFFF"))
                                }
                            } else {
                                Circle()
                                    .stroke(timestampColor.opacity(0.7), lineWidth: 2)
                                    .frame(width: 20.scaled, height: 20.scaled)
                            }
                            
                            Text(opt.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(messageTextColor)
                            
                            Spacer()
                            
                            if opt.count > 0 {
                                // Voter Avatar Circle
                                Circle()
                                    .fill(Color(hex: "#EA4335"))
                                    .frame(width: 18.scaled, height: 18.scaled)
                            }
                            
                            Text("\(opt.count)")
                                .font(.system(size: 13.5, weight: .regular))
                                .foregroundColor(timestampColor)
                        }
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(hex: colorScheme == .dark ? "#263238" : "#E2E8EB"))
                                    .frame(height: 5.scaled)
                                
                                if opt.count > 0 {
                                    let fillWidth = max(10, geo.size.width * CGFloat(opt.count) / CGFloat(totalVotes))
                                    Capsule()
                                        .fill(Color(hex: colorScheme == .dark ? "#FFFFFF" : "#00A884"))
                                        .frame(width: fillWidth, height: 5.scaled)
                                }
                            }
                        }
                        .frame(height: 5.scaled)
                    }
                }
            }
            .padding(.vertical, 4.scaled)
            
            // Divider
            Rectangle()
                .fill(Color(hex: colorScheme == .dark ? "#263238" : "#E2E8EB"))
                .frame(height: 1)
                .padding(.top, 4.scaled)
            
            // Centered "View votes" in green
            HStack {
                Spacer()
                Text("View votes".localized)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(Color(hex: "#00A884"))
                Spacer()
            }
            .padding(.vertical, 4.scaled)
        }
        .frame(minWidth: 260.scaled)
    }
    
    // MARK: - Event Card View (Image 3)
    private func eventCardView(ev: ChatEventInfo) -> some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            HStack(spacing: 10.scaled) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#00A884").opacity(0.18))
                        .frame(width: 38.scaled, height: 38.scaled)
                    Image(systemName: "calendar")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#00A884"))
                }
                
                VStack(alignment: .leading, spacing: 2.scaled) {
                    Text(ev.title)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(messageTextColor)
                    Text(ev.timeText)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(timestampColor)
                }
            }
            
            HStack(spacing: 6.scaled) {
                HStack(spacing: -5.scaled) {
                    Circle().fill(Color.orange).frame(width: 16.scaled, height: 16.scaled)
                    Circle().fill(Color.blue).frame(width: 16.scaled, height: 16.scaled)
                }
                Text(ev.attendees)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(timestampColor)
            }
            
            Divider().background(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08))
            
            HStack {
                Button(action: {}) {
                    Text("Edit event".localized)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color(hex: "#53BDEB"))
                        .frame(maxWidth: .infinity)
                }
                Divider().frame(height: 14.scaled)
                Button(action: {}) {
                    Text("Add to calendar".localized)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color(hex: "#53BDEB"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 2.scaled)
        }
        .frame(width: isIPad ? 290 : 240.scaled)
        .padding(.vertical, 2.scaled)
    }
    
    // MARK: - Location Card View (Image 4)
    private func locationCardView(title: String, url: URL) -> some View {
        VStack(alignment: .leading, spacing: 6.scaled) {
            ZStack {
                RoundedRectangle(cornerRadius: 8.scaled)
                    .fill(Color(hex: colorScheme == .dark ? "#263238" : "#E2E8EB"))
                    .frame(height: 120.scaled)
                
                // Simulated map roads
                VStack(spacing: 14.scaled) {
                    Rectangle().fill(Color.white.opacity(0.12)).frame(height: 2)
                    Rectangle().fill(Color.white.opacity(0.12)).frame(height: 3)
                    Rectangle().fill(Color.white.opacity(0.12)).frame(height: 2)
                }
                
                VStack(spacing: 5.scaled) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 30.scaled))
                        .foregroundColor(.red)
                        .shadow(radius: 2)
                    
                    Text(title)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8.scaled)
                        .padding(.vertical, 3.scaled)
                        .background(Capsule().fill(Color.black.opacity(0.65)))
                }
            }
            .onTapGesture {
                UIApplication.shared.open(url)
            }
        }
        .frame(width: isIPad ? 280 : 230.scaled)
        .padding(.vertical, 2.scaled)
    }
    
    // MARK: - Audio Waveform Bar Heights (WhatsApp Authentic Profile)
    private let waveformHeights: [CGFloat] = [
        6, 12, 18, 10, 24, 14, 20, 8, 16, 26, 12, 22, 16, 28, 14, 8, 18, 10, 22, 14, 8, 12
    ]
    
    // MARK: - WhatsApp Voice Note Row
    private func whatsappVoiceNoteRow(url: URL, isMe: Bool) -> some View {
        let isCurrent = (audioManager.playingURL == url)
        let totalDuration = audioManager.getDuration(for: url)
        let currentPos = isCurrent ? audioManager.currentTime : 0.0
        let progress = isCurrent ? audioManager.progress : 0.0
        let isPlaying = isCurrent && audioManager.isPlaying
        
        let displayTime: String = {
            if isCurrent && (isPlaying || currentPos > 0) {
                return formatAudioTime(currentPos)
            } else if totalDuration > 0 {
                return formatAudioTime(totalDuration)
            } else {
                return "0:00"
            }
        }()
        
        return HStack(alignment: .center, spacing: 10.scaled) {
            // Play / Pause Circle Button
            Button(action: {
                HapticFeedback.generate(.light)
                audioManager.toggle(url: url)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#00A884"))
                        .frame(width: 36.scaled, height: 36.scaled)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 15.scaled, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 1)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Waveform on top + Running Time / Duration on left bottom
            VStack(alignment: .leading, spacing: 4.scaled) {
                // Audio Waveform
                HStack(spacing: 2.2.scaled) {
                    ForEach(0..<waveformHeights.count, id: \.self) { idx in
                        let barRatio = Double(idx) / Double(waveformHeights.count)
                        let isPlayed = isCurrent && (progress > barRatio)
                        
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(isPlayed ? Color(hex: "#00A884") : Color(hex: "#8696A0").opacity(0.45))
                            .frame(width: 2.6.scaled, height: waveformHeights[idx].scaled)
                    }
                }
                .frame(height: 24.scaled)
                
                // Left-side bottom time (counts elapsed while playing / shows duration)
                Text(displayTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(timestampColor)
            }
        }
        .padding(.vertical, 4.scaled)
        .padding(.horizontal, 2.scaled)
    }
    
    private func formatAudioTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
    
    
    // MARK: - Empty Chat
    private var emptyChatView: some View {
        VStack(spacing: 12.scaled) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48.scaled))
                .foregroundColor(timestampColor)
            
            Text("No messages in this chat".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(messageTextColor)
            Spacer()
        }
    }
    
    // MARK: - Load Messages
    private func loadMessages() {
        let loaded: [ChatMessage]
        if let fileURL = conversation.fileURL {
            loaded = ChatBackupManager.shared.parseChatFile(
                url: fileURL,
                mediaFolder: conversation.folderURL,
                chatName: conversation.name
            )
        } else if ChatBackupManager.isDummyDataEnabled {
            loaded = ChatBackupManager.generateDummyMessages(for: conversation.name)
        } else {
            loaded = []
        }
        messages = loaded
        let sections = ChatBackupManager.shared.groupedSections(for: loaded)
        isScrollableContent = Self.estimateIsScrollable(messages: loaded, sectionCount: sections.count)
    }
}

// MARK: - ActivityView for Share Sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ChatConversationView(
        conversation: ChatConversation(
            id: "sample-id",
            name: "+91 98765 43210",
            lastMessage: "Hello!",
            lastDate: Date(),
            folderURL: URL(fileURLWithPath: NSTemporaryDirectory()),
            fileURL: nil,
            messageCount: 5
        )
    )
}
