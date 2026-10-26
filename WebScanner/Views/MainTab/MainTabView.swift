//
//  MainTabView.swift
//  WebScanner
//

import SwiftUI
import StoreKit

public struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    @ObservedObject private var tabBarManager = TabBarManager.shared
    @ObservedObject private var passcodeManager = PasscodeManager.shared
    @ObservedObject private var updateManager = TR_AppUpdateManager.shared
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    @State private var isPresentPremium: Bool = false
    @State private var showRateAlert: Bool = false
    
    private var selectedTabBinding: Binding<Int> {
        Binding(
            get: { tabBarManager.selectedTab },
            set: { tabBarManager.selectedTab = $0 }
        )
    }
    
    public init() {}
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Full Screen Background (Seamless across tab switches)
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                // Tab Content
                Group {
                    switch tabBarManager.selectedTab {
                    case 0:
                        HomeView(selectedTab: selectedTabBinding)
                    case 1:
                        DirectChatView()
                    case 2:
                        SettingsView()
                    default:
                        HomeView(selectedTab: selectedTabBinding)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Floating Liquid Glass Tab Bar (Hidden on detail screens)
                if !tabBarManager.isHidden {
                    customTabBar(bottomInset: geo.safeAreaInsets.bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: tabBarManager.isHidden)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(edges: .bottom)
        .id(localizationHelper.refreshID)
        .fullScreenCover(isPresented: $isPresentPremium, onDismiss: {
            checkUpdateThenRate()
        }) {
            PremiumPaywallView(isFromAppOpen: tabBarManager.isPaywallFromAppOpen) {
                isPresentPremium = false
                tabBarManager.showPaywall = false
                checkUpdateThenRate()
            }
        }
        .alert(
            "Update Available".localized,
            isPresented: $updateManager.showUpdateAlert
        ) {
            Button("Update Now".localized) {
                updateManager.openAppStore()
                handlePostReviewLogic()
            }
            Button("Later".localized, role: .cancel) {
                handlePostReviewLogic()
            }
        } message: {
            Text("A new version of our app is available on the App Store. Please update for the best experience.".localized)
        }
        .alert("Do you like our App?".localized, isPresented: $showRateAlert) {
            Button("No".localized + " ❌", role: .cancel) {
            }
            Button("Yes".localized + " 👍") {
                UserDefaults.standard.set(true, forKey: "IsRatingShown")
                UserDefaults.standard.set(true, forKey: "didAskForReview")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    rateApp()
                }
            }
        } message: {
            Text("Help us improve it app by answering this quick poll".localized)
        }
        .onChange(of: tabBarManager.showPaywall) { show in
            if show {
                isPresentPremium = true
            }
        }
        .onChange(of: passcodeManager.isAppUnlocked) { unlocked in
            if unlocked {
                handleStartupFlow()
            }
        }
        .onAppear {
            UserDefaults.standard.set(true, forKey: WS_SessionKeys.isHomeOpened)
            if tabBarManager.selectedTab == 0 && !tabBarManager.shouldNavigateToBackupChats {
                tabBarManager.selectedTab = 0
            }
            handleStartupFlow()
        }
    }
    
    // MARK: - Startup Sequencing (Paywall -> Version Update -> Rate Popup)
    private func handleStartupFlow() {
        updateManager.checkForUpdate()
        
        if passcodeManager.isPasscodeEnabled && !passcodeManager.isAppUnlocked {
            return
        }
        
        if !isPro {
            if !WS_AppSession.shared.hasShownPremium && isShowPremium.lowercased() != "false" {
                WS_AppSession.shared.hasShownPremium = true
                tabBarManager.isPaywallFromAppOpen = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    guard !self.isPro else { return }
                    self.tabBarManager.showPaywall = true
                    self.isPresentPremium = true
                }
            } else {
                checkUpdateThenRate()
            }
        } else {
            checkUpdateThenRate()
        }
    }

    private func checkUpdateThenRate() {
        guard !WS_AppSession.shared.hasPromptedUpdateAlert else {
            handlePostReviewLogic()
            return
        }
        WS_AppSession.shared.hasPromptedUpdateAlert = true

        updateManager.checkForUpdate { isAvailable in
            if isAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.updateManager.showUpdateAlert = true
                }
            } else {
                self.handlePostReviewLogic()
            }
        }
    }

    // MARK: - Post Review & App Rating Handlers
    private func handlePostReviewLogic() {
        guard !WS_AppSession.shared.hasShownRate else { return }
        WS_AppSession.shared.hasShownRate = true

        let didAskForReview = UserDefaults.standard.bool(forKey: "didAskForReview") || UserDefaults.standard.bool(forKey: "IsRatingShown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if didAskForReview {
                self.rateApp()
            } else {
                self.showRateAlert = true
            }
        }
    }

    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    // MARK: - Custom Liquid Glass Tab Bar
    private func customTabBar(bottomInset: CGFloat) -> some View {
        HStack(spacing: 0) {
            tabBarItem(
                index: 0,
                title: "Home",
                selectedImage: "Home_Selected",
                unselectedImage: "Home_Unselect"
            )
            
            tabBarItem(
                index: 1,
                title: "Direct Chat",
                selectedImage: "Chat_Selected",
                unselectedImage: "Chat_Unselect"
            )
            
            tabBarItem(
                index: 2,
                title: "Settings",
                selectedImage: "Setting_Selected",
                unselectedImage: "Setting_Unselect"
            )
        }
        .padding(.horizontal, isIPad ? 28 : 16.scaled)
        .padding(.vertical, isIPad ? 10 : 8.scaled)
        .glassCard(
            cornerRadius: 32.scaled,
            color: colorScheme == .dark ? Color.clear : Color.clear
        )
        .padding(.horizontal, isIPad ? 36 : 24.scaled)
        .padding(.bottom, max(bottomInset, isIPad ? 32 : 24))
        .frame(maxWidth: isIPad ? 520 : .infinity)
    }
    
    private func tabBarItem(index: Int, title: String, selectedImage: String, unselectedImage: String) -> some View {
        let isSelected = (tabBarManager.selectedTab == index)
        let capsuleWidth: CGFloat = isIPad ? 84 : 50.scaled
        let capsuleHeight: CGFloat = isIPad ? 56 : 36.scaled
        
        return Button(action: {
            HapticFeedback.generate(.selection)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                tabBarManager.selectedTab = index
            }
        }) {
            VStack(spacing: isIPad ? 5 : 4.scaled) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(AppColors.primaryGreen)
                            .frame(width: capsuleWidth, height: capsuleHeight)
                            .transition(.scale.combined(with: .opacity))
                        
                        Image(selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 36 : 24.scaled, height: isIPad ? 36 : 24.scaled)
                    } else {
                        Image(unselectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 36 : 24.scaled, height: isIPad ? 36 : 24.scaled)
                            .frame(width: capsuleWidth, height: capsuleHeight)
                    }
                }
                .frame(width: capsuleWidth, height: capsuleHeight)
                
                Text(title)
                    .font(.inter(isSelected ? .bold : .medium, size: isIPad ? 13 : 11))
                    .foregroundColor(isSelected ? AppColors.primaryGreen : Color(hex: "#7A7A7A"))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.94))
    }
}

#Preview {
    MainTabView()
}
