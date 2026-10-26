//
//  WS_AppConsentManager.swift
//  WebScanner
//
//  Created by Kushang kaklotar on 24/10/26.
//

import Foundation
import UIKit
import Combine
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

@MainActor
final class WS_AppConsentManager: NSObject, ObservableObject {
    static let shared = WS_AppConsentManager()
    
    @Published var isConsentCompleted: Bool = false
    @Published var isAdsInitialized: Bool = false
    @Published var hasLoadedRemoteConfig: Bool = false
    
    private var isRequestInProgress: Bool = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - Main Entry Point: Request UMP Consent -> ATT Dialog -> Start Ads -> Callback
    func requestConsentAndTracking(from viewController: UIViewController? = nil, completion: @escaping () -> Void) {
        guard !isRequestInProgress else {
            print("⏳ Consent and ATT request is already in progress")
            return
        }
        
        // If no internet connection, skip consent and return immediately
        guard TR_AdsManager.isConnectedToNetwork() else {
            print("⚠️ No internet connection. Skipping consent and ATT.")
            completion()
            return
        }
        
        isRequestInProgress = true
        
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        
        #if DEBUG
        let debugSettings = DebugSettings()
        debugSettings.geography = .EEA
        parameters.debugSettings = debugSettings
        #endif
        
        print("📋 Requesting UMP Consent info update...")
        
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("⚠️ UMP Consent info update failed: \(error.localizedDescription)")
                    self.handleConsentFinished(completion: completion)
                    return
                }
                
                let presentingVC = viewController ?? UIApplication.shared.topPresentedViewController
                
                print("📋 UMP Consent info updated. Form status: \(ConsentInformation.shared.formStatus.rawValue), status: \(ConsentInformation.shared.consentStatus.rawValue)")
                
                ConsentForm.loadAndPresentIfRequired(from: presentingVC) { [weak self] formError in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        
                        if let formError = formError {
                            print("⚠️ UMP Consent Form load/present failed: \(formError.localizedDescription)")
                        } else {
                            print("✅ UMP Consent Form dismissed/handled successfully.")
                        }
                        
                        self.handleConsentFinished(completion: completion)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Request App Tracking Transparency (ATT)
    private func handleConsentFinished(completion: @escaping () -> Void) {
        self.requestTrackingAuthorizationIfNeeded { [weak self] in
            guard let self = self else { return }
            self.isConsentCompleted = true
            self.isRequestInProgress = false
            completion()
        }
    }
    
    private func requestTrackingAuthorizationIfNeeded(completion: @escaping () -> Void) {
        if #available(iOS 14.5, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    print("🎯 Presenting AppTrackingTransparency (ATT) popup...")
                    ATTrackingManager.requestTrackingAuthorization { authStatus in
                        print("🎯 ATT Authorization result: \(authStatus.rawValue)")
                        DispatchQueue.main.async {
                            completion()
                        }
                    }
                }
                return
            }
        }
        completion()
    }
    
    // MARK: - Remote Configuration Fetch from AWS S3 JSON
    func fetchRemoteConfiguration(completion: @escaping () -> Void) {
        guard let url = URL(string: getJSON) else {
            completion()
            return
        }
        
        // Fast return if no internet connection
        guard TR_AdsManager.isConnectedToNetwork() else {
            print("⚠️ No internet connection. Skipping remote configuration fetch.")
            self.initializeMobileAds()
            completion()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 6.0
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        sessionConfiguration.urlCache = nil
        sessionConfiguration.timeoutIntervalForRequest = 6.0
        sessionConfiguration.timeoutIntervalForResource = 6.0
        
        var hasCompleted = false
        let safeCompletion = {
            if !hasCompleted {
                hasCompleted = true
                completion()
            }
        }
        
        let session = URLSession(configuration: sessionConfiguration)
        let requestTask = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ S3 API Error:", error.localizedDescription)
                DispatchQueue.main.async {
                    self?.initializeMobileAds()
                    safeCompletion()
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.initializeMobileAds()
                    safeCompletion()
                }
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 [getJSON] API Response:\n\(jsonString)")
            }
            
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        self?.hasLoadedRemoteConfig = true
                    }
                    if let appOpen = responseJSON["appopenId"] as? String, !appOpen.isEmpty { appopenId = appOpen }
                    if let native = responseJSON["nativeId"] as? String, !native.isEmpty { nativeId = native }
                    if let inter = responseJSON["interstialId"] as? String, !inter.isEmpty { interstialId = inter }
                    if let banner = responseJSON["bannerId"] as? String, !banner.isEmpty { bannerId = banner }
                    if let reward = responseJSON["rewardId"] as? String, !reward.isEmpty { rewardId = reward }
                    if let btnColor = responseJSON["addButtonColor"] as? String, !btnColor.isEmpty { addButtonColor = btnColor }
                    
                    let configuration = (responseJSON["extraFields"] as? [String: Any]) ?? (responseJSON["configuration"] as? [String: Any]) ?? responseJSON
                    
                    small_native = configuration["small_native"] as? String ?? (responseJSON["customBanner"] as? String ?? (responseJSON["bannerId"] as? String ?? ""))
                    second_small_native = configuration["second_small_native"] as? String ?? (responseJSON["secBannerId"] as? String ?? (responseJSON["customBanner"] as? String ?? ""))
                    second_native = configuration["second_native"] as? String ?? (responseJSON["secNativeId"] as? String ?? (responseJSON["customNative"] as? String ?? ""))
                    second_appopen = configuration["second_appopen"] as? String ?? (responseJSON["secAppopenId"] as? String ?? (responseJSON["customAppOpen"] as? String ?? ""))
                    androidBannerUrl = configuration["splash_banner"] as? String ?? androidBannerUrl
                    
                    if let val = configuration["iapLifetime"] { iapLifetime = "\(val)" }
                    else if let val = configuration["lifeTime_plan"] { iapLifetime = "\(val)" }
                    else { iapLifetime = "false" }
                    
                    if let val = configuration["iapYearlyPlan"] { iapYearlyPlan = "\(val)" }
                    else if let val = configuration["yearly_plan"] { iapYearlyPlan = "\(val)" }
                    else { iapYearlyPlan = "false" }
                    
                    if let val = configuration["iapMonthlyPlan"] { iapMonthlyPlan = "\(val)" }
                    else if let val = configuration["monthly_plan"] { iapMonthlyPlan = "\(val)" }
                    else { iapMonthlyPlan = "false" }
                    
                    if let val = configuration["iapWeeklyPlan"] { iapWeeklyPlan = "\(val)" }
                    else if let val = configuration["weekly_plan"] { iapWeeklyPlan = "\(val)" }
                    else { iapWeeklyPlan = "false" }
                    
                    print("📊 [getJSON] Active Plans Configuration:")
                    print("   - iapLifetime: \(iapLifetime)")
                    print("   - iapYearlyPlan: \(iapYearlyPlan)")
                    print("   - iapMonthlyPlan: \(iapMonthlyPlan)")
                    print("   - iapWeeklyPlan: \(iapWeeklyPlan)")
                    print("   - isShowPremium: \(configuration["isShowPremium"] ?? "true")")
                    
                    isShowPremium = configuration["isShowPremium"] as? String ?? (responseJSON["isShowPremium"] as? String ?? "true")
                    
                    let isPremClose = (configuration["pro_close_inter"] as? String == "true") ||
                                      (configuration["pro_close_inter"] as? Bool == true) ||
                                      (configuration["premium_close"] as? String == "true") ||
                                      (configuration["premium_close"] as? Bool == true) ||
                                      (responseJSON["pro_close_inter"] as? String == "true") ||
                                      (responseJSON["pro_close_inter"] as? Bool == true) ||
                                      (responseJSON["premium_close"] as? String == "true") ||
                                      (responseJSON["premium_close"] as? Bool == true)
                    pro_close_inter = isPremClose ? "true" : "false"
                    
                    if let closeTimeStr = (configuration["premium_close_time"] as? String) ?? (responseJSON["premium_close_time"] as? String),
                       let closeTimeVal = Double(closeTimeStr) {
                        premiumCloseTime = closeTimeVal
                    } else if let closeTimeNum = (configuration["premium_close_time"] as? Double) ?? (responseJSON["premium_close_time"] as? Double) {
                        premiumCloseTime = closeTimeNum
                    } else if let closeTimeInt = (configuration["premium_close_time"] as? Int) ?? (responseJSON["premium_close_time"] as? Int) {
                        premiumCloseTime = Double(closeTimeInt)
                    } else {
                        premiumCloseTime = 2.0
                    }
                    
 
                    freeLimitCount = configuration["freeLimitCount"] as? String ?? "10"
                    
                    let customInterstitialCount = responseJSON["customInterstial"] as? Int ?? 0
                    
                    if let afterClickValue = responseJSON["afterClick"] as? String,
                       let clickCount = Int(afterClickValue) {
                        adsCount = clickCount
                    } else if let afterClickInt = responseJSON["afterClick"] as? Int {
                        adsCount = afterClickInt
                    } else {
                        adsCount = 4
                    }
                    
                    adsPlus = customInterstitialCount == 0 ? max(1, adsCount - 1) : adsCount
                    
                    DispatchQueue.main.async {
                        TR_AdCountViewModel.sharedd.afterClick = adsCount
                        print("==================================================")
                        print("📡 Remote Config API Response Loaded Successfully:")
                        print("   🔹 [Fresh Install / Before Home Ad IDs]:")
                        print("      - second_native:        \(second_native)")
                        print("      - second_small_native:  \(second_small_native)")
                        print("      - second_appopen:       \(second_appopen)")
                        print("   🔹 [Regular / After Home Ad IDs]:")
                        print("      - nativeId:             \(nativeId)")
                        print("      - small_native:         \(small_native)")
                        print("      - appopenId:            \(appopenId)")
                        print("      - interstialId:         \(interstialId)")
                        print("      - bannerId:             \(bannerId)")
                        print("   🔹 [Settings]:")
                        print("      - afterClick:           \(adsCount)")
                        print("      - isShowPremium:        \(isShowPremium)")
                        print("==================================================")
                    }
                }
                DispatchQueue.main.async { safeCompletion() }
            } catch {
                print("❌ S3 JSON Parse Error:", error.localizedDescription)
                DispatchQueue.main.async { safeCompletion() }
            }
        }
        requestTask.resume()
    }
    
    // MARK: - Initialize Google Mobile Ads SDK
    private func initializeMobileAds() {
        if ConsentInformation.shared.canRequestAds {
            if !isAdsInitialized {
                print("🚀 Initializing Google Mobile Ads SDK...")
                MobileAds.shared.start { status in
                    print("✅ Google Mobile Ads initialized.")
                }
                isAdsInitialized = true
                TR_AdCountViewModel.sharedd.reloadAd()
            }
        } else {
            print("ℹ️ Ads cannot be requested per UMP consent.")
        }
    }
}

// MARK: - UIApplication & UIViewController Top-Most Helper
extension UIApplication {
    var topPresentedViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostViewController
    }
}

extension UIViewController {
    var topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostViewController
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController
        }
        return self
    }
}

// MARK: - SwiftUI Bridge for Consent Presentation
import SwiftUI

public struct ConsentHandlerView: UIViewControllerRepresentable {
    public let onCompletion: () -> Void
    
    public init(onCompletion: @escaping () -> Void) {
        self.onCompletion = onCompletion
    }
    
    public func makeUIViewController(context: Context) -> ConsentViewController {
        let vc = ConsentViewController()
        vc.onCompletion = onCompletion
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: ConsentViewController, context: Context) {}
}

public final class ConsentViewController: UIViewController {
    var onCompletion: (() -> Void)?
    private var hasTriggered = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasTriggered else { return }
        hasTriggered = true
        
        WS_AppConsentManager.shared.requestConsentAndTracking(from: self) { [weak self] in
            self?.onCompletion?()
        }
    }
}
