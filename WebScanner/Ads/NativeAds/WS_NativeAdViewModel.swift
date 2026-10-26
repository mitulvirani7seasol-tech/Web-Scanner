//
//  WS_NativeAdViewModel.swift
//  WebScanner
//
//

import Foundation
import SwiftUI
import GoogleMobileAds
import UIKit
import Combine

typealias TR_NativeAdViewModel = WS_NativeAdViewModel
typealias SM_NativeAdViewModel = WS_NativeAdViewModel

final class WS_NativeAdViewModel: NSObject, ObservableObject {
    @Published var nativeAd: NativeAd?
    @Published var smallNativeAd: NativeAd?
    @Published var secondNativeAd: NativeAd?
    @Published var secondSmallNativeAd: NativeAd?
    
    @Published var didFailToLoad: Bool = false
    @Published var didFailToSmallLoad: Bool = false
    @Published var didFailToSecondLoad: Bool = false
    @Published var didFailToSmallNativeLoad: Bool = false

    private var adLoader: AdLoader?
    private var smallAdLoader: AdLoader?
    private var secondAdLoader: AdLoader?
    private var secondSmallAdLoader: AdLoader?

    func refreshAd() {
        didFailToLoad = false
        nativeAd = nil

        let isHomeOpened = UserDefaults.standard.bool(forKey: WS_SessionKeys.isHomeOpened)
        let adUnit: String = {
            if !isHomeOpened {
                return !second_native.isEmpty ? second_native : (!nativeId.isEmpty ? nativeId : "ca-app-pub-3940256099942544/3986624511")
            } else {
                return !nativeId.isEmpty ? nativeId : (!second_native.isEmpty ? second_native : "ca-app-pub-3940256099942544/3986624511")
            }
        }()
        print("📢 [NativeAd Large] Requesting Ad Unit ID: \(adUnit) | isHomeOpened: \(isHomeOpened)")

        let request = Request()
        adLoader = AdLoader(adUnitID: adUnit,
                            rootViewController: nil,
                            adTypes: [.native],
                            options: nil)
        adLoader?.delegate = self
        adLoader?.load(request)
    }
    
    func refreshSecondNative() {
        didFailToSecondLoad = false
        secondNativeAd = nil

        let isHomeOpened = UserDefaults.standard.bool(forKey: WS_SessionKeys.isHomeOpened)
        let adUnit: String = {
            if !isHomeOpened {
                return !second_native.isEmpty ? second_native : (!nativeId.isEmpty ? nativeId : "ca-app-pub-3940256099942544/3986624511")
            } else {
                return !nativeId.isEmpty ? nativeId : (!second_native.isEmpty ? second_native : "ca-app-pub-3940256099942544/3986624511")
            }
        }()
        print("📢 [Second NativeAd Large] Requesting Ad Unit ID: \(adUnit) | isHomeOpened: \(isHomeOpened)")

        let request = Request()
        secondAdLoader = AdLoader(adUnitID: adUnit,
                            rootViewController: nil,
                            adTypes: [.native],
                            options: nil)
        secondAdLoader?.delegate = self
        secondAdLoader?.load(request)
    }
    
    func refreshSmallNative() {
        didFailToSmallLoad = false
        smallNativeAd = nil

        let isHomeOpened = UserDefaults.standard.bool(forKey: WS_SessionKeys.isHomeOpened)
        let adUnit: String = {
            if !isHomeOpened {
                return !second_small_native.isEmpty ? second_small_native : (!small_native.isEmpty ? small_native : (!nativeId.isEmpty ? nativeId : "ca-app-pub-3940256099942544/3986624511"))
            } else {
                return !small_native.isEmpty ? small_native : (!second_small_native.isEmpty ? second_small_native : (!nativeId.isEmpty ? nativeId : "ca-app-pub-3940256099942544/3986624511"))
            }
        }()
        print("📢 [Small NativeAd] Requesting Ad Unit ID: \(adUnit) | isHomeOpened: \(isHomeOpened)")

        let request = Request()
        smallAdLoader = AdLoader(adUnitID: adUnit,
                            rootViewController: nil,
                            adTypes: [.native],
                            options: nil)
        smallAdLoader?.delegate = self
        smallAdLoader?.load(request)
    }
    
    func refreshSecondSmallNative() {
        didFailToSmallNativeLoad = false
        secondSmallNativeAd = nil

        let isHomeOpened = UserDefaults.standard.bool(forKey: WS_SessionKeys.isHomeOpened)
        let adUnit: String = {
            if !isHomeOpened {
                return !second_small_native.isEmpty ? second_small_native : (!small_native.isEmpty ? small_native : (!nativeId.isEmpty ? nativeId : "ca-app-pub-3940256099942544/3986624511"))
            } else {
                return !small_native.isEmpty ? small_native : (!second_small_native.isEmpty ? second_small_native : (!nativeId.isEmpty ? nativeId : "ca-app-pub-3940256099942544/3986624511"))
            }
        }()
        print("📢 [Second Small NativeAd] Requesting Ad Unit ID: \(adUnit) | isHomeOpened: \(isHomeOpened)")

        let request = Request()
        secondSmallAdLoader = AdLoader(adUnitID: adUnit,
                            rootViewController: nil,
                            adTypes: [.native],
                            options: nil)
        secondSmallAdLoader?.delegate = self
        secondSmallAdLoader?.load(request)
    }
}

// MARK: - Delegates
extension WS_NativeAdViewModel: NativeAdLoaderDelegate, NativeAdDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            if adLoader == self.smallAdLoader {
                self.smallNativeAd = nativeAd
                self.didFailToSmallLoad = false
                nativeAd.delegate = self
                print("✅ [Small NativeAd] Loaded successfully with ID: \(adLoader.adUnitID)")
            } else if adLoader == self.secondAdLoader {
                self.secondNativeAd = nativeAd
                self.didFailToSecondLoad = false
                nativeAd.delegate = self
                print("✅ [Second NativeAd Large] Loaded successfully with ID: \(adLoader.adUnitID)")
            } else if adLoader == self.secondSmallAdLoader {
                self.secondSmallNativeAd = nativeAd
                self.didFailToSmallNativeLoad = false
                nativeAd.delegate = self
                print("✅ [Second Small NativeAd] Loaded successfully with ID: \(adLoader.adUnitID)")
            } else {
                self.nativeAd = nativeAd
                self.didFailToLoad = false
                nativeAd.delegate = self
                print("✅ [NativeAd Large] Loaded successfully with ID: \(adLoader.adUnitID)")
            }
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            if adLoader == self.smallAdLoader {
                self.didFailToSmallLoad = true
                print("❌ [Small NativeAd] Failed to load (ID: \(adLoader.adUnitID)): \(error.localizedDescription)")
            } else if adLoader == self.secondAdLoader {
                self.didFailToSecondLoad = true
                print("❌ [Second NativeAd Large] Failed to load (ID: \(adLoader.adUnitID)): \(error.localizedDescription)")
            } else if adLoader == self.secondSmallAdLoader {
                self.didFailToSmallNativeLoad = true
                print("❌ [Second Small NativeAd] Failed to load (ID: \(adLoader.adUnitID)): \(error.localizedDescription)")
            } else {
                self.didFailToLoad = true
                print("❌ [NativeAd Large] Failed to load (ID: \(adLoader.adUnitID)): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - NativeAdDelegate
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) { print("🖱️ Click recorded") }
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) { print("👀 Impression recorded") }
    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) { print("📱 Will present screen") }
    func nativeAdWillDismissScreen(_ nativeAd: NativeAd) { print("📴 Will dismiss screen") }
    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) { print("✅ Screen dismissed") }
}
