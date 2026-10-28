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
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    topBar(horizontalPadding: horizontalPadding)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: isIPad ? 18 : 14.scaled) {
                            Image("ic_premium_Top")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIPad ? (isLandscape ? 220 : 300) : 220.scaled, height: isIPad ? (isLandscape ? 180 : 300) : 180.scaled)
                                .padding(.top, isIPad ? 6 : 2)
                            
                            titleView
                                .padding(.top, isIPad ? 8 : 6)
                            
                            featuresListView(horizontalPadding: horizontalPadding)
                                .padding(.top, isIPad ? 8 : 6)
                            
                            plansSection
                                .padding(.top, isIPad ? 8 : 4)
                            
                            subscribeButton
                                .padding(.top, isIPad ? 10 : 6)
                            
                            legalFooter
                                .padding(.top, isIPad ? 8 : 2)
                            
                            subscriptionInfoView
                                .padding(.top, isIPad ? 8 : 4)
                            
                            
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
            fetchPlansAndSet()
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
            Button("OK".localized) {
                let isUserPro = self.isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
                if isUserPro {
                    dismiss()
                    onDismiss?()
                }
            }
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
        if !plans.contains(where: { $0.id == selectedPlanId }) || selectedPlanId.isEmpty {
            let matchingProducts = storeKitProducts.filter { prod in
                plans.contains(where: { $0.id == prod.id })
            }
            
            if let highestPriceProduct = matchingProducts.max(by: { $0.price < $1.price }) {
                selectedPlanId = highestPriceProduct.id
                print("💎 [PremiumPaywallView] Default selected highest price plan: \(highestPriceProduct.id) (\(highestPriceProduct.displayPrice))")
            } else if plans.contains(where: { $0.id == lifetimeProductID || $0.id == "Life_Time_Cast" }) {
                selectedPlanId = plans.first(where: { $0.id == lifetimeProductID || $0.id == "Life_Time_Cast" })?.id ?? ""
            } else if plans.contains(where: { $0.id == yearProductID }) {
                selectedPlanId = yearProductID
            } else if plans.contains(where: { $0.id == monthProductID }) {
                selectedPlanId = monthProductID
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
                        .frame(width: isIPad ? 44 : 36.scaled, height: isIPad ? 44 : 36.scaled)
                        .clipShape(Circle())
                        .glassCard(cornerRadius: isIPad ? 22 : 18.scaled)
                }
                .buttonStyle(ScaleButtonStyle())
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
        let isUserPro = isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
        let shouldShowInterOnClose = isFromAppOpen && (pro_close_inter == "true") && TR_AdsManager.isConnectedToNetwork() && !isUserPro
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
                            fetchPlansAndSet()
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
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text(period)
                            .font(.inter(.regular, size: isIPad ? 13 : 11.5.scaled))
                            .foregroundColor(AppColors.SaticColor(for: colorScheme))
                    }
                    
                    Spacer()
                    
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
                            ? (colorScheme == .dark ? Color(hex: "#16A34A").opacity(0.12) : Color(hex: "#16A34A").opacity(0.4))
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
    private func fetchPlansAndSet() {
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
            WS_AppConsentManager.shared.fetchRemoteration {
                fetchStoreKitBlock()
            }
        } else {
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
                        let transaction: StoreKit.Transaction?
                        switch verification {
                        case .verified(let t):
                            transaction = t
                        case .unverified(let t, _):
                            transaction = t
                        }
                        
                        if let transaction = transaction {
                            Task {
                                await transaction.finish()
                            }
                        }
                        
                        self.isPro = true
                        UserDefaults.standard.set(true, forKey: WS_SessionKeys.isPro)
                        UserDefaults.standard.synchronize()
                        WS_AdCountViewModel.shared.isPro = true
                        
                        self.alertTitle = "Premium Activated".localized
                        self.alertMessage = "Thank you for subscribing! All premium features are now unlocked.".localized
                        self.showAlert = true
                        HapticFeedback.generate(.success)
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
                await WS_SubscriptionManager.shared.checkSubscriptionStatus()
                let isStillPro = UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
                await MainActor.run {
                    self.isProcessing = false
                    if isStillPro {
                        self.isPro = true
                        UserDefaults.standard.set(true, forKey: WS_SessionKeys.isPro)
                        UserDefaults.standard.synchronize()
                        WS_AdCountViewModel.shared.isPro = true
                        self.alertTitle = "Restore Purchases".localized
                        self.alertMessage = "Your purchases have been successfully restored.".localized
                        self.showAlert = true
                        HapticFeedback.generate(.success)
                    } else {
                        self.isPro = false
                        UserDefaults.standard.set(false, forKey: WS_SessionKeys.isPro)
                        UserDefaults.standard.synchronize()
                        WS_AdCountViewModel.shared.isPro = false
                        self.alertTitle = "Restore Purchases".localized
                        self.alertMessage = "No active subscription found for this account.".localized
                        self.showAlert = true
                    }
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
