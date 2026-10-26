//
//  SplashScreenView.swift
//  WebScanner
//

import SwiftUI
import Lottie

public struct SplashScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isActive: Bool
    
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    
    @State private var showSplashContent: Bool = false
    @State private var logoScale: CGFloat = 0.82
    @State private var logoOpacity: Double = 0.0
    
    @State private var hasPresentedAd: Bool = false
    @State private var hasStartedSplashAnimation: Bool = false
    @State private var hasCompleted: Bool = false
    @State private var timeoutWorkItem: DispatchWorkItem? = nil
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(isActive: Binding<Bool>) {
        self._isActive = isActive
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dynamic Background Image (Clamped to device dimensions)
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                // Centered App Logo & Title (Appears AFTER Open App Ad)
                if showSplashContent {
                    VStack(spacing: isIPad ? 24 : 16) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 170 : 130, height: isIPad ? 170 : 130)
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 12, x: 0, y: 6)
                        
                        Text("Web Scanner".localized)
                            .font(.inter(.bold, size: isIPad ? 32 : 24))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .transition(.opacity)
                    
                    // Bottom Pinned Loader
                    VStack {
                        Spacer()
                        
                        LottieView(
                            animationName: "Loading",
                            loopMode: .loop,
                            isDarkMode: colorScheme == .dark
                        )
                            .frame(width: isIPad ? 130 : 100, height: isIPad ? 130 : 100)
                            .padding(.bottom, isIPad ? max(geo.safeAreaInsets.bottom, 36) + 24 : max(geo.safeAreaInsets.bottom, 20) + 20)
                    }
                    .opacity(logoOpacity)
                    .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            startInitialFlow()
        }
    }
    
    // MARK: - Initial Flow: Open App Ad FIRST -> Splash Screen -> Continue Flow
    private func startInitialFlow() {
        TR_AdCountViewModel.sharedd.reloadAd()
        
        if isPro {
            startSplashAnimation()
            return
        }
        
        // When there is NO internet, ads cannot load, so show splash animation for 2.0s then proceed to App/Paywall
        if !TR_AdsManager.isConnectedToNetwork() {
            print("🌐 [SplashScreenView] Offline launch -> Showing splash for 2.0s then navigating to app/paywall...")
            startSplashAnimation()
            return
        }
        
        // Cancellable 6.0s timeout fallback for slow internet
        let workItem = DispatchWorkItem {
            // NEVER interrupt if an ad is actively showing on screen or splash already running
            if TR_AppOpenAdManager.shared.isShowingAd || TR_AppOpenBackAdManager.shared.isShowingAd || self.hasPresentedAd || self.hasStartedSplashAnimation || self.hasCompleted {
                print("⏱️ [SplashScreenView] 6.0s timeout ignored because Open App Ad is actively showing.")
                return
            }
            print("⏱️ [SplashScreenView] 6.0s slow internet timeout reached without ad -> Starting splash animation.")
            self.startSplashAnimation()
        }
        self.timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: workItem)
        
        print("🌐 [SplashScreenView] Fetching remote config for initial Open App Ad...")
        WS_AppConsentManager.shared.fetchRemoteConfiguration {
            Task {
                await loadAndShowOpenAppAd()
            }
        }
    }
    
    private func loadAndShowOpenAppAd() async {
        guard !hasStartedSplashAnimation, !hasCompleted else { return }
        
        if isPro || !TR_AdsManager.isConnectedToNetwork() {
            await MainActor.run { startSplashAnimation() }
            return
        }
        
        let isHomeOpened = UserDefaults.standard.bool(forKey: WS_SessionKeys.isHomeOpened)
        if isHomeOpened {
            TR_AppOpenBackAdManager.shared.resetForForeground()
            await TR_AppOpenBackAdManager.shared.loadAd()
            
            await MainActor.run {
                guard !hasStartedSplashAnimation, !hasCompleted else { return }
                guard TR_AppOpenBackAdManager.shared.appOpenAd != nil else {
                    print("⚠️ [SplashScreenView] No App Open Back ad available -> Showing splash screen.")
                    startSplashAnimation()
                    return
                }
                
                // Cancel timeout so ad is NEVER prematurely dismissed!
                timeoutWorkItem?.cancel()
                timeoutWorkItem = nil
                hasPresentedAd = true
                print("🎬 [SplashScreenView] Presenting App Open Back ad FIRST (waiting indefinitely for user to tap Continue to app)...")
                TR_AppOpenBackAdManager.shared.showAdIfAvailable {
                    print("✅ [SplashScreenView] User manually dismissed Open App Ad. Now showing splash screen...")
                    TR_AppOpenBackAdManager.shared.isShowingAd = false
                    TR_AppOpenAdManager.shared.isShowingAd = false
                    startSplashAnimation()
                }
            }
        } else {
            TR_AppOpenAdManager.shared.resetForForeground()
            await TR_AppOpenAdManager.shared.loadAd()
            
            await MainActor.run {
                guard !hasStartedSplashAnimation, !hasCompleted else { return }
                guard TR_AppOpenAdManager.shared.appOpenAd != nil else {
                    print("⚠️ [SplashScreenView] No App Open ad available -> Showing splash screen.")
                    startSplashAnimation()
                    return
                }
                
                // Cancel timeout so ad is NEVER prematurely dismissed!
                timeoutWorkItem?.cancel()
                timeoutWorkItem = nil
                hasPresentedAd = true
                print("🎬 [SplashScreenView] Presenting App Open ad FIRST (waiting indefinitely for user to tap Continue to app)...")
                TR_AppOpenAdManager.shared.showAdIfAvailable {
                    print("✅ [SplashScreenView] User manually dismissed Open App Ad. Now showing splash screen...")
                    TR_AppOpenBackAdManager.shared.isShowingAd = false
                    TR_AppOpenAdManager.shared.isShowingAd = false
                    startSplashAnimation()
                }
            }
        }
    }
    
    // MARK: - Splash Screen Animation Phase
    private func startSplashAnimation() {
        // Never start splash animation if an ad is actively displaying to the user!
        if TR_AppOpenAdManager.shared.isShowingAd || TR_AppOpenBackAdManager.shared.isShowingAd {
            print("⛔ [SplashScreenView] Open App Ad is actively showing! Blocking startSplashAnimation.")
            return
        }
        
        guard !hasStartedSplashAnimation, !hasCompleted else { return }
        hasStartedSplashAnimation = true
        
        withAnimation(.easeOut(duration: 0.6)) {
            showSplashContent = true
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            safeFinishSplash()
        }
    }
    
    private func safeFinishSplash() {
        // Never dismiss splash screen if an ad is actively displaying to the user!
        if TR_AppOpenAdManager.shared.isShowingAd || TR_AppOpenBackAdManager.shared.isShowingAd {
            print("⛔ [SplashScreenView] Open App Ad is actively showing! Blocking safeFinishSplash.")
            return
        }
        
        guard !hasCompleted else { return }
        hasCompleted = true
        WS_AppSession.shared.isSplashCompleted = true
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                isActive = false
            }
        }
    }
}

#Preview {
    SplashScreenView(isActive: .constant(true))
}
