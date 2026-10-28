//
//  WS_AdCountViewModel.swift
//  WebScanner
//
//

import Foundation
import Combine
import SwiftUI

typealias TR_AdCountViewModel = WS_AdCountViewModel
typealias SM_AdCountViewModel = WS_AdCountViewModel

final class WS_AdCountViewModel: NSObject, ObservableObject {
    var isPro: Bool {
        get { UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro) }
        set { UserDefaults.standard.set(newValue, forKey: WS_SessionKeys.isPro) }
    }
    @Published var tapCount: Int = 0
    @Published var afterClick: Int = 1

    let interstitialManager = WS_InterstitialAdManager()
    var cancellables = Set<AnyCancellable>()
    static let shared = WS_AdCountViewModel()
    static var sharedd: WS_AdCountViewModel { shared }

    // MARK: - Init
    override init() {
        super.init()
        interstitialManager.load()
        observeAfterClickChange()
    }

    // MARK: - Observe afterClick changes dynamically
    private func observeAfterClickChange() {
        NotificationCenter.default.publisher(
            for: Notification.Name(rawValue: "afterClickUpdated")
        )
        .sink { [weak self] _ in
            guard let self else { return }
            
            self.afterClick = adsCount
            print("Updated afterClick: \(self.afterClick)")
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Tap Logic
    func registerTap() {
        tapCount += 1
        print("Total Tap Count: \(tapCount)")

        guard !isPro else { return }

        if tapCount >= afterClick {
            print("Tap count reached threshold (\(afterClick)) — showing ad.")
            showInterstitial()
            tapCount = 0
        }
    }
    
    func registerTap(completion: @escaping () -> Void) {
        tapCount += 1
        
        guard !isPro else {
            completion()
            return
        }
        
        if tapCount >= afterClick {
            tapCount = 0
            
            interstitialManager.present {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    completion()
                }
            }
        } else {
            completion()
        }
    }

    // MARK: - Show & Reload Ads
    private func showInterstitial() {
        interstitialManager.present()
        reloadAd()
    }

    func reloadAd() {
        print("Reloading interstitial ad...")
        interstitialManager.load()
    }
}
