//
//  DirectChatView.swift
//  WebScanner
//

import SwiftUI

public struct DirectChatView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    @StateObject private var countryManager = CountryCodeManager.shared
    @StateObject private var quickMessageManager = QuickMessageManager.shared
    @ObservedObject private var recentChatManager = RecentChatManager.shared
    
    @State private var selectedCountry: CountryCodeItem = CountryCodeItem(name: "India", code: "IN", emoji: "🇮🇳", dial_code: "+91")
    @State private var phoneNumber: String = ""
    @State private var messageText: String = ""
    @State private var selectedQuickMessage: String? = nil
    
    @State private var navigateToCountryPicker: Bool = false
    @State private var showPaywall: Bool = false
    @State private var navigateToRecentChats: Bool = false
    @State private var navigateToQuickMessages: Bool = false
    
    // Country phone number validation alert
    @State private var showValidationAlert: Bool = false
    @State private var validationErrorMessage: String = ""
    
    // Swipe to delete in recent chats
    @State private var swipedChatId: String? = nil
    @State private var chatToDelete: RecentChatItem? = nil
    @State private var showDeleteConfirmation: Bool = false
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    // Track redirect to clear inputs upon returning
    @State private var shouldClearOnReturn: Bool = false
    
    private enum InputField: Hashable {
        case phone
        case message
    }
    
    @FocusState private var focusedField: InputField?
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var isPhoneEmpty: Bool {
        phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    
                    Image(colorScheme == .dark ? "BG_Dark" : "BG")
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .ignoresSafeArea()
                    
                    
                    VStack(spacing: 0) {
                        headerBar(topInset: geo.safeAreaInsets.top)
                        
                        // Scrollable Content
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: isIPad ? 24 : 18.scaled) {
                                
                                // 1. Main Direct Chat Card
                                directChatCard
                                
                                if !isPro {
                                    TR_NativeAd7()
                                }
                                
                                // 2. Recent Chats Section
                                recentChatsSection
                                
                                // Bottom spacing to clear floating tab bar
                                Spacer()
                                    .frame(height: isIPad ? 140 : 110.scaled)
                            }
                            .padding(.horizontal, isIPad ? 32 : 16)
                            .padding(.top, isIPad ? 6 : 4.scaled)
                            .frame(maxWidth: isIPad ? .infinity : .infinity)
                            .frame(maxWidth: .infinity)
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .simultaneousGesture(
                            DragGesture().onChanged { _ in
                                if focusedField != nil {
                                    focusedField = nil
                                    hideKeyboard()
                                }
                                if swipedChatId != nil {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                        swipedChatId = nil
                                    }
                                }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
//                .frame(width: geo.size.width, height: geo.size.height)
            }
            
            .contentShape(Rectangle())
            .onTapGesture {
                if focusedField != nil {
                    focusedField = nil
                    hideKeyboard()
                }
                if swipedChatId != nil {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        swipedChatId = nil
                    }
                }
            }
            .dismissKeyboardOnOutsideTap()
            .navigationDestination(isPresented: $navigateToRecentChats) {
                RecentChatsView()
            }
            .navigationDestination(isPresented: $navigateToQuickMessages) {
                QuickMessagesView(selectedMessage: $messageText, selectedPill: $selectedQuickMessage)
            }
            .navigationDestination(isPresented: $navigateToCountryPicker) {
                SelectCountryView(selectedCountry: $selectedCountry)
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PremiumPaywallView(isFromAppOpen: false) {
                    showPaywall = false
                }
            }
            .alert("Invalid Phone Number".localized, isPresented: $showValidationAlert) {
                Button("OK".localized, role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                clearInputsIfReturning()
            }
            .onAppear {
                clearInputsIfReturning()
                swipedChatId = nil
            }
            .id(localizationHelper.refreshID)
        }
    }
    
    private func clearInputsIfReturning() {
        if shouldClearOnReturn {
            phoneNumber = ""
            messageText = ""
            selectedQuickMessage = nil
            shouldClearOnReturn = false
        }
    }
    
    // MARK: - Header Bar (Matching Image 3: < Recent Chats)
    private func headerBar(topInset: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text("Direct Chat".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 22))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            Button(action: {
                focusedField = nil
                hideKeyboard()
                HapticFeedback.generate(.light)
                showPaywall = true
            }) {
                Image("ic_premium")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 46 : 36.scaled, height: isIPad ? 46 : 36.scaled)
                    .contentShape(Rectangle())
            }
            .frame(width: isIPad ? 56 : 44, height: isIPad ? 56 : 44)
            .contentShape(Rectangle())
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, isIPad ? 32 : 16)
        .padding(.top, isIPad ? 14 : 8)
        .padding(.bottom, 12)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Direct Chat Card
    private var directChatCard: some View {
        VStack(alignment: .leading, spacing: isIPad ? 18 : 14.scaled) {
            
            // 1. Enter WhatsApp Number Label
            Text("Enter WhatsApp Number".localized)
                .font(.inter(.bold, size: isIPad ? 17 : 14))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            // 2. Phone Input Row
            HStack(spacing: isIPad ? 12 : 8.scaled) {
                // Country Code Button (Pushes SelectCountryView)
                Button(action: {
                    focusedField = nil
                    hideKeyboard()
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap {
                        navigateToCountryPicker = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(selectedCountry.dial_code)
                            .font(.inter(.semiBold, size: isIPad ? 16 : 14.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: isIPad ? 13 : 11.scaled, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                    .padding(.horizontal, isIPad ? 16 : 12.scaled)
                    .frame(height: isIPad ? 52 : 46.scaled)
                    .background(inputPillBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14.scaled, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Phone Number TextField
                HStack(spacing: 8) {
                    TextField("Enter phone number".localized, text: $phoneNumber)
                        .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                        .keyboardType(.phonePad)
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .focused($focusedField, equals: .phone)
                    
                    if !phoneNumber.isEmpty {
                        Button(action: { phoneNumber = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                    }
                }
                .padding(.horizontal, isIPad ? 16 : 14.scaled)
                .frame(height: isIPad ? 52 : 46.scaled)
                .background(inputPillBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14.scaled, style: .continuous))
            }
            
            // 3. Message Label
            Text("Message".localized)
                .font(.inter(.bold, size: isIPad ? 17 : 14))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.top, 2)
            
            // 4. Message Input Box (Type or message here...)
            ZStack(alignment: .topLeading) {
                if messageText.isEmpty {
                    Text("Type or message here...".localized)
                        .font(.inter(.regular, size: isIPad ? 15 : 13.scaled))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.85))
                        .padding(.horizontal, 14.scaled)
                        .padding(.vertical, 14.scaled)
                }
                
                TextEditor(text: $messageText)
                    .font(.inter(.regular, size: isIPad ? 15 : 13.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8.scaled)
                    .padding(.vertical, 8.scaled)
                    .focused($focusedField, equals: .message)
            }
            .frame(height: isIPad ? 120 : 100.scaled)
            .background(inputPillBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16.scaled, style: .continuous))
            
            // 5. Quick Messages Section
            VStack(alignment: .leading, spacing: isIPad ? 12 : 8.scaled) {
                HStack {
                    Text("Quick Messages".localized)
                        .font(.inter(.bold, size: isIPad ? 17 : 14))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Spacer()
                    
                    Button(action: {
                        focusedField = nil
                        hideKeyboard()
                        HapticFeedback.generate(.light)
                        TR_AdCountViewModel.sharedd.registerTap {
                            navigateToQuickMessages = true
                        }
                    }) {
                        Text("View All".localized)
                            .font(.inter(.semiBold, size: isIPad ? 15 : 12.scaled))
                            .foregroundColor(AppColors.primaryGreen)
                    }
                }
                
                // Horizontal pills from QuickMessageManager.defaultMessages
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isIPad ? 10 : 8.scaled) {
                        ForEach(QuickMessageManager.defaultMessages, id: \.self) { pill in
                            let isSelected = (selectedQuickMessage == pill)
                            
                            Button(action: {
                                focusedField = nil
                                hideKeyboard()
                                HapticFeedback.generate(.selection)
                                TR_AdCountViewModel.sharedd.registerTap()
                                if isSelected {
                                    selectedQuickMessage = nil
                                    messageText = ""
                                } else {
                                    selectedQuickMessage = pill
                                    messageText = pill
                                }
                            }) {
                                Text(pill)
                                    .font(.inter(isSelected ? .semiBold : .medium, size: isIPad ? 14 : 12.scaled))
                                    .foregroundColor(isSelected ? .white : AppColors.textPrimary(for: colorScheme))
                                    .padding(.horizontal, isIPad ? 18 : 14.scaled)
                                    .padding(.vertical, isIPad ? 10 : 8.scaled)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? AppColors.primaryGreen : inputPillColor)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // 6. Action Button: Open WhatsApp Chat (Disabled when phone number is empty)
            Button(action: {
                focusedField = nil
                hideKeyboard()
                TR_AdCountViewModel.sharedd.registerTap {
                    if !isPro {
                        showPaywall = true
                        return
                    }
                    handleOpenWhatsApp()
                }
            }) {
                Text("Open WhatsApp Chat".localized)
                    .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 56 : 50.scaled)
                    .background(isPhoneEmpty ? AppColors.primaryGreen.opacity(0.4) : AppColors.primaryGreen)
                    .clipShape(Capsule())
                    .shadow(color: isPhoneEmpty ? Color.clear : AppColors.primaryGreen.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .disabled(isPhoneEmpty)
            .buttonStyle(ScaleButtonStyle(scaleAmount: isPhoneEmpty ? 1.0 : 0.97))
            .padding(.top, 4)
        }
        .padding(.horizontal, isIPad ? 22 : 16.scaled)
        .padding(.vertical, isIPad ? 22 : 18.scaled)
        .contentShape(Rectangle())
        .onTapGesture {
            if focusedField != nil {
                focusedField = nil
                hideKeyboard()
            }
        }
        .glassCard(
            cornerRadius: 24.scaled,
            color: colorScheme == .dark ? Color.clear : Color.clear
        )
    }
    
    private var inputPillBackground: some View {
        RoundedRectangle(cornerRadius: 14.scaled, style: .continuous)
            .fill(inputPillColor)
    }
    
    private var inputPillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.09) : Color(hex: "#747474").opacity(0.10)
    }
    
    // MARK: - Recent Chats Section
    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 16 : 12.scaled) {
            HStack {
                Text("Recent Chats".localized)
                    .font(.inter(.bold, size: isIPad ? 22 : 17))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                // Hide View All when recent chats is empty
                if !recentChatManager.recentChats.isEmpty {
                    Button(action: {
                        focusedField = nil
                        hideKeyboard()
                        HapticFeedback.generate(.light)
                        TR_AdCountViewModel.sharedd.registerTap {
                            navigateToRecentChats = true
                        }
                    }) {
                        Text("View All".localized)
                            .font(.inter(.semiBold, size: isIPad ? 16 : 13))
                            .foregroundColor(AppColors.primaryGreen)
                    }
                }
            }
            
            if recentChatManager.recentChats.isEmpty {
                VStack(spacing: isIPad ? 14 : 10.scaled) {
                    Image("ic_No_chat ")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isIPad ? 90 : 74.scaled, height: isIPad ? 90 : 74.scaled)
                    
                    Text("No Chats Available".localized)
                        .font(.inter(.medium, size: isIPad ? 16 : 13))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIPad ? 32 : 24.scaled)
            } else {
                // Show latest 10 on iPhone, latest 20 on iPad
                let maxRecentCount = isIPad ? 20 : 10
                let displayed = Array(recentChatManager.recentChats.prefix(maxRecentCount))
                
                LazyVStack(spacing: isIPad ? 12 : 9.scaled) {
                    ForEach(displayed) { chat in
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
                                focusedField = nil
                                hideKeyboard()
                                HapticFeedback.generate(.medium)
                                TR_AdCountViewModel.sharedd.registerTap {
                                    if !isPro {
                                        showPaywall = true
                                        return
                                    }
                                    shouldClearOnReturn = true
                                    openWhatsAppDirect(fullNumber: chat.phoneNumber, message: chat.message)
                                }
                            },
                            onDelete: {
                                chatToDelete = chat
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Validation & Open WhatsApp Action
    private func handleOpenWhatsApp() {
        if !isPro {
            showPaywall = true
            return
        }
        let result = PhoneNumberValidator.validate(number: phoneNumber, country: selectedCountry)
        if !result.isValid {
            HapticFeedback.generate(.error)
            validationErrorMessage = result.errorMessage
            showValidationAlert = true
            return
        }
        HapticFeedback.generate(.medium)
        openWhatsApp()
    }
    
    private func openWhatsApp() {
        let cleanPhone = phoneNumber.filter { "0123456789".contains($0) }
        guard !cleanPhone.isEmpty else { return }
        
        let dialDigits = selectedCountry.dial_code.filter { "0123456789".contains($0) }
        let fullDigits = "\(dialDigits)\(cleanPhone)"
        let formattedDisplay = "\(selectedCountry.dial_code) \(cleanPhone)"
        
        RecentChatManager.shared.addChat(phoneNumber: formattedDisplay, message: messageText)
        
        var urlString = "https://wa.me/\(fullDigits)"
        if !messageText.isEmpty,
           let encoded = messageText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "?text=\(encoded)"
        }
        
        if let url = URL(string: urlString) {
            shouldClearOnReturn = true
            UIApplication.shared.open(url)
        }
    }
    
    private func openWhatsAppDirect(fullNumber: String, message: String) {
        let cleanDigits = fullNumber.filter { "0123456789".contains($0) }
        guard !cleanDigits.isEmpty else { return }
        
        var urlString = "https://wa.me/\(cleanDigits)"
        if !message.isEmpty,
           let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "?text=\(encoded)"
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    DirectChatView()
}
