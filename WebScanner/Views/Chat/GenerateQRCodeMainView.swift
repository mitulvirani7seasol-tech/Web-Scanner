//
//  GenerateQRCodeMainView.swift
//  WebScanner
//
//

import SwiftUI
import Combine

public enum GenerateCodeTab: Int {
    case qrCode = 0
    case barcode = 1
}

public final class GenerateQRTabManager: ObservableObject {
    public static let shared = GenerateQRTabManager()
    @Published public var selectedTab: GenerateCodeTab = .qrCode
    private init() {}
}

public struct GenerateQRCodeMainView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var tabManager = GenerateQRTabManager.shared
    
    private var navPath: Binding<NavigationPath>?
    
    @State private var selectedCategoryToNavigate: QRCodeCategory? = nil
    @State private var selectedBarcodeToNavigate: BarcodeCategory? = nil
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(navPath: Binding<NavigationPath>? = nil) {
        self.navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 48 : 32) : 18.scaled
            
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar(horizontalPadding: horizontalPadding)
                
                segmentedToggleBar
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 14 : 10)
                    .padding(.bottom, isIPad ? 14 : 12)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 14 : 12.scaled) {
                        if tabManager.selectedTab == .qrCode {
                            ForEach(QRCodeCategory.allCases) { item in
                                qrCodeItemCard(item: item)
                            }
                        } else {
                            ForEach(BarcodeCategory.allCases) { item in
                                barcodeItemCard(item: item)
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 4)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 20)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedCategoryToNavigate != nil && navPath == nil },
            set: { if !$0 { selectedCategoryToNavigate = nil } }
        )) {
            if let cat = selectedCategoryToNavigate {
                CreateQRCodeFormView(category: cat, navPath: navPath)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedBarcodeToNavigate != nil && navPath == nil },
            set: { if !$0 { selectedBarcodeToNavigate = nil } }
        )) {
            if let cat = selectedBarcodeToNavigate {
                CreateBarcodeFormView(category: cat, navPath: navPath)
            }
        }
    }
    
    // MARK: - Header Bar (< Generate QR Code)
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                handleBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Generate QR Code".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - Segmented Toggle Bar (QR Code | Barcode)
    private var segmentedToggleBar: some View {
        HStack(spacing: 4) {
            Button(action: {
                TR_AdCountViewModel.sharedd.registerTap()
                HapticFeedback.generate(.selection)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    tabManager.selectedTab = .qrCode
                }
            }) {
                HStack(spacing: 8) {
                    Image(tabManager.selectedTab == .qrCode ? "ic_QRcode_selected" : "ic_QRcode")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(tabManager.selectedTab == .qrCode ? .white : AppColors.textSecondary(for: colorScheme))
                    
                    Text("QR Code".localized)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(tabManager.selectedTab == .qrCode ? .white : AppColors.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 48 : 42.scaled)
                .background(
                    Capsule()
                        .fill(tabManager.selectedTab == .qrCode ? Color(hex: "#16A34A") : Color.clear)
                )
            }
            .contentShape(Rectangle())
            
            Button(action: {
                TR_AdCountViewModel.sharedd.registerTap()
                HapticFeedback.generate(.selection)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    tabManager.selectedTab = .barcode
                }
            }) {
                HStack(spacing: 8) {
                    Image(tabManager.selectedTab == .barcode ? "ic_barcode_selected" : "ic_barcode")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(tabManager.selectedTab == .barcode ? .white : AppColors.textSecondary(for: colorScheme))
                    
                    Text("Barcode".localized)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(tabManager.selectedTab == .barcode ? .white : AppColors.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 48 : 42.scaled)
                .background(
                    Capsule()
                        .fill(tabManager.selectedTab == .barcode ? Color(hex: "#16A34A") : Color.clear)
                )
            }
            .contentShape(Rectangle())
        }
        .padding(4)
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .glassModifier(cornerRadius: 24)
    }
    
    // MARK: - QR Code Item Card
    private func qrCodeItemCard(item: QRCodeCategory) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap {
                if let nav = navPath {
                    nav.wrappedValue.append(HomeDestination.createQRCode(item))
                } else {
                    selectedCategoryToNavigate = item
                }
            }
        }) {
            HStack(spacing: 14) {
                Image(item.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isIPad ? 56 : 40.scaled, height: isIPad ? 56 : 40.scaled)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title.localized)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.5.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Text(item.subtitle.localized)
                        .font(.inter(.regular, size: isIPad ? 13 : 11.5.scaled))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: isIPad ? 16 : 13, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.5))
            }
            .padding(.horizontal, isIPad ? 18 : 14.scaled)
            .padding(.vertical, isIPad ? 14 : 12.scaled)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
            .glassModifier(cornerRadius: 18)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Barcode Item Card
    private func barcodeItemCard(item: BarcodeCategory) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap {
                if let nav = navPath {
                    nav.wrappedValue.append(HomeDestination.createBarcode(item))
                } else {
                    selectedBarcodeToNavigate = item
                }
            }
        }) {
            HStack(spacing: 14) {
                Image(item.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isIPad ? 56 : 40.scaled, height: isIPad ? 56 : 40.scaled)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title.localized)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.5.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Text(item.subtitle.localized)
                        .font(.inter(.regular, size: isIPad ? 13 : 11.5.scaled))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: isIPad ? 16 : 13, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.5))
            }
            .padding(.horizontal, isIPad ? 18 : 14.scaled)
            .padding(.vertical, isIPad ? 14 : 12.scaled)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
            .glassModifier(cornerRadius: 18)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleBack() {
        if let nav = navPath, !nav.wrappedValue.isEmpty {
            nav.wrappedValue.removeLast()
        } else {
            dismiss()
        }
    }
}

#Preview {
    GenerateQRCodeMainView()
}
