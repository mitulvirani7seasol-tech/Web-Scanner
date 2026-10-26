//
//  PremiumPaywallView.swift
//  WebScanner
//
//

import SwiftUI
import StoreKit

// MARK: - Paywall Plan Item Model
struct PaywallPlanItem: Identifiable, Equatable {
    let id: String
    let title: String
    let price: String
    let period: String
    let badge: String?
}

public struct PremiumPaywallView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    public var isFromAppOpen: Bool = false
    public var onDismiss: (() -> Void)? = nil
    
    // StoreKit product IDs matching StoreKitFile.storekit
    private let yearProductID = "Re_Year"
    private let monthProductID = "Re_Month"
    private let weekProductID = "Re_Week"
    private let lifetimeProductID = "Re_Lifetime"
    
    @State private var selectedPlanId: String = ""
    @State private var isCloseButtonVisible: Bool = false
    @State private var isProcessing: Bool = false
    @State private var isLoadingPlans: Bool = true
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var storeKitProducts: [Product] = []
    
    @AppStorage(WS_SessionKeys.isPro) private var isPro: Bool = false
    
    // Web sheet state
    @State private var showWebSheet: Bool = false
    @State private var webURL: URL? = nil
    @State private var webTitle: String = ""
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(isFromAppOpen: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.isFromAppOpen = isFromAppOpen
        self.onDismiss = onDismiss
    }
    
    // MARK: - Strictly Dynamic Plans from StoreKit matching Active API Flags (No Static Fallbacks)
    private var availablePlans: [PaywallPlanItem] {
        var plans: [PaywallPlanItem] = []
        
        // 1. Lifetime Plan
        if isLifetimePlanEnabled {
            if let p = storeKitProducts.first(where: { $0.id == lifetimeProductID || $0.id == "Life_Time_Cast" }) {
                plans.append(PaywallPlanItem(
                    id: p.id,
                    title: "Lifetime Plan".localized,
                    price: "\(p.displayPrice)/",
                    period: "One-Time".localized,
                    badge: "Best Value".localized
                ))
            }
        }
        
        // 2. Yearly Plan
        if isYearlyPlanEnabled {
            if let p = storeKitProducts.first(where: { $0.id == yearProductID }) {
                plans.append(PaywallPlanItem(
                    id: yearProductID,
                    title: "Yearly Plan".localized,
                    price: "\(p.displayPrice)/",
                    period: "Per Year".localized,
                    badge: (isLifetimePlanEnabled ? nil : "Best Value".localized)
                ))
            }
        }
        
        // 3. Monthly Plan
        if isMonthlyPlanEnabled {
            if let p = storeKitProducts.first(where: { $0.id == monthProductID }) {
                plans.append(PaywallPlanItem(
                    id: monthProductID,
                    title: "Monthly Plan".localized,
                    price: "\(p.displayPrice)/",
                    period: "Per Month".localized,
                    badge: nil
                ))
            }
        }
        
        // 4. Weekly Plan
        if isWeeklyPlanEnabled {
            if let p = storeKitProducts.first(where: { $0.id == weekProductID }) {
                plans.append(PaywallPlanItem(
                    id: weekProductID,
                    title: "Weekly Plan".localized,
                    price: "\(p.displayPrice)/",
                    period: "Per Week".localized,
                    badge: nil
                ))
            }
        }
        
        return plans
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 56 : 40) : 20.scaled
            
            ZStack {
                // Background
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar (X Close on Timer & Restore)
                    topBar(horizontalPadding: horizontalPadding)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: isIPad ? 18 : 14.scaled) {
                            // Top Illustration Image (ic_premium_Top)
                            Image("ic_premium_Top")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIPad ? (isLandscape ? 220 : 300) : 220.scaled, height: isIPad ? (isLandscape ? 180 : 300) : 180.scaled)
                                .padding(.top, isIPad ? 6 : 2)
                            
                            // Title: Unlock Premium Access
                            titleView
                                .padding(.top, isIPad ? 8 : 6)
                            
                            // Bullet Points / Features
                            featuresListView(horizontalPadding: horizontalPadding)
                                .padding(.top, isIPad ? 8 : 6)
                            
                            // Plans from API & StoreKit (Loader shown while fetching)
                            plansSection
                                .padding(.top, isIPad ? 8 : 4)
                            
                            // Subscribe Now Action Button
                            subscribeButton
                                .padding(.top, isIPad ? 10 : 6)
                            
                            // Legal Pre-Paid Plan Description
                            subscriptionInfoView
                                .padding(.top, isIPad ? 8 : 4)
                            
                            // Legal Footer (Terms of use | Privacy policy | Eula)
                            legalFooter
                                .padding(.top, isIPad ? 6 : 2)
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 20) + 16)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear {
            startCloseButtonTimer()
            fetchPlansAndConfig()
        }
        .onChange(of: isPro) { pro in
            if pro {
                dismiss()
                onDismiss?()
            }
        }
        .sheet(isPresented: $showWebSheet) {
            if let url = webURL {
                WebBrowserSheetView(title: webTitle, url: url)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK".localized) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Close Button Timer
    private func startCloseButtonTimer() {
        let delay = max(0.0, premiumCloseTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.25)) {
                isCloseButtonVisible = true
            }
        }
    }
    
    private func selectDefaultPlanIfNeeded() {
        let plans = availablePlans
        if !plans.contains(where: { $0.id == selectedPlanId }) {
            if plans.contains(where: { $0.id == yearProductID }) {
                selectedPlanId = yearProductID
            } else if plans.contains(where: { $0.id == lifetimeProductID || $0.id == "Life_Time_Cast" }) {
                selectedPlanId = plans.first(where: { $0.id == lifetimeProductID || $0.id == "Life_Time_Cast" })?.id ?? ""
            } else if let first = plans.first {
                selectedPlanId = first.id
            } else {
                selectedPlanId = ""
            }
        }
    }
    
    // MARK: - Top Bar (Close on Timer & Restore)
    private func topBar(horizontalPadding: CGFloat) -> some View {
        HStack {
            if isCloseButtonVisible {
                Button(action: {
                    HapticFeedback.generate(.light)
                    handleCloseAction()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: isIPad ? 24 : 18.scaled, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .frame(width: isIPad ? 36 : 28.scaled, height: isIPad ? 36 : 28.scaled)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity)
            } else {
                Color.clear
                    .frame(width: isIPad ? 36 : 28.scaled, height: isIPad ? 36 : 28.scaled)
            }
            
            Spacer()
            
            Button(action: {
                HapticFeedback.generate(.light)
                handleRestore()
            }) {
                Text("Restore".localized)
                    .font(.inter(.medium, size: isIPad ? 20 : 16.scaled))
                    .foregroundColor(AppColors.SaticColor(for: colorScheme))
                    .underline()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 18 : 12)
        .padding(.bottom, isIPad ? 6 : 4)
    }
    
    private func handleCloseAction() {
        let shouldShowInterOnClose = isFromAppOpen && (pro_close_inter == "true") && TR_AdsManager.isConnectedToNetwork() && !isPro
        if shouldShowInterOnClose {
            var didDismiss = false
            let safeDismiss = {
                guard !didDismiss else { return }
                didDismiss = true
                dismiss()
                onDismiss?()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if !TR_AdState.shared.isShowingInterstitial {
                    safeDismiss()
                }
            }
            
            TR_AdCountViewModel.sharedd.interstitialManager.present {
                safeDismiss()
            }
        } else {
            dismiss()
            onDismiss?()
        }
    }
    
    // MARK: - Title
    private var titleView: some View {
        HStack(spacing: 5) {
            Text("Unlock".localized)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            Text("Premium".localized)
                .foregroundColor(Color(hex: "#16A34A"))
            Text("Access".localized)
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
        }
        .font(.inter(.bold, size: isIPad ? 24 : 20.scaled))
    }
    
    // MARK: - Features List
    private func featuresListView(horizontalPadding: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 12.scaled) {
            featureBulletRow(title: "Unlimited WhatsApp Scan Access".localized)
            featureBulletRow(title: "Direct Chat Without Limits".localized)
            featureBulletRow(title: "Unlimited Status Downloads".localized)
            featureBulletRow(title: "Ad-Free Experience".localized)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
    
    private func featureBulletRow(title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(AppColors.textPrimary(for: colorScheme), lineWidth: 1.2)
                    .frame(width: isIPad ? 24 : 20.scaled, height: isIPad ? 24 : 20.scaled)
                
                Image(systemName: "checkmark")
                    .font(.system(size: isIPad ? 12 : 10.scaled, weight: .bold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
            }
            
            Text(title)
                .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
        }
    }
    
    // MARK: - Plans Section (Loaded dynamically from API & StoreKit)
    private var plansSection: some View {
        VStack(spacing: isIPad ? 20 : 12.scaled) {
            if isLoadingPlans {
                VStack(spacing: 14) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#16A34A")))
                        .scaleEffect(isIPad ? 1.5 : 1.2)
                    
                    Text("Loading plans...".localized)
                        .font(.inter(.medium, size: isIPad ? 16 : 13.scaled))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 180 : 130.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.4), lineWidth: 1)
                )
                .glassModifier(cornerRadius: 18)
            } else if availablePlans.isEmpty {
                if !TR_AdsManager.isConnectedToNetwork() {
                    // No Internet Card
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: isIPad ? 28 : 22.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        
                        Text("Unable to load plans. Please check your internet connection.".localized)
                            .font(.inter(.medium, size: isIPad ? 14 : 12.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            HapticFeedback.generate(.light)
                            fetchPlansAndConfig()
                        }) {
                            Text("Retry".localized)
                                .font(.inter(.bold, size: isIPad ? 15 : 13.scaled))
                                .foregroundColor(Color(hex: "#16A34A"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "#16A34A").opacity(0.12))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 180 : 130.scaled)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .glassModifier(cornerRadius: 18)
                } else {
                    // No Plan Available Card (API flags are false)
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: isIPad ? 30 : 24.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        
                        Text("No plan available".localized)
                            .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text("Currently no subscription plans are available.".localized)
                            .font(.inter(.regular, size: isIPad ? 13 : 11.5.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 180 : 130.scaled)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .glassModifier(cornerRadius: 18)
                }
            } else {
                ForEach(availablePlans) { plan in
                    planCard(
                        id: plan.id,
                        title: plan.title,
                        price: plan.price,
                        period: plan.period,
                        badge: plan.badge
                    )
                }
            }
        }
    }
    
    private func planCard(
        id: String,
        title: String,
        price: String,
        period: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedPlanId == id
        
        return Button(action: {
            HapticFeedback.generate(.selection)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedPlanId = id
            }
        }) {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .center) {
                    // Left: Price & Period
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text(period)
                            .font(.inter(.regular, size: isIPad ? 13 : 11.5.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    // Right: Plan Title
                    Text(title)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                }
                .padding(.horizontal, isIPad ? 20 : 16.scaled)
                .padding(.vertical, isIPad ? 26 : 18.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            isSelected
                            ? (colorScheme == .dark ? Color(hex: "#16A34A").opacity(0.12) : Color(hex: "#16A34A").opacity(0.08))
                            : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.35))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isSelected
                            ? Color(hex: "#16A34A")
                            : (colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.55)),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .glassModifier(cornerRadius: 18)
                
                // Badge on Top Right
                if let badge = badge {
                    Text(badge)
                        .font(.inter(.bold, size: isIPad ? 11 : 9.5.scaled))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10.scaled)
                        .padding(.vertical, 3.5.scaled)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FF8C00"), Color(hex: "#FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .offset(x: -14.scaled, y: -8.scaled)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Subscribe Now Button
    private var subscribeButton: some View {
        Button(action: {
            HapticFeedback.generate(.medium)
            handlePurchase()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "#16A34A"))
                    .frame(height: isIPad ? 70 : 50.scaled)
                    .shadow(color: Color(hex: "#16A34A").opacity(availablePlans.isEmpty || isLoadingPlans ? 0.0 : 0.35), radius: 8, x: 0, y: 4)
                    .opacity(availablePlans.isEmpty || isLoadingPlans ? 0.5 : 1.0)
                
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe Now".localized)
                        .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isProcessing || isLoadingPlans || availablePlans.isEmpty)
    }
    
    // MARK: - Legal Pre-Paid Plan & Subscription Management Info
    private var subscriptionInfoView: some View {
        VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
            Text("Subscription options are available only through the App Store. Payment will be charged to your Apple ID account once your subscription starts. Subscriptions renew automatically at the same price and duration unless canceled at least 24 hours before the current period ends. You can manage or cancel your subscription anytime in your Apple ID account settings.".localized)
                .font(.inter(.regular, size: isIPad ? 16 : 14.scaled))
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Legal Footer (Terms of use | Privacy policy | Eula)
    private var legalFooter: some View {
        HStack(spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                if let url = URL(string: TEARMS) {
                    webURL = url
                    webTitle = "Terms of use".localized
                    showWebSheet = true
                }
            }) {
                Text("Terms of use".localized)
                    .font(.inter(.regular, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            
            Rectangle()
                .fill(AppColors.textSecondary(for: colorScheme).opacity(0.4))
                .frame(width: 1, height: 12)
            
            Button(action: {
                HapticFeedback.generate(.light)
                if let url = URL(string: PRIVACYPOLICY) {
                    webURL = url
                    webTitle = "Privacy policy".localized
                    showWebSheet = true
                }
            }) {
                Text("Privacy policy".localized)
                    .font(.inter(.regular, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            
            Rectangle()
                .fill(AppColors.textSecondary(for: colorScheme).opacity(0.4))
                .frame(width: 1, height: 12)
            
            Button(action: {
                HapticFeedback.generate(.light)
                if let url = URL(string: EULA) {
                    webURL = url
                    webTitle = "Eula".localized
                    showWebSheet = true
                }
            }) {
                Text("Eula".localized)
                    .font(.inter(.regular, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 4)
    }
    
    // MARK: - Helpers & StoreKit Logic
    private func fetchPlansAndConfig() {
        isLoadingPlans = true
        
        let fetchStoreKitBlock: () -> Void = {
            Task {
                await self.loadStoreKitProducts()
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.isLoadingPlans = false
                        self.selectDefaultPlanIfNeeded()
                    }
                }
            }
        }
        
        if TR_AdsManager.isConnectedToNetwork() {
            print("🌐 [PremiumPaywallView] Fetching remote configuration & StoreKit products...")
            WS_AppConsentManager.shared.fetchRemoteConfiguration {
                fetchStoreKitBlock()
            }
        } else {
            // When internet is offline, attempt loading local StoreKit products
            fetchStoreKitBlock()
        }
    }
    
    private func loadStoreKitProducts() async {
        do {
            let ids: Set<String> = [
                yearProductID,
                monthProductID,
                weekProductID,
                lifetimeProductID,
                "Life_Time_Cast"
            ]
            let products = try await Product.products(for: ids)
            await MainActor.run {
                self.storeKitProducts = products
            }
            print("🛒 [PremiumPaywallView] Successfully loaded \(products.count) StoreKit products:")
            for p in products {
                print("   - \(p.id): \(p.displayPrice)")
            }
        } catch {
            print("❌ [PremiumPaywallView] Failed to load StoreKit products: \(error)")
        }
    }
    
    private func handlePurchase() {
        guard let product = storeKitProducts.first(where: { $0.id == selectedPlanId }) else {
            alertTitle = "Plan Unavailable".localized
            alertMessage = "Selected plan is currently unavailable. Please try again.".localized
            showAlert = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let result = try await product.purchase()
                await MainActor.run {
                    self.isProcessing = false
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified(let transaction):
                            Task {
                                await transaction.finish()
                            }
                            self.isPro = true
                            self.alertTitle = "Premium Activated".localized
                            self.alertMessage = "Thank you for subscribing! All premium features are now unlocked.".localized
                            self.showAlert = true
                            HapticFeedback.generate(.success)
                        case .unverified:
                            self.alertTitle = "Purchase Unverified".localized
                            self.alertMessage = "The purchase could not be verified.".localized
                            self.showAlert = true
                        }
                    case .userCancelled:
                        break
                    case .pending:
                        self.alertTitle = "Purchase Pending".localized
                        self.alertMessage = "Your purchase is pending approval.".localized
                        self.showAlert = true
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.alertTitle = "Purchase Error".localized
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    private func handleRestore() {
        isProcessing = true
        
        Task {
            do {
                try await AppStore.sync()
                await MainActor.run {
                    self.isProcessing = false
                    self.isPro = true
                    self.alertTitle = "Restore Purchases".localized
                    self.alertMessage = "Your purchases have been successfully restored.".localized
                    self.showAlert = true
                    HapticFeedback.generate(.success)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.alertTitle = "Restore Purchases".localized
                    self.alertMessage = "No active subscription found for this account.".localized
                    self.showAlert = true
                }
            }
        }
    }
}

#Preview {
    PremiumPaywallView()
}
