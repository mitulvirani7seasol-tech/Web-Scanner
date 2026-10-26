//
//  BarcodeDetailsView.swift
//  WebScanner
//
//

import SwiftUI
import CoreImage

public struct BarcodeDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    public let barcodeText: String
    public let category: BarcodeCategory
    private var navPath: Binding<NavigationPath>?
    
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var barcodeImage: UIImage? = nil
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(barcodeText: String, category: BarcodeCategory, navPath: Binding<NavigationPath>? = nil) {
        self.barcodeText = barcodeText
        self.category = category
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
                // 1. Top Custom Navigation Header: < Barcode Details
                headerBar(horizontalPadding: horizontalPadding)
                
                // 2. Main Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 20 : 16.scaled) {
                        // Card 1: Barcode Preview Card (Matches Screenshot 5)
                        barcodePreviewCard
                        
                        // Card 2: Result text + Copy & Share buttons
                        resultCard
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 14 : 10)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 16)
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
            generateBarcodeImage()
        }
        .onDisappear {
            GenerateQRTabManager.shared.selectedTab = .barcode
        }
        .sheet(isPresented: $showShareSheet) {
            if !barcodeText.isEmpty {
                if let img = barcodeImage {
                    ActivityView(activityItems: [barcodeText, img])
                } else {
                    ActivityView(activityItems: [barcodeText])
                }
            }
        }
    }
    
    // MARK: - Header Bar (< Barcode Details)
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
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Barcode Details".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 10 : 6)
    }
    
    // MARK: - Card 1: Barcode Preview
    private var barcodePreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Barcode Preview".localized)
                .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            VStack(spacing: 8) {
                if let bImg = barcodeImage {
                    Image(uiImage: bImg)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(height: isIPad ? 220 : 140.scaled)
                        .padding(.top, 14)
                        .padding(.horizontal, 16)
                    
                    Text(barcodeText)
                        .font(.system(size: isIPad ? 22 : 18.scaled, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .tracking(3)
                        .padding(.bottom, 14)
                } else {
                    ProgressView()
                        .frame(height: isIPad ? 280 : 160.scaled)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
//            .background(
//                RoundedRectangle(cornerRadius: 14, style: .continuous)
//                    .fill(Color.white)
//            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, isIPad ? 20 : 16.scaled)
        .padding(.vertical, isIPad ? 18 : 14.scaled)
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
        .glassModifier(cornerRadius: 18)
    }
    
    // MARK: - Card 2: Result text + Copy & Share buttons
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Result".localized)
                .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            // Inner Result Barcode Number Container
            Text(barcodeText)
                .font(.inter(.medium, size: isIPad ? 16 : 14.5.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                )
            
            // Action Buttons: Copy (outlined) & Share (filled green)
            HStack(spacing: 12) {
                // Copy Button (Outlined green)
                Button(action: {
                    TR_AdCountViewModel.sharedd.registerTap()
                    copyToClipboard()
                }) {
                    HStack(spacing: 6) {
                        if isCopied {
                            Image(systemName: "checkmark")
                                .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                            Text("Copied!".localized)
                                .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        } else {
                            Text("Copy".localized)
                                .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        }
                    }
                    .foregroundColor(Color(hex: "#16A34A"))
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 50 : 44.scaled)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(hex: "#16A34A"), lineWidth: 1.5)
                    )
                }
                .contentShape(Rectangle())
                .glassModifier(cornerRadius: 24)
                
                // Share Button (Solid green)
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    showShareSheet = true
                }) {
                    Text("Share".localized)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 50 : 44.scaled)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(hex: "#16A34A"))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, isIPad ? 20 : 16.scaled)
        .padding(.vertical, isIPad ? 18 : 14.scaled)
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
        .glassModifier(cornerRadius: 18)
    }
    
    // MARK: - Actions & Barcode Generator
    private func copyToClipboard() {
        HapticFeedback.generate(.success)
        UIPasteboard.general.string = barcodeText
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isCopied = false
            }
        }
    }
    
    private func handleBack() {
        GenerateQRTabManager.shared.selectedTab = .barcode
        if let nav = navPath {
            if nav.wrappedValue.count >= 2 {
                nav.wrappedValue.removeLast(2)
            } else if !nav.wrappedValue.isEmpty {
                nav.wrappedValue.removeLast()
            }
        } else {
            dismiss()
        }
    }
    
    private func generateBarcodeImage() {
        guard let data = barcodeText.data(using: .ascii) else { return }
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(7.0, forKey: "inputQuietSpace")
        
        guard let outputCI = filter.outputImage else { return }
        let scaleX: CGFloat = 3.0
        let scaleY: CGFloat = 3.0
        let transformed = outputCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        if let cgImg = context.createCGImage(transformed, from: transformed.extent) {
            barcodeImage = UIImage(cgImage: cgImg)
        }
    }
}

#Preview {
    BarcodeDetailsView(barcodeText: "59012341", category: .ean8)
}
