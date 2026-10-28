//
//  HomeView.swift
//  WebScanner
//

import SwiftUI

public enum HomeDestination: Hashable {
    case webScanner(accountId: String?)
    case clone(platform: WebAppPlatform, accountId: String?)
    case statusMain
    case statusSaver
    case howToDownloadStatus
    case splitLongVideo
    case captionStatus
    case backupChats
    case chatConversation(ChatConversation)
    case chatMain
    case quickReply
    case addQuickReplyMessage
    case funnyMessages
    case scanQRCode
    case scanDetails(String)
    case generateQRCode
    case createQRCode(QRCodeCategory)
    case qrCodeDetails(scannedText: String)
    case createBarcode(BarcodeCategory)
    case barcodeDetails(barcodeText: String, category: BarcodeCategory)
    case recentPlatforms
}

public struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    @ObservedObject private var tabBarManager = TabBarManager.shared
    @ObservedObject private var passcodeManager = PasscodeManager.shared
    @StateObject private var accountManager = AccountManager.shared
    
    @Binding var selectedTab: Int
    @State private var navPath = NavigationPath()
    @State private var showRenameSheet: Bool = false
    @State private var accountToRename: AppAccount?
    @State private var newAccountName: String = ""
    @State private var showAllRecent: Bool = false
    @State private var swipedAccountId: String? = nil
    @State private var accountToDelete: AppAccount? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showNoInternetAlert: Bool = false
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var isSmallDevice: Bool {
        !isIPad && UIScreen.main.bounds.width <= 375
    }
    
    public init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        NavigationStack(path: $navPath) {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    
                    Image(colorScheme == .dark ? "BG_Dark" : "BG")
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        topHeader
                            .padding(.horizontal, 16)
                            .padding(.top, isIPad ? 14 : 8.scaled)
                            .padding(.bottom, isIPad ? 10 : 10.scaled)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: isIPad ? 24 : 20.scaled) {
                                heroScanBanner
                                
                                if !isPro {
                                    TR_NativeAd7()
                                }
                                
                                whatsappToolsSection
                                
                                supportedPlatformsSection
                                
                                recentPlatformsSection
                                
                                Spacer()
                                    .frame(height: isIPad ? 32 : 24)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, isIPad ? 6 : 4.scaled)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            .navigationDestination(for: HomeDestination.self) { destination in
                switch destination {
                case .webScanner(let accountId):
                    let account = accountManager.accounts.first(where: { $0.id == accountId })
                    WebScannerView(existingAccount: account)
                        .id(accountId ?? "new_ws_scanner")
                case .clone(let platform, let accountId):
                    let account = accountManager.accounts.first(where: { $0.id == accountId })
                    CloneWebView(platform: platform, existingAccount: account)
                case .statusMain:
                    StatusMainView(navPath: $navPath)
                case .howToDownloadStatus:
                    HowToDownloadStatusView()
                case .statusSaver:
                    StatusSaverView()
                case .splitLongVideo:
                    SplitLongVideoView(navPath: $navPath)
                case .captionStatus:
                    CaptionStatusListView()
                case .backupChats:
                    ChatBackupView()
                case .chatConversation(let conv):
                    ChatConversationView(conversation: conv)
                        .id(conv.id)
                case .chatMain:
                    ChatMainView(navPath: $navPath)
                case .quickReply:
                    QuickReplyView(navPath: $navPath)
                case .addQuickReplyMessage:
                    AddQuickReplyMessageView()
                case .funnyMessages:
                    FunnyMessagesView(navPath: $navPath)
                case .scanQRCode:
                    ScanQRCodeView(navPath: $navPath)
                case .scanDetails(let code):
                    ScanDetailsView(scannedText: code, navPath: $navPath)
                case .generateQRCode:
                    GenerateQRCodeMainView(navPath: $navPath)
                case .createQRCode(let cat):
                    CreateQRCodeFormView(category: cat, navPath: $navPath)
                case .qrCodeDetails(let text):
                    QRCodeDetailsView(resultText: text, navPath: $navPath)
                case .createBarcode(let cat):
                    CreateBarcodeFormView(category: cat, navPath: $navPath)
                case .barcodeDetails(let text, let cat):
                    BarcodeDetailsView(barcodeText: text, category: cat, navPath: $navPath)
                case .recentPlatforms:
                    RecentPlatformsView(navPath: $navPath)
                }
            }
            .sheet(isPresented: $showRenameSheet) {
                renameSheet
            }
            .alert("Delete Account".localized, isPresented: $showDeleteConfirmation, presenting: accountToDelete) { acc in
                Button("No".localized, role: .cancel) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        swipedAccountId = nil
                    }
                    accountToDelete = nil
                }
                Button("Yes".localized, role: .destructive) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        deleteAndLogoutAccount(acc)
                    }
                    accountToDelete = nil
                    swipedAccountId = nil
                }
            } message: { _ in
                Text("Are you sure you want to delete this account?".localized)
            }
            .alert("No Internet Connection".localized, isPresented: $showNoInternetAlert) {
                Button("OK".localized, role: .cancel) {}
            } message: {
                Text("Please check your internet connection and try again.".localized)
            }
            .onChange(of: navPath) { path in
                TabBarManager.shared.isHidden = !path.isEmpty
                swipedAccountId = nil
            }
            .onChange(of: tabBarManager.chatToOpenImmediately) { conv in
                if let conv = conv {
                    tabBarManager.chatToOpenImmediately = nil
                    TabBarManager.shared.isHidden = true
                    var newPath = NavigationPath()
                    newPath.append(HomeDestination.backupChats)
                    if isPro {
                        newPath.append(HomeDestination.chatConversation(conv))
                    } else {
                        tabBarManager.isPaywallFromAppOpen = false
                        tabBarManager.showPaywall = true
                    }
                    navPath = newPath
                }
            }
            .onChange(of: tabBarManager.shouldNavigateToBackupChats) { shouldNav in
                if shouldNav {
                    tabBarManager.shouldNavigateToBackupChats = false
                    TabBarManager.shared.isHidden = true
                    var newPath = NavigationPath()
                    newPath.append(HomeDestination.backupChats)
                    navPath = newPath
                }
            }
            .onAppear {
                if let conv = tabBarManager.chatToOpenImmediately {
                    tabBarManager.chatToOpenImmediately = nil
                    TabBarManager.shared.isHidden = true
                    var newPath = NavigationPath()
                    newPath.append(HomeDestination.backupChats)
                    if isPro {
                        newPath.append(HomeDestination.chatConversation(conv))
                    } else {
                        tabBarManager.isPaywallFromAppOpen = false
                        tabBarManager.showPaywall = true
                    }
                    navPath = newPath
                } else if tabBarManager.shouldNavigateToBackupChats {
                    tabBarManager.shouldNavigateToBackupChats = false
                    TabBarManager.shared.isHidden = true
                    var newPath = NavigationPath()
                    newPath.append(HomeDestination.backupChats)
                    navPath = newPath
                } else {
                    TabBarManager.shared.isHidden = !navPath.isEmpty
                }
            }
            .id(localizationHelper.refreshID)
        }
    }
    
    // MARK: - Top Header
    private var topHeader: some View {
        HStack(alignment: .center) {
            Text("Web Scanner".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 22))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            Button(action: {
                HapticFeedback.generate(.light)
                tabBarManager.isPaywallFromAppOpen = false
                tabBarManager.showPaywall = true
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
    }
    
    // MARK: - Hero Banner: WT Scan Now
    private var heroScanBanner: some View {
        Button(action: {
            HapticFeedback.generate(.medium)
            guard NetworkMonitor.shared.isNetworkAvailable else {
                showNoInternetAlert = true
                return
            }
            TR_AdCountViewModel.sharedd.registerTap {
                navPath.append(HomeDestination.webScanner(accountId: nil))
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: isIPad ? 24 : 18.scaled, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        GeometryReader { bgGeo in
                            Image("ic_WT_Scan_Now_BG")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: bgGeo.size.width, height: bgGeo.size.height)
                                .clipped()
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: isIPad ? 24 : 18.scaled, style: .continuous))
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: isIPad ? 12 : (isSmallDevice ? 10 : 10.scaled)) {
                        Text("WT Scan Now".localized)
                            .font(.inter(.bold, size: isIPad ? 23 : (isSmallDevice ? 17 : 19)))
                            .foregroundColor(.white)
                        
                        Text("Access Your Chats Instantly".localized)
                            .font(.inter(.regular, size: isIPad ? 14 : (isSmallDevice ? 10 : 11)))
                            .foregroundColor(.white.opacity(0.88))
                            .lineLimit(1)
                        
                        HStack(spacing: isSmallDevice ? 6 : 10) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: isIPad ? 20 : (isSmallDevice ? 14 : 16.scaled), weight: .bold))
                                .foregroundColor(Color(hex: "#121212"))
                            
                            Text("Scan Now".localized)
                                .font(.inter(.bold, size: isIPad ? 14 : (isSmallDevice ? 10 : 11)))
                                .foregroundColor(Color(hex: "#121212"))
                        }
                        .padding(.horizontal, isIPad ? 16 : (isSmallDevice ? 10 : 12.scaled))
                        .padding(.vertical, isIPad ? 8 : (isSmallDevice ? 5 : 6.scaled))
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .padding(.top, isIPad ? 4 : 2.scaled)
                    }
                    
                    Spacer()
                    
                    Image("ic_WT_Scan_Now")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: isIPad ? 150 : (isSmallDevice ? 90 : 90.scaled),
                            height: isIPad ? 150 : (isSmallDevice ? 90 : 90.scaled)
                        )
                }
                .padding(.horizontal, isIPad ? 24 : (isSmallDevice ? 14 : 18.scaled))
                .padding(.vertical, isIPad ? 18 : (isSmallDevice ? 10 : 12.scaled))
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 220 : (isSmallDevice ? 124 : 134.scaled))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - WhatsApp Tools Section
    private var whatsappToolsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 16 : 10.scaled) {
            Text("WhatsApp Tools".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 17))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            HStack(spacing: isIPad ? 16 : (isSmallDevice ? 8 : 12.scaled)) {
                // Backup Chats
                toolCard(
                    title: "Backup Chats".localized,
                    iconName: "ic_backUp"
                ) {
                    navPath.append(HomeDestination.backupChats)
                }
                
                // Status Saver
                toolCard(
                    title: "Status".localized,
                    iconName: "ic_Status"
                ) {
                    navPath.append(HomeDestination.statusMain)
                }
                
                // Chat
                toolCard(
                    title: "Chat".localized,
                    iconName: "ic_Chat"
                ) {
                    navPath.append(HomeDestination.chatMain)
                }
            }
        }
    }
    
    private func toolCard(title: String, iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap {
                action()
            }
        }) {
            toolCardContent(title: title, iconName: iconName)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func toolCardContent(title: String, iconName: String) -> some View {
        VStack(spacing: isIPad ? 12 : (isSmallDevice ? 6 : 9.scaled)) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: isIPad ? 60 : (isSmallDevice ? 42 : 50.scaled),
                    height: isIPad ? 60 : (isSmallDevice ? 42 : 50.scaled)
                )
            
            Text(title)
                .font(.inter(.semiBold, size: isIPad ? 14 : (isSmallDevice ? 11 : 12)))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? 22 : (isSmallDevice ? 16 : 20.scaled))
        .contentShape(Rectangle())
        .glassCard(
            cornerRadius: 16.scaled,
            color: colorScheme == .dark ? Color.clear : Color.clear
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - Supported Platforms Section (Inside one continuous Liquid Glass card)
    private var supportedPlatformsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 12.scaled) {
            Text("Supported Platforms".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            HStack(spacing: 0) {
                platformItem(platform: .telegram, icon: "ic_telegram")
                platformItem(platform: .facebook, icon: "ic_facebook")
                platformItem(platform: .instagram, icon: "ic_instagram")
                platformItem(platform: .twitter, icon: "ic_X")
                platformItem(platform: .google, icon: "ic_Google")
            }
        }
        .padding(.horizontal, isIPad ? 22 : 16.scaled)
        .padding(.vertical, isIPad ? 22 : 20.scaled)
        .glassCard(
            cornerRadius: 16.scaled,
            color: colorScheme == .dark ? Color.clear : Color.clear
        )
    }
    
    private func platformItem(platform: WebAppPlatform, icon: String) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            guard NetworkMonitor.shared.isNetworkAvailable else {
                showNoInternetAlert = true
                return
            }
            TR_AdCountViewModel.sharedd.registerTap {
                navPath.append(HomeDestination.clone(platform: platform, accountId: nil))
            }
        }) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: isIPad ? 60 : (isSmallDevice ? 42 : 50.scaled),
                    height: isIPad ? 60 : (isSmallDevice ? 42 : 50.scaled)
                )
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Recent / Saved Platforms Section
    private var recentPlatformsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 14 : 10.scaled) {
            HStack {
                Text("Recent Platforms".localized)
                    .font(.inter(.bold, size: isIPad ? 20 : 17))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                if !accountManager.accounts.isEmpty {
                    Button(action: {
                        HapticFeedback.generate(.light)
                        TR_AdCountViewModel.sharedd.registerTap {
                            navPath.append(HomeDestination.recentPlatforms)
                        }
                    }) {
                        Text("View All".localized)
                            .font(.inter(.semiBold, size: isIPad ? 14 : 13))
                            .foregroundColor(AppColors.primaryGreen)
                    }
                }
            }
            
            if accountManager.accounts.isEmpty {
                // Empty state matching Image 1
                VStack(spacing: isIPad ? 14 : 10.scaled) {
                    Image("ic_No_Platforms_Yet")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isIPad ? 90 : 70.scaled, height: isIPad ? 90 : 70.scaled)
                    
                    Text("No Platforms Yet".localized)
                        .font(.inter(.medium, size: isIPad ? 16 : 13))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIPad ? 32 : 24.scaled)
            } else {
                let displayedAccounts = Array(accountManager.accounts.prefix(10))
                
                VStack(spacing: isIPad ? 12 : 9.scaled) {
                    ForEach(displayedAccounts) { account in
                        RecentPlatformRow(
                            account: account,
                            colorScheme: colorScheme,
                            isIPad: isIPad,
                            onTap: {
                                HapticFeedback.generate(.light)
                                guard NetworkMonitor.shared.isNetworkAvailable else {
                                    showNoInternetAlert = true
                                    return
                                }
                                if !isPro {
                                    tabBarManager.isPaywallFromAppOpen = false
                                    tabBarManager.showPaywall = true
                                    return
                                }
                                accountManager.touch(account)
                                TR_AdCountViewModel.sharedd.registerTap {
                                    if account.platform == .whatsApp {
                                        if account.isSessionActive {
                                            navPath.append(HomeDestination.clone(platform: .whatsApp, accountId: account.id))
                                        } else {
                                            navPath.append(HomeDestination.webScanner(accountId: account.id))
                                        }
                                    } else {
                                        navPath.append(HomeDestination.clone(platform: account.platform, accountId: account.id))
                                    }
                                }
                            },
                            onDelete: {
                                accountToDelete = account
                                showDeleteConfirmation = true
                            },
                            onRename: {
                                accountToRename = account
                                let raw = account.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if raw.isEmpty || raw.starts(with: "-") || raw.contains("લૉગ ઇન") || raw.contains("સાઇન અપ") || raw.contains("Log in") || raw.contains("Sign in") {
                                    newAccountName = "\(account.platform.displayName) - 1"
                                } else {
                                    newAccountName = account.accountName
                                }
                                showRenameSheet = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func deleteAndLogoutAccount(_ account: AppAccount) {
        HapticFeedback.generate(.medium)
        accountManager.delete(id: account.id)
        if !accountManager.accounts.contains(where: { $0.platform == .whatsApp }) {
            UserDefaults.standard.set(false, forKey: "is_whatsapp_web_logged_in")
        }
        swipedAccountId = nil
    }
    
    private var isRenameValid: Bool {
        !newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Rename Sheet
    private var renameSheet: some View {
        VStack(spacing: 16) {
            Text("Rename Account".localized)
                .font(.inter(.bold, size: 18))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.top, 16)
            
            TextField("Account Name".localized, text: $newAccountName)
                .font(.inter(.medium, size: 16))
                .padding(12)
                .background(AppColors.cardBackground(for: colorScheme))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            HStack(spacing: 14) {
                Button("Cancel".localized) {
                    showRenameSheet = false
                }
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .glassCard(
                    cornerRadius: 12.scaled,
                    color: colorScheme == .dark ? Color.clear : Color.clear
                )
                
                Button("Update".localized) {
                    let trimmed = newAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if var acc = accountToRename {
                        acc.accountName = trimmed
                        accountManager.update(acc)
                    }
                    showRenameSheet = false
                }
                .font(.inter(.bold, size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isRenameValid ? AppColors.primaryGreen : AppColors.primaryGreen.opacity(0.4))
                .cornerRadius(12)
                .disabled(!isRenameValid)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(
            AppColors.background(for: colorScheme)
                .ignoresSafeArea(edges: .bottom)
        )
        .presentationDetents([.height(isIPad ? 210 : 170)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - RecentPlatformRow with 100% Native Fluid Scroll & Context Menu (Rename / Delete)
public struct RecentPlatformRow: View {
    let account: AppAccount
    let colorScheme: ColorScheme
    let isIPad: Bool
    var isEditing: Bool = false
    let onTap: () -> Void
    var onDelete: (() -> Void)? = nil
    var onRename: (() -> Void)? = nil
    
    var isSwiped: Bool = false
    var onSwipe: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    
    public init(
        account: AppAccount,
        colorScheme: ColorScheme,
        isIPad: Bool,
        isEditing: Bool = false,
        isSwiped: Bool = false,
        onSwipe: (() -> Void)? = nil,
        onReset: (() -> Void)? = nil,
        onTap: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        onRename: (() -> Void)? = nil
    ) {
        self.account = account
        self.colorScheme = colorScheme
        self.isIPad = isIPad
        self.isEditing = isEditing
        self.isSwiped = isSwiped
        self.onSwipe = onSwipe
        self.onReset = onReset
        self.onTap = onTap
        self.onDelete = onDelete
        self.onRename = onRename
    }
    
    public var displayAccountName: String {
        let raw = account.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty || raw.starts(with: "-") || raw.contains("લૉગ ઇન") || raw.contains("સાઇન અપ") || raw.contains("Log in") || raw.contains("Sign in") {
            return AccountManager.shared.defaultAccountName(for: account.platform, accountId: account.id)
        }
        return raw
    }
    
    public var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: isIPad ? 16 : 12.scaled) {
                Image(account.platform.iconAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 46 : 38.scaled, height: isIPad ? 46 : 38.scaled)
                
                VStack(alignment: .leading, spacing: 3.scaled) {
                    Text(displayAccountName)
                        .font(.inter(.semiBold, size: isIPad ? 17 : 14))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    
                    Text(account.timeAgoFormatted)
                        .font(.inter(.regular, size: isIPad ? 13 : 11))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: isIPad ? 15 : 12.scaled, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            .padding(.horizontal, isIPad ? 18 : 14.scaled)
            .padding(.vertical, isIPad ? 14 : 10.scaled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 16.scaled)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
        .contextMenu {
            if let onRename = onRename {
                Button {
                    onRename()
                } label: {
                    Label("Rename".localized, systemImage: "pencil")
                }
            }
            
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete".localized, systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
}
