//
//  ChatBackupView.swift
//  WebScanner
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook

public struct ChatBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var backupManager = ChatBackupManager.shared
    
    @State private var showFileImporter: Bool = false
    @State private var showHelpSheet: Bool = false
    @State private var navigateToGuide: Bool = false
    @State private var selectedConversation: ChatConversation?
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    @State private var showImportSourceSheet: Bool = false
    @State private var conversationToDelete: ChatConversation? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var swipedConversationId: String? = nil
    @State private var showPaywall: Bool = false
    @State private var pendingConversationToOpen: ChatConversation? = nil
    @AppStorage(WS_SessionKeys.isPro) private var isPro = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Top Custom Header: < Backup Chats     (?)
                headerView
                
                // Main Content: Empty State or Populated List
                if backupManager.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsListView
                }
                    importBackupButton
            }
            .background(
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            )
            
            // Bottom Sheet Modal for Import Chat Sources
            if showImportSourceSheet {
                importChatSourceSheet
            }
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
            backupManager.loadConversations()
            if TabBarManager.shared.shouldShowImportSheet {
                TabBarManager.shared.shouldShowImportSheet = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    showImportSourceSheet = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            backupManager.loadConversations()
        }
        .onChange(of: selectedConversation) { conv in
            TabBarManager.shared.isHidden = true
        }
        .onChange(of: TabBarManager.shared.shouldShowImportSheet) { shouldShow in
            if shouldShow {
                TabBarManager.shared.shouldShowImportSheet = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    showImportSourceSheet = true
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.zip, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedConversation != nil },
            set: { if !$0 { selectedConversation = nil } }
        )) {
            if let conv = selectedConversation {
                ChatConversationView(conversation: conv)
            }
        }
        .sheet(isPresented: $showHelpSheet) {
            helpSheet
        }
        .alert("Import Error".localized, isPresented: $showErrorAlert) {
            Button("OK".localized) {}
        } message: {
            Text(errorMessage ?? "Could not import the selected chat.".localized)
        }
        .onChange(of: selectedConversation) { newConv in
            if newConv != nil {
                swipedConversationId = nil
            }
        }
        .onChange(of: navigateToGuide) { _ in
            TabBarManager.shared.isHidden = true
        }
        .onAppear {
            TabBarManager.shared.isHidden = true
            swipedConversationId = nil
        }
        .onDisappear {
            swipedConversationId = nil
        }
        .alert("Delete Chat".localized, isPresented: $showDeleteConfirmation, presenting: conversationToDelete) { conv in
            Button("No".localized, role: .cancel) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    swipedConversationId = nil
                }
                conversationToDelete = nil
            }
            Button("Yes".localized, role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    backupManager.deleteConversation(id: conv.id)
                }
                conversationToDelete = nil
                swipedConversationId = nil
            }
        } message: { _ in
            Text("Are you sure you want to delete this chat?".localized)
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            if isPro, let pending = pendingConversationToOpen {
                selectedConversation = pending
            }
            pendingConversationToOpen = nil
        }) {
            PremiumPaywallView(isFromAppOpen: false) {
                showPaywall = false
                if isPro, let pending = pendingConversationToOpen {
                    selectedConversation = pending
                }
                pendingConversationToOpen = nil
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            // Back Button
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
            
            // Title: Backup Chats
            Text("Backup Chats".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            if backupManager.isImporting {
                ProgressView()
                    .tint(AppColors.primaryGreen)
                    .padding(.trailing, 6)
            }
            
            // Help / Info Button (?) -> Navigates to ExportChatGuideView
            Button(action: {
                HapticFeedback.generate(.light)
                TR_AdCountViewModel.sharedd.registerTap {
                    navigateToGuide = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.9 : 0.85))
                        .frame(width: isIPad ? 36 : 30, height: isIPad ? 36 : 30)
                    
                    Image(systemName: "questionmark")
                        .font(.system(size: isIPad ? 16 : 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
            .navigationDestination(isPresented: $navigateToGuide) {
                ExportChatGuideView()
            }
        }
        .padding(.horizontal, isIPad ? 28 : 16.scaled)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 16 : 12)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
    }
    
    // MARK: - Empty State View (Matching Screenshot)
    private var emptyStateView: some View {
        VStack(spacing: isIPad ? 18 : 14.scaled) {
            Spacer()
            
            Image("ic_empty_backupchat")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isIPad ? 130 : 96.scaled, height: isIPad ? 130 : 96.scaled)
            
            Text("No chat backup found".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 18))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.top, 4)
            
            Text("Your backup chats will appear here.".localized)
                .font(.inter(.regular, size: isIPad ? 15 : 13))
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Conversations List View (Matching Screenshot 2)
    private var conversationsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: isIPad ? 14 : 12.scaled) {
                ForEach(backupManager.conversations) { conv in
                    BackupChatRow(
                        conversation: conv,
                        colorScheme: colorScheme,
                        isIPad: isIPad,
                        isSwiped: swipedConversationId == conv.id,
                        onSwipe: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                swipedConversationId = conv.id
                            }
                        },
                        onReset: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                if swipedConversationId == conv.id {
                                    swipedConversationId = nil
                                }
                            }
                        },
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                swipedConversationId = nil
                            }
                            if !isPro {
                                pendingConversationToOpen = conv
                                showPaywall = true
                                return
                            }
                            selectedConversation = conv
                        },
                        onDelete: {
                            conversationToDelete = conv
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(.horizontal, isIPad ? 28 : 16.scaled)
            .padding(.top, 8)
            .padding(.bottom, isIPad ? 110 : 90.scaled)
            .frame(maxWidth: isIPad ? .infinity : .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Import Chat Button
    private var importBackupButton: some View {
        Button(action: {
            HapticFeedback.generate(.medium)
            TR_AdCountViewModel.sharedd.registerTap {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    showImportSourceSheet = true
                }
            }
        }) {
            Text("Import Chat".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 58 : 52.scaled)
                .background(AppColors.primaryGreen)
                .clipShape(Capsule())
                .shadow(color: AppColors.primaryGreen.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.96))
        .padding(.horizontal, isIPad ? 28 : 16.scaled)
        .padding(.top, isIPad ? 20 : 10.scaled)
        .padding(.bottom, isIPad ? 24 : 16.scaled)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
    }
    
    // MARK: - Help Sheet
    private var helpSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("How to Backup Chats".localized)
                    .font(.inter(.bold, size: 20))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                Spacer()
                Button(action: { showHelpSheet = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.top, 24)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    helpStepCard(
                        step: 1,
                        title: "Export Chat from WhatsApp".localized,
                        desc: "Open WhatsApp > Tap Contact/Group Info > Scroll down and tap 'Export Chat' > Choose 'Attach Media' or 'Without Media'.".localized
                    )
                    
                    helpStepCard(
                        step: 2,
                        title: "Save to Files".localized,
                        desc: "From the iOS Share Sheet, select 'Save to Files' and choose any folder on your device.".localized
                    )
                    
                    helpStepCard(
                        step: 3,
                        title: "Import Backup".localized,
                        desc: "In WebScanner, tap 'Import Backup' and choose the saved ZIP or TXT file.".localized
                    )
                    
                    helpStepCard(
                        step: 4,
                        title: "View Offline Anytime".localized,
                        desc: "Your conversation will be securely stored offline with full media and search support.".localized
                    )
                }
                .padding(.vertical, 4)
            }
            
            Button(action: { showHelpSheet = false }) {
                Text("Got It".localized)
                    .font(.inter(.bold, size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.primaryGreen)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 22)
        .background(AppColors.background(for: colorScheme))
        .presentationDetents([.medium, .large])
    }
    
    private func helpStepCard(step: Int, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGreen.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text("\(step)")
                    .font(.inter(.bold, size: 14))
                    .foregroundColor(AppColors.primaryGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.inter(.semiBold, size: 15))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                Text(desc)
                    .font(.inter(.regular, size: 13))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Import Chat Source Sheet Modal
    private var importChatSourceSheet: some View {
        ZStack(alignment: isIPad ? .center : .bottom) {
            // Semi-transparent backdrop overlay
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        showImportSourceSheet = false
                    }
                }
            
            // Sheet / Center Modal Card
            VStack(spacing: 0) {
                // Title: Import Chat
                Text("Import Chat".localized)
                    .font(.inter(.bold, size: isIPad ? 24 : 22))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .padding(.top, isIPad ? 26 : 24)
                
                // Subtitle: Where would you like to import chats from?
                Text("Where would you like to import chats from?".localized)
                    .font(.inter(.regular, size: isIPad ? 16 : 14))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                
                // 3 Options: WhatsApp, WA Business, Files
                HStack(spacing: isIPad ? 18 : 12) {
                    importSourceCard(
                        title: "Whatsapp".localized,
                        imageName: "ic_import_whatsapp",
                        action: { openWhatsApp() }
                    )
                    
                    importSourceCard(
                        title: "WA Business".localized,
                        imageName: "ic_import_wabusiness",
                        action: { openWhatsAppBusiness() }
                    )
                    
                    importSourceCard(
                        title: "Files".localized,
                        imageName: "ic_import_files",
                        action: { openFiles() }
                    )
                }
                .padding(.horizontal, isIPad ? 28 : 18)
                .padding(.top, isIPad ? 24 : 20)
                .padding(.bottom, isIPad ? 30 : 28)
            }
            .frame(maxWidth: isIPad ? 480 : .infinity)
            .padding(.horizontal, isIPad ? 24 : 0)
            .background(
                Group {
                    if isIPad {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(colorScheme == .dark ? Color(hex: "#1E1E20") : Color.white)
                            .shadow(color: Color.black.opacity(0.25), radius: 32, x: 0, y: 12)
                    } else {
                        (colorScheme == .dark ? Color(hex: "#1E1E20") : Color.white)
                            .clipShape(CustomRoundedCorners(radius: 28, corners: [.topLeft, .topRight]))
                            .shadow(color: Color.black.opacity(0.18), radius: 25, y: -6)
                    }
                }
            )
            .transition(
                isIPad
                    ? .asymmetric(
                        insertion: .scale(scale: 0.92).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    )
                    : .move(edge: .bottom).combined(with: .opacity)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isIPad ? .center : .bottom)
        .ignoresSafeArea()
    }
    
    // MARK: - Import Source Card
    private func importSourceCard(title: String, imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap {
                action()
            }
        }) {
            VStack(spacing: isIPad ? 14 : 12) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 60 : 48, height: isIPad ? 60 : 48)
                
                Text(title)
                    .font(.inter(.semiBold, size: isIPad ? 16 : 14))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 136 : 116)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 22 : 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color(hex: "#2C2C2E") : Color(hex: "#F1F2F6"))
            )
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.94))
    }
    
    // MARK: - Actions for Sources
    private func openWhatsApp() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showImportSourceSheet = false
        }
        
        // Priority 1: Direct Consumer app scheme
        let waConsumerSchemes = ["whatsapp-consumer://app", "whatsapp-consumer://"]
        for scheme in waConsumerSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        
        // Priority 2: Generic whatsapp scheme (if consumer scheme wasn't registered by user's WhatsApp build)
        let waSchemes = ["whatsapp://app", "whatsapp://"]
        for scheme in waSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        
        // Fallback to App Store
        if let appStoreURL = URL(string: "https://apps.apple.com/app/whatsapp-messenger/id310633997") {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    private func openWhatsAppBusiness() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showImportSourceSheet = false
        }
        
        let waBizSchemes = ["whatsapp-smb://app", "whatsapp-smb://", "whatsapp-business://app", "whatsapp-business://"]
        for scheme in waBizSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        
        // Fallback to App Store for WhatsApp Business
        if let appStoreURL = URL(string: "https://apps.apple.com/app/whatsapp-business/id1386432906") {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
    
    private func openFiles() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            showImportSourceSheet = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showFileImporter = true
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                do {
                    let conv = try await backupManager.importChatFile(from: url)
                    await MainActor.run {
                        if !isPro {
                            pendingConversationToOpen = conv
                            showPaywall = true
                        } else {
                            selectedConversation = conv
                        }
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    }
                }
            }
        case .failure(let err):
            errorMessage = err.localizedDescription
            showErrorAlert = true
        }
    }
}

// MARK: - BackupChatRow with Interactive Swipe to Delete (Matching Screenshot 2)
private struct BackupChatRow: View {
    let conversation: ChatConversation
    let colorScheme: ColorScheme
    let isIPad: Bool
    let isSwiped: Bool
    let onSwipe: () -> Void
    let onReset: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    
    private let actionWidth: CGFloat = 56
    private let horizontalSpacing: CGFloat = 10
    
    private var totalOffset: CGFloat {
        actionWidth + horizontalSpacing
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Red Delete Button (revealed on swipe to left with spring animation and horizontal spacing)
            Button(action: {
                HapticFeedback.generate(.medium)
                onDelete()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18.scaled, style: .continuous)
                        .fill(Color(hex: "#FF3B30"))
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: actionWidth, height: isIPad ? 66 : 56.scaled)
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.94))
            .opacity(offset < -8 ? min(1.0, Double(-offset) / Double(actionWidth)) : 0)
            .scaleEffect(offset < -8 ? min(1.0, 0.75 + 0.25 * (Double(-offset) / Double(actionWidth))) : 0.75)
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: offset)
            
            // Foreground Card (Entire card is clickable & swipeable)
            HStack(spacing: isIPad ? 16 : 12.scaled) {
                // Green Avatar Circle with Person Silhouette
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGreen)
                        .frame(width: isIPad ? 52 : 46.scaled, height: isIPad ? 52 : 46.scaled)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Name & Last Message
                VStack(alignment: .leading, spacing: 4.scaled) {
                    Text(conversation.name)
                        .font(.inter(.semiBold, size: isIPad ? 17 : 15))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    
                    Text(conversation.lastMessage.isEmpty ? "No messages".localized : conversation.lastMessage)
                        .font(.inter(.regular, size: isIPad ? 14 : 12))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Green Count Badge
                Text("\(max(conversation.messageCount, 1))")
                    .font(.inter(.bold, size: isIPad ? 13 : 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(AppColors.primaryGreen)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, isIPad ? 16 : 14.scaled)
            .padding(.vertical, isIPad ? 14 : 12.scaled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 18.scaled)
            .contentShape(Rectangle())
            .offset(x: offset)
            .onTapGesture {
                if isSwiped {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        offset = 0
                    }
                    onReset()
                } else {
                    HapticFeedback.generate(.light)
                    onTap()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            if isSwiped {
                                let newOffset = -totalOffset + value.translation.width
                                offset = min(0, max(newOffset, -totalOffset - 25))
                            } else if value.translation.width < 0 {
                                offset = max(value.translation.width, -totalOffset - 25)
                            }
                        }
                    }
                    .onEnded { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            if isSwiped {
                                if value.translation.width > 20 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        offset = 0
                                    }
                                    onReset()
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        offset = -totalOffset
                                    }
                                }
                            } else {
                                if value.translation.width < -35 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        offset = -totalOffset
                                    }
                                    onSwipe()
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        offset = 0
                                    }
                                    onReset()
                                }
                            }
                        }
                    }
            )
            .onChange(of: isSwiped) { swiped in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    offset = swiped ? -totalOffset : 0
                }
            }
//            .contextMenu {
//                Button(role: .destructive, action: {
//                    onDelete()
//                }) {
//                    Label("Delete Chat".localized, systemImage: "trash")
//                }
//            }
        }
    }
}

#Preview {
    ChatBackupView()
}
