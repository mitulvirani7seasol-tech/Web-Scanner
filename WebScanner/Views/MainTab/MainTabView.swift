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
    
    public init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        let unselectedColor = UIColor(red: 122/255, green: 122/255, blue: 122/255, alpha: 1.0)
        let selectedColor = UIColor(red: 5/255, green: 151/255, blue: 77/255, alpha: 1.0)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = unselectedColor
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]
        itemAppearance.selected.iconColor = selectedColor
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    public var body: some View {
        TabView(selection: selectedTabBinding) {
            HomeView(selectedTab: selectedTabBinding)
                .tabItem {
                    Image(tabBarManager.selectedTab == 0 ? "Home_Selected" : "Home_Unselect")
                        .renderingMode(.template)
                    Text("Home".localized)
                }
                .tag(0)
                .toolbar(tabBarManager.isHidden ? .hidden : .visible, for: .tabBar)
            
            DirectChatView()
                .tabItem {
                    Image(tabBarManager.selectedTab == 1 ? "Chat_Selected" : "Chat_Unselect")
                        .renderingMode(.template)
                    Text("Direct Chat".localized)
                }
                .tag(1)
                .toolbar(tabBarManager.isHidden ? .hidden : .visible, for: .tabBar)
            
            SettingsView()
                .tabItem {
                    Image(tabBarManager.selectedTab == 2 ? "Setting_Selected" : "Setting_Unselect")
                        .renderingMode(.template)
                    Text("Settings".localized)
                }
                .tag(2)
                .toolbar(tabBarManager.isHidden ? .hidden : .visible, for: .tabBar)
        }
        .environment(\.horizontalSizeClass, .compact)
        .tint(AppColors.primaryGreen)
        .toolbar(tabBarManager.isHidden ? .hidden : .visible, for: .tabBar)
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
        
        let isUserPro = isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
        if !isUserPro {
            if !WS_AppSession.shared.hasShownPremium && isShowPremium.lowercased() != "false" {
                WS_AppSession.shared.hasShownPremium = true
                tabBarManager.isPaywallFromAppOpen = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    let stillPro = self.isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
                    guard !stillPro else { return }
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
    
}

#Preview {
    MainTabView()
}
