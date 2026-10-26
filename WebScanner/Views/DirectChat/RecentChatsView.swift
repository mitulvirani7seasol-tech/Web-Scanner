//
//  RecentChatsView.swift
//  WebScanner
//

import SwiftUI

public struct RecentChatsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var recentChatManager = RecentChatManager.shared
    
    @State private var swipedChatId: String? = nil
    @State private var chatToDelete: RecentChatItem? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showPaywall: Bool = false
    @AppStorage(WS_SessionKeys.isPro) private var isPro: Bool = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background image strictly bounded
//                Image(colorScheme == .dark ? "BG_Dark" : "BG")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .clipped()
//                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Bar (Matching Image 3: < Recent Chats)
                    headerBar(topInset: geo.safeAreaInsets.top)
                    
                    // List of Recent Chats
                    if recentChatManager.recentChats.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image("ic_No_chat ")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                            
                            Text("No Chats Available".localized)
                                .font(.inter(.medium, size: 15))
                                .foregroundColor(AppColors.textSecondary(for: colorScheme))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: isIPad ? 14 : 12.scaled) {
                                ForEach(recentChatManager.recentChats) { chat in
                                    RecentChatSwipeableRow(
                                        chat: chat,
                                        colorScheme: colorScheme,
                                        isIPad: isIPad,
                                        isSwiped: swipedChatId == chat.id,
                                        onSwipe: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                swipedChatId = chat.id
                                            }
                                        },
                                        onReset: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                if swipedChatId == chat.id {
                                                    swipedChatId = nil
                                                }
                                            }
                                        },
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                swipedChatId = nil
                                            }
                                            HapticFeedback.generate(.medium)
                                            TR_AdCountViewModel.sharedd.registerTap {
                                                if !isPro {
                                                    showPaywall = true
                                                    return
                                                }
                                                openWhatsApp(chat: chat)
                                            }
                                        },
                                        onDelete: {
                                            chatToDelete = chat
                                            showDeleteConfirmation = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, isIPad ? 32 : 16)
                            .padding(.top, 12)
                            .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 20)
                            .frame(maxWidth: .infinity)
                        }
                        .simultaneousGesture(
                            DragGesture().onChanged { _ in
                                if swipedChatId != nil {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        swipedChatId = nil
                                    }
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
            swipedChatId = nil
        }
        .onDisappear {
            TabBarManager.shared.isHidden = false
            swipedChatId = nil
        }
        .alert("Delete Chat".localized, isPresented: $showDeleteConfirmation, presenting: chatToDelete) { chat in
            Button("No".localized, role: .cancel) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    swipedChatId = nil
                }
                chatToDelete = nil
            }
            Button("Yes".localized, role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    recentChatManager.delete(id: chat.id)
                }
                chatToDelete = nil
                swipedChatId = nil
            }
        } message: { _ in
            Text("Are you sure you want to delete this chat?".localized)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PremiumPaywallView(isFromAppOpen: false) {
                showPaywall = false
            }
        }
    }
    
    // MARK: - Header Bar (Matching Image 3: < Recent Chats)
    private func headerBar(topInset: CGFloat) -> some View {
        HStack(spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 40, height: isIPad ? 44 : 40)
//                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Recent Chats".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, isIPad ? 32 : 16)
        .padding(.top, isIPad ? 14 : 8)
        .padding(.bottom, 12)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
        .frame(maxWidth: .infinity)
    }
    
    private func openWhatsApp(chat: RecentChatItem) {
        let cleanDigits = chat.phoneNumber.filter { "0123456789".contains($0) }
        guard !cleanDigits.isEmpty else { return }
        
        var urlString = "https://wa.me/\(cleanDigits)"
        if !chat.message.isEmpty,
           let encoded = chat.message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "?text=\(encoded)"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Reusable Swipeable Recent Chat Row (Matching Image 3 & ChatBackupView)
public struct RecentChatSwipeableRow: View {
    public let chat: RecentChatItem
    public let colorScheme: ColorScheme
    public let isIPad: Bool
    public let isSwiped: Bool
    public let onSwipe: () -> Void
    public let onReset: () -> Void
    public let onTap: () -> Void
    public let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    private let actionWidth: CGFloat = 56
    private let horizontalSpacing: CGFloat = 10
    
    private var totalOffset: CGFloat {
        actionWidth + horizontalSpacing
    }
    
    public init(
        chat: RecentChatItem,
        colorScheme: ColorScheme,
        isIPad: Bool,
        isSwiped: Bool,
        onSwipe: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.chat = chat
        self.colorScheme = colorScheme
        self.isIPad = isIPad
        self.isSwiped = isSwiped
        self.onSwipe = onSwipe
        self.onReset = onReset
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    public var body: some View {
        ZStack(alignment: .trailing) {
            // Red Delete Button (revealed on swipe to left with spring animation)
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
                .frame(width: actionWidth, height: isIPad ? 68 : 58.scaled)
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.94))
            .opacity(offset < -8 ? min(1.0, Double(-offset) / Double(actionWidth)) : 0)
            .scaleEffect(offset < -8 ? min(1.0, 0.75 + 0.25 * (Double(-offset) / Double(actionWidth))) : 0.75)
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: offset)
            
            // Foreground Card (Matching Image 3: Left ic_wp, middle bold phone & time, right ic_msg)
            HStack(spacing: 14.scaled) {
                // WhatsApp Icon from Assets Direct_Chat
                Image("ic_wp")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 60 : 44.scaled, height: isIPad ? 60 : 44.scaled)
                
                // Phone & Time
                VStack(alignment: .leading, spacing: 4.scaled) {
                    Text(chat.phoneNumber)
                        .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    
                    Text(chat.timeAgoFormatted)
                        .font(.inter(.regular, size: isIPad ? 13 : 11.scaled))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                // Message Icon from Assets Direct_Chat
                Image("ic_msg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled)
            }
            .padding(.horizontal, isIPad ? 18 : 14.scaled)
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
        }
    }
}

