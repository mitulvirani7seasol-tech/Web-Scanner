//
//  ContentView.swift
//  WebScanner
//
//  Created by Kushang kaklotar on 17/10/26.
//

import SwiftUI

enum AppFlowState {
    case consent
    case splash
    case language
    case intro
    case main
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var passcodeManager = PasscodeManager.shared
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    
    @AppStorage("hasCompletedConsent") private var hasCompletedConsent: Bool = false
    @AppStorage("hasSelectedLanguage") private var hasSelectedLanguage: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var isSplashActive: Bool = true
    @State private var currentFlow: AppFlowState
    
    init() {
        let completedConsent = UserDefaults.standard.bool(forKey: "hasCompletedConsent")
        _currentFlow = State(initialValue: completedConsent ? .splash : .consent)
    }
    
    var body: some View {
        ZStack {
            switch currentFlow {
            case .consent:
                ZStack {
                    Image(colorScheme == .dark ? "BG_Dark" : "BG")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                    
                    ConsentHandlerView {
                        print("🎉 [ContentView] Consent & ATT finished on fresh install. Transitioning to splash screen...")
                        hasCompletedConsent = true
                        withAnimation(.easeInOut(duration: 0.35)) {
                            currentFlow = .splash
                        }
                    }
                }
                .transition(.opacity)
                .zIndex(250)
                
            case .splash:
                SplashScreenView(isActive: $isSplashActive)
                    .transition(.opacity)
                    .zIndex(200)
                
            case .language:
                LanguageSelectionView(isInitialFlow: true) {
                    hasSelectedLanguage = true
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentFlow = .intro
                    }
                }
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                .zIndex(150)
                
            case .intro:
                IntroView {
                    hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentFlow = .main
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                .zIndex(100)
                
            case .main:
                MainTabView()
                    .transition(.opacity)
                
                // Passcode Security Overlay
                if passcodeManager.isPasscodeEnabled && !passcodeManager.isAppUnlocked {
                    PasscodeLockOverlayView()
                        .transition(.opacity)
                        .zIndex(300)
                }
            }
        }
        .ignoresSafeArea()
        .id(localizationHelper.refreshID)
        .animation(.easeInOut(duration: 0.35), value: currentFlow)
        .onChange(of: isSplashActive) { active in
            if !active {
                determineNextFlow()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                passcodeManager.lockApp()
            } else if newPhase == .active {
                checkPendingSharedBackup()
            }
        }
        .onAppear {
            checkPendingSharedBackup()
        }
    }
    
    private func checkPendingSharedBackup() {
        guard let chatName = ChatBackupManager.shared.consumePendingSharedChat(), !chatName.isEmpty else {
            return
        }
        
        ChatBackupManager.shared.loadConversations()
        let target = ChatBackupManager.shared.conversations.first(where: {
            $0.name == chatName || $0.id == chatName || $0.folderURL.lastPathComponent == chatName
        })
        
        if let target = target {
            TabBarManager.shared.navigateDirectlyToChat(target)
        } else {
            TabBarManager.shared.navigateToBackupChats()
        }
    }
    
    private func determineNextFlow() {
        withAnimation(.easeInOut(duration: 0.35)) {
            if !hasSelectedLanguage {
                currentFlow = .language
            } else if !hasCompletedOnboarding {
                currentFlow = .intro
            } else {
                currentFlow = .main
            }
        }
    }
}

#Preview {
    ContentView()
}
