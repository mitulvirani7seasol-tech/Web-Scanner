//
//  WS_SubscriptionManager.swift
//  WebScanner
//
//  Created by Kushang kaklotar on 27/10/26.
//

import Foundation
import StoreKit

final class WS_SubscriptionManager {
    static let shared = WS_SubscriptionManager()

    private var updateListenerTask: Task<Void, Never>? = nil

    private init() {
        startListeningForTransactionUpdates()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// Listens for real-time App Store transactions (purchases, renewals, revocations)
    func startListeningForTransactionUpdates() {
        updateListenerTask?.cancel()
        updateListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                let transaction: Transaction
                switch result {
                case .verified(let t):
                    transaction = t
                case .unverified(let t, _):
                    transaction = t
                }
                
                await transaction.finish()
                await self?.checkSubscriptionStatus()
            }
        }
    }

    @MainActor
    func checkSubscriptionStatus() async {
        var hasActiveSubscription = false
        var foundAnySubscription = false
        var hasExpiredOrRevoked = false

        // 1. Check current entitlements (active subscriptions and lifetime purchases)
        for await result in Transaction.currentEntitlements {
            let transaction: Transaction
            switch result {
            case .verified(let t):
                transaction = t
            case .unverified(let t, _):
                transaction = t
            }

            foundAnySubscription = true

            // If revoked by Apple (e.g. refund/chargeback), it is not active
            if transaction.revocationDate != nil {
                hasExpiredOrRevoked = true
                continue
            }

            if let expirationDate = transaction.expirationDate {
                // Auto-renewable subscription: check if expiration date is in the future
                if expirationDate > Date() {
                    hasActiveSubscription = true
                    break
                } else {
                    hasExpiredOrRevoked = true
                }
            } else {
                // Non-consumable / Lifetime purchase: has no expiration date
                hasActiveSubscription = true
                break
            }
        }

        if hasActiveSubscription {
            UserDefaults.standard.set(true, forKey: WS_SessionKeys.isPro)
            UserDefaults.standard.synchronize()
            WS_AdCountViewModel.shared.isPro = true
            print("👑 [WS_SubscriptionManager] Active subscription found -> isPro = true")
            return
        }

        // 2. If currentEntitlements had records and all were expired or revoked:
        if foundAnySubscription && hasExpiredOrRevoked {
            UserDefaults.standard.set(false, forKey: WS_SessionKeys.isPro)
            UserDefaults.standard.synchronize()
            WS_AdCountViewModel.shared.isPro = false
            print("👑 [WS_SubscriptionManager] Subscription expired or revoked -> isPro = false")
            return
        }

        // 3. If currentEntitlements was empty, inspect past transaction history:
        var hasPastExpiredSubscription = false
        for await result in Transaction.all {
            let transaction: Transaction
            switch result {
            case .verified(let t):
                transaction = t
            case .unverified(let t, _):
                transaction = t
            }

            if transaction.revocationDate != nil {
                hasPastExpiredSubscription = true
                break
            }
            if let expDate = transaction.expirationDate, expDate <= Date() {
                hasPastExpiredSubscription = true
                break
            }
        }

        if hasPastExpiredSubscription {
            UserDefaults.standard.set(false, forKey: WS_SessionKeys.isPro)
            UserDefaults.standard.synchronize()
            WS_AdCountViewModel.shared.isPro = false
            print("👑 [WS_SubscriptionManager] Historical subscription expired -> isPro = false")
        } else {
            // Keep existing status if no expired transaction was confirmed in Apple history
            let currentPro = UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
            print("👑 [WS_SubscriptionManager] No StoreKit expiration history found. Preserving isPro: \(currentPro)")
        }
    }
}
