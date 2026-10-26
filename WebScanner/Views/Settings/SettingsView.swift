//
//  SettingsView.swift
//  WebScanner
//

import SwiftUI
import SafariServices
import StoreKit

public struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    
    @State private var isDarkMode: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showSafari: Bool = false
    @State private var safariURL: URL? = nil
    @State private var safariTitle: String = ""
    @State private var showPaywall: Bool = false
    @State private var navigateToLanguage: Bool = false
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    
    public init() {}
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var currentLanguageName: String {
        let code = localizationHelper.currentLanguage
        return LanguageSelectionView.availableLanguages.first { $0.code == code }?.name ?? "English"
    }
    
    public var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    // Background Image
                    
                    VStack(spacing: 0) {
                        // Top Header (Pinned at top)
                        topHeader
                            .padding(.horizontal, 16)
                            .padding(.top, isIPad ? 16 : 8.scaled)
                            .padding(.bottom, isIPad ? 14 : 10.scaled)
                        
                        // Scrollable Content
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: isIPad ? 22 : 18.scaled) {
                                // Card 1: Language & Dark Mode
                                preferencesCard
                                
                                if !isPro {
                                    TR_NativeAd7()
                                }
                                
                                // Section: Support
                                supportSection
                                
                                // Section: About (Without About Us)
                                aboutSection
                                
                                Spacer()
                                    .frame(height: isIPad ? 120 : 100.scaled)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, isIPad ? 4 : 2)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .background(
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            )
            
            .navigationDestination(isPresented: $navigateToLanguage) {
                LanguageSelectionView()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showSafari) {
                if let url = safariURL {
                    WebBrowserSheetView(title: safariTitle, url: url)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareURL = URL(string: APPURL) {
                    ShareActivityView(activityItems: ["Check out \(appname)!", shareURL])
                }
            }
            .onAppear {
                isDarkMode = (themeManager.currentTheme == .dark)
            }
        }
    }
    
    // MARK: - Top Header
    private var topHeader: some View {
        HStack(alignment: .center) {
            Text("Settings".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 22))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            Button(action: {
                HapticFeedback.generate(.light)
                showPaywall = true
            }) {
                Image("ic_premium")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 46 : 36.scaled, height: isIPad ? 46 : 36.scaled)
                    .contentShape(Rectangle())
            }
            .frame(width: isIPad ? 56 : 44, height: isIPad ? 56 : 44)
            .contentShape(Rectangle())
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Preferences Card (Language & Dark Mode)
    private var preferencesCard: some View {
        VStack(spacing: 0) {
            // Language Row (Whole row clickable)
            Button(action: {
                HapticFeedback.generate(.light)
                TR_AdCountViewModel.sharedd.registerTap {
                    navigateToLanguage = true
                }
            }) {
                HStack(spacing: isIPad ? 16 : 14.scaled) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: isIPad ? 22 : 18.scaled))
                        .foregroundColor(AppColors.primaryGreen)
                        .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled, alignment: .center)
                    
                    Text("Language".localized)
                        .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Spacer()
                    
                    HStack(spacing: isIPad ? 8 : 6.scaled) {
                        Text(currentLanguageName)
                            .font(.inter(.regular, size: isIPad ? 15 : 13.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12.scaled, weight: .semibold))
                            .foregroundColor(Color(hex: "#C4C4C6"))
                    }
                }
                .padding(.horizontal, isIPad ? 18 : 16.scaled)
                .frame(height: isIPad ? 60 : 50.scaled)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            dividerLine
            
            // Dark Mode Row
            HStack(spacing: isIPad ? 16 : 14.scaled) {
                Image(systemName: "moon.fill")
                    .font(.system(size: isIPad ? 22 : 18.scaled))
                    .foregroundColor(AppColors.primaryGreen)
                    .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled, alignment: .center)
                
                Text("Dark Mode".localized)
                    .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                Toggle("", isOn: $isDarkMode)
                    .labelsHidden()
                    .tint(AppColors.primaryGreen)
                    .onChange(of: isDarkMode) { newValue in
                        HapticFeedback.generate(.selection)
                        themeManager.currentTheme = newValue ? .dark : .light
                    }
            }
            .padding(.horizontal, isIPad ? 18 : 16.scaled)
            .frame(height: isIPad ? 60 : 50.scaled)
            .contentShape(Rectangle())
        }
        .glassCard(
            cornerRadius: 16.scaled,
            color: colorScheme == .dark ? Color.clear : Color.clear
        )
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 10 : 8.scaled) {
            Text("Support".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // Rate App (Whole row clickable)
                Button(action: {
                    rateApp()
                }) {
                    HStack(spacing: isIPad ? 16 : 14.scaled) {
                        Image(systemName: "star.fill")
                            .font(.system(size: isIPad ? 22 : 18.scaled))
                            .foregroundColor(AppColors.primaryGreen)
                            .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled, alignment: .center)
                        
                        Text("Rate App".localized)
                            .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12.scaled, weight: .semibold))
                            .foregroundColor(Color(hex: "#C4C4C6"))
                    }
                    .padding(.horizontal, isIPad ? 18 : 16.scaled)
                    .frame(height: isIPad ? 60 : 50.scaled)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                dividerLine
                
                // Share App (Whole row clickable)
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    showShareSheet = true
                }) {
                    HStack(spacing: isIPad ? 16 : 14.scaled) {
                        ShareNodesIcon(size: isIPad ? 20 : 17.scaled, color: AppColors.primaryGreen)
                            .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled, alignment: .center)
                        
                        Text("Share App".localized)
                            .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12.scaled, weight: .semibold))
                            .foregroundColor(Color(hex: "#C4C4C6"))
                    }
                    .padding(.horizontal, isIPad ? 18 : 16.scaled)
                    .frame(height: isIPad ? 60 : 50.scaled)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .glassCard(
                cornerRadius: 16.scaled,
                color: colorScheme == .dark ? Color.clear : Color.clear
            )
        }
    }
    
    // MARK: - About Section (No About Us)
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 10 : 8.scaled) {
            Text("About".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                // Privacy Policy (Whole row clickable)
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    if let url = URL(string: PRIVACYPOLICY) {
                        safariURL = url
                        safariTitle = "Privacy Policy".localized
                        showSafari = true
                    }
                }) {
                    HStack(spacing: isIPad ? 16 : 14.scaled) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: isIPad ? 22 : 18.scaled))
                            .foregroundColor(AppColors.primaryGreen)
                            .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled, alignment: .center)
                        
                        Text("Privacy Policy".localized)
                            .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12.scaled, weight: .semibold))
                            .foregroundColor(Color(hex: "#C4C4C6"))
                    }
                    .padding(.horizontal, isIPad ? 18 : 16.scaled)
                    .frame(height: isIPad ? 60 : 50.scaled)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                dividerLine
                
                // Terms of Use (Whole row clickable)
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    if let url = URL(string: TEARMS) {
                        safariURL = url
                        safariTitle = "Terms of Use".localized
                        showSafari = true
                    }
                }) {
                    HStack(spacing: isIPad ? 16 : 14.scaled) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: isIPad ? 22 : 18.scaled))
                            .foregroundColor(AppColors.primaryGreen)
                            .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled, alignment: .center)
                        
                        Text("Terms of Use".localized)
                            .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12.scaled, weight: .semibold))
                            .foregroundColor(Color(hex: "#C4C4C6"))
                    }
                    .padding(.horizontal, isIPad ? 18 : 16.scaled)
                    .frame(height: isIPad ? 60 : 50.scaled)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                dividerLine
                
                // EULA (Whole row clickable)
                Button(action: {
                    HapticFeedback.generate(.light)
                    if let url = URL(string: EULA) {
                        safariURL = url
                        safariTitle = "EULA".localized
                        showSafari = true
                    }
                }) {
                    HStack(spacing: isIPad ? 16 : 14.scaled) {
                        Image(systemName: "doc.plaintext.fill")
                            .font(.system(size: isIPad ? 22 : 18.scaled))
                            .foregroundColor(AppColors.primaryGreen)
                            .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled, alignment: .center)
                        
                        Text("EULA".localized)
                            .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: isIPad ? 14 : 12.scaled, weight: .semibold))
                            .foregroundColor(Color(hex: "#C4C4C6"))
                    }
                    .padding(.horizontal, isIPad ? 18 : 16.scaled)
                    .frame(height: isIPad ? 60 : 50.scaled)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .glassCard(
                cornerRadius: 16.scaled,
                color: colorScheme == .dark ? Color.clear : Color.clear
            )
        }
    }
    
    // MARK: - Reusable Divider Line
    private var dividerLine: some View {
        Divider()
            .background(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
            .padding(.leading, isIPad ? 58 : 50.scaled)
    }
    
    // MARK: - Actions
    private func rateApp() {
        HapticFeedback.generate(.light)
        if let url = URL(string: REVIEW_LINK), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

// MARK: - Pixel-Perfect Share Nodes Icon
struct ShareNodesIcon: View {
    var size: CGFloat = 18
    var color: Color = AppColors.primaryGreen
    
    var body: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height
            
            let pLeft = CGPoint(x: w * 0.22, y: h * 0.5)
            let pTopRight = CGPoint(x: w * 0.82, y: h * 0.22)
            let pBottomRight = CGPoint(x: w * 0.82, y: h * 0.78)
            let circleR = w * 0.16
            let lineWidth = w * 0.10
            
            // Connecting branch lines
            var path = Path()
            path.move(to: pLeft)
            path.addLine(to: pTopRight)
            path.move(to: pLeft)
            path.addLine(to: pBottomRight)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            
            // 3 Nodes (filled circles)
            for pt in [pLeft, pTopRight, pBottomRight] {
                let rect = CGRect(x: pt.x - circleR, y: pt.y - circleR, width: circleR * 2, height: circleR * 2)
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Safari & Share Sheet Representables
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
