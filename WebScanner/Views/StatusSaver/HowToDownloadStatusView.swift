//
//  HowToDownloadStatusView.swift
//  WebScanner
//
//

import SwiftUI

public struct StatusGuideStep: Identifiable {
    public let id: Int
    public let imageName: String
    public let description: String
}

public struct HowToDownloadStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentStepIndex: Int = 0
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // MARK: - Steps Data
    private let steps: [StatusGuideStep] = [
        StatusGuideStep(
            id: 0,
            imageName: "How_to_download_1",
            description: "Click on the status you want to download.".localized
        ),
        StatusGuideStep(
            id: 1,
            imageName: "How_to_download_2",
            description: "Click on download button.".localized
        )
    ]
    
    private var totalSteps: Int {
        steps.count
    }
    
    private var safeCurrentStepIndex: Int {
        min(max(currentStepIndex, 0), max(totalSteps - 1, 0))
    }
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 48 : 32) : 18
            
            VStack(spacing: 20) {
                headerBar(horizontalPadding: horizontalPadding)
                
                stepBadge
                    .padding(.top, isIPad ? (isLandscape ? 12 : 20) : 0)
                
                stepDescriptionText
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? (isLandscape ? 10 : 16) : 0)
                
                devicePreviewCarousel(geo: geo, isLandscape: isLandscape)
                
                bottomControls(isLandscape: isLandscape)
                    .padding(.top, isIPad ? (isLandscape ? 8 : 14) : 8)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom + (isIPad ? (isLandscape ? 12 : 0) : 0), isIPad ? (isLandscape ? 20 : 0) : 0))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
    }
    
    // MARK: - Header Bar
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 24 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 48 : 36, height: isIPad ? 48 : 36)
                    .contentShape(Rectangle())
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("How to download?".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 6)
    }
    
    // MARK: - Liquid Glass Step Badge (STEP X OF Y)
    private var stepBadge: some View {
        HStack(spacing: 5) {
            Text("STEP \(safeCurrentStepIndex + 1)".localized)
                .font(.inter(.bold, size: isIPad ? 15 : 12))
                .foregroundColor(AppColors.primaryGreen)
            
            Text("OF \(totalSteps)".localized)
                .font(.inter(.semiBold, size: isIPad ? 15 : 12))
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
        }
        .id("badge_\(safeCurrentStepIndex)")
        .padding(.horizontal, isIPad ? 22 : 16)
        .padding(.vertical, isIPad ? 8 : 6)
        .background(
            Capsule()
                .fill(Color.clear)
                .background(.ultraThinMaterial, in: Capsule())
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.04), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Step Description Text
    private var stepDescriptionText: some View {
        let currentStep = steps[safeCurrentStepIndex]
        return Text(currentStep.description)
            .font(.inter(.semiBold, size: isIPad ? 20 : 15))
            .foregroundColor(AppColors.textPrimary(for: colorScheme))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .id("desc_\(safeCurrentStepIndex)")
    }
    
    // MARK: - Device Preview Carousel
    private func devicePreviewCarousel(geo: GeometryProxy, isLandscape: Bool) -> some View {
        TabView(selection: $currentStepIndex) {
            ForEach(steps) { step in
                VStack {
                    Spacer(minLength: 0)
                    
                    Image(step.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            maxWidth: isIPad
                                ? (isLandscape ? (geo.size.width * 0.52) : (geo.size.width * 0.92))
                                : (geo.size.width * 0.99),
                            maxHeight: isIPad
                                ? (isLandscape ? (geo.size.height * 0.68) : (geo.size.height * 0.68))
                                : (geo.size.height * 0.65)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 12, x: 0, y: 6)
                    
                    Spacer(minLength: 0)
                }
                .tag(step.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bottom Controls (< and >)
    private func bottomControls(isLandscape: Bool) -> some View {
        HStack(spacing: isIPad ? (isLandscape ? 24 : 32) : 20) {
            Button(action: {
                if currentStepIndex > 0 {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStepIndex -= 1
                    }
                }
            }) {
                arrowCircle(systemName: "chevron.left", enabled: currentStepIndex > 0, isLandscape: isLandscape)
            }
            .disabled(currentStepIndex == 0)
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
            
            Button(action: {
                if currentStepIndex < totalSteps - 1 {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStepIndex += 1
                    }
                }
            }) {
                arrowCircle(systemName: "chevron.right", enabled: currentStepIndex < totalSteps - 1, isLandscape: isLandscape)
            }
            .disabled(currentStepIndex == totalSteps - 1)
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
        }
    }
    
    private func arrowCircle(systemName: String, enabled: Bool, isLandscape: Bool) -> some View {
        let size: CGFloat = isIPad ? (isLandscape ? 52 : 62) : 52
        return ZStack {
            Circle()
                .fill(
                    colorScheme == .dark
                        ? Color(hex: "#1E222B").opacity(0.85)
                        : Color.white.opacity(0.85)
                )
                .background(.ultraThinMaterial, in: Circle())
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                                    Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 6, x: 0, y: 3)
            
            Image(systemName: systemName)
                .font(.system(size: isIPad ? (isLandscape ? 18 : 22) : 18, weight: .bold))
                .foregroundColor(
                    enabled
                        ? AppColors.textPrimary(for: colorScheme)
                        : AppColors.textSecondary(for: colorScheme).opacity(0.35)
                )
        }
        .opacity(enabled ? 1.0 : 0.45)
    }
}

#Preview {
    HowToDownloadStatusView()
}
