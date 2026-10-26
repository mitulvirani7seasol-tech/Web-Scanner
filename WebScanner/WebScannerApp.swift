//
//  WebScannerApp.swift
//  WebScanner
//
//  Created by Kushang kaklotar on 17/10/26.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            return .portrait
        }
    }
}

@main
struct WebScannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared
    
    let adCountViewModel = TR_AdCountViewModel.sharedd
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasInBackground = false
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    
    init() {
        AdOrientationManager.shared.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(adCountViewModel)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .onOpenURL { url in
                    if url.scheme?.lowercased() == "webscanner" {
                        ChatBackupManager.shared.loadConversations()
                        if url.host == "openChatFromShare" || url.absoluteString.contains("openChatFromShare") {
                            ChatBackupManager.shared.clearPendingSharedChatFlags()
                            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                            let targetName = components?.queryItems?.first(where: { $0.name == "name" })?.value
                            let target = ChatBackupManager.shared.conversations.first(where: {
                                if let targetName = targetName, !targetName.isEmpty {
                                    return $0.name == targetName || $0.id == targetName || $0.folderURL.lastPathComponent == targetName
                                }
                                return false
                            }) ?? ChatBackupManager.shared.conversations.first
                            
                            if let target = target {
                                TabBarManager.shared.navigateDirectlyToChat(target)
                            } else {
                                TabBarManager.shared.navigateToBackupChats()
                            }
                        } else if url.host == "openContactDetails" || url.absoluteString.contains("openContactDetails") {
                            let target = ChatBackupManager.shared.conversations.first
                            if let target = target {
                                TabBarManager.shared.navigateDirectlyToChat(target)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    NotificationCenter.default.post(name: NSNotification.Name("OpenContactDetailsNotification"), object: nil)
                                }
                            }
                        } else if url.host == "openImportSheet" || url.absoluteString.contains("openImportSheet") {
                            TabBarManager.shared.navigateToBackupChats()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                TabBarManager.shared.shouldShowImportSheet = true
                            }
                        } else if url.host == "setLanguage" || url.absoluteString.contains("setLanguage") {
                            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                                LocalizationHelper.shared.setLanguage(code: code)
                            }
                        } else if url.host == "directChat" || url.absoluteString.contains("directChat") {
                            TabBarManager.shared.selectedTab = 1
                        } else {
                            TabBarManager.shared.navigateToBackupChats()
                        }
                    } else if url.isFileURL {
                        Task { @MainActor in
                            if let newConv = try? await ChatBackupManager.shared.importChatFile(from: url) {
                                ChatBackupManager.shared.loadConversations()
                                TabBarManager.shared.navigateDirectlyToChat(newConv)
                            } else {
                                ChatBackupManager.shared.loadConversations()
                                if let first = ChatBackupManager.shared.conversations.first {
                                    TabBarManager.shared.navigateDirectlyToChat(first)
                                } else {
                                    TabBarManager.shared.navigateToBackupChats()
                                }
                            }
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                // Only allow wasInBackground if splash has already completed AND no ad or paywall is displaying
                guard WS_AppSession.shared.isSplashCompleted else {
                    print("⛔ Splash not yet completed → do not mark wasInBackground")
                    return
                }
                if TR_AppOpenAdManager.shared.isShowingAd || TR_AppOpenBackAdManager.shared.isShowingAd || TR_AdState.shared.isShowingInterstitial || UIApplication.isAdOrPremiumPresented {
                    print("⛔ Ad or Premium is showing → do not mark wasInBackground")
                    return
                }
                print("📴 App went to background")
                wasInBackground = true
                
            case .active:
                print("🔄 App became active")
                guard wasInBackground, WS_AppSession.shared.isSplashCompleted else { return }
                wasInBackground = false
                
                if isPro {
                    print("🚫 Pro user → skip AppOpen ad")
                    return
                }
                if TR_AdState.shared.isShowingInterstitial || UIApplication.isAdOrPremiumPresented {
                    print("⛔ Interstitial running or Premium view open → skip AppOpen")
                    return
                }
                if TR_AppOpenAdManager.shared.isShowingAd || TR_AppOpenBackAdManager.shared.isShowingAd {
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        guard !UIApplication.isAdOrPremiumPresented else { return }
                        let isHomeOpened = UserDefaults.standard.bool(forKey: WS_SessionKeys.isHomeOpened)
                        if isHomeOpened {
                            print("Foreground: HomeScreen opened → load regular app open ad")
                            TR_AppOpenBackAdManager.shared.resetForForeground()
                            await TR_AppOpenBackAdManager.shared.loadAd()
                            TR_AppOpenBackAdManager.shared.showAdIfAvailable { }
                        } else {
                            print("Foreground: HomeScreen NOT opened → load second app open ad")
                            TR_AppOpenAdManager.shared.resetForForeground()
                            await TR_AppOpenAdManager.shared.loadAd()
                            TR_AppOpenAdManager.shared.showAdIfAvailable { }
                        }
                    }
                }
            default:
                break
            }
        }
    }
}

