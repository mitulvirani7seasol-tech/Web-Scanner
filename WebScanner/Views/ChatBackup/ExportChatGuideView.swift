//
//  ExportChatGuideView.swift
//  WebScanner
//
//

import SwiftUI

public enum GuideTab: Int, CaseIterable, Identifiable {
    case export = 0
    case importChat = 1
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .export: return "Export Chat".localized
        case .importChat: return "Import Chat".localized
        }
    }
    
    public var iconName: String {
        switch self {
        case .export: return "square.and.arrow.up"
        case .importChat: return "square.and.arrow.down"
        }
    }
}

public struct GuideStep: Identifiable {
    public let id: Int
    public let imageName: String
    public let description: String
}

public struct ExportChatGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab: GuideTab = .export
    @State private var currentStepIndex: Int = 0
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // MARK: - Steps Data
    private let exportSteps: [GuideStep] = [
        GuideStep(
            id: 0,
            imageName: "Export_Chat_1",
            description: "Open the chat section, swipe left on any conversation, and tap 'More'.".localized
        ),
        GuideStep(
            id: 1,
            imageName: "Export_Chat_2",
            description: "Tap on Contact or Group info.".localized
        ),
        GuideStep(
            id: 2,
            imageName: "Export_Chat_3",
            description: "Tap on Export Chat.".localized
        ),
        GuideStep(
            id: 3,
            imageName: "Export_Chat_4",
            description: "Choose Attach Media or Without Media.".localized
        ),
        GuideStep(
            id: 4,
            imageName: "Export_Chat_5",
            description: "Tap on Saved to Files.".localized
        )
    ]
    
    private let importSteps: [GuideStep] = [
        GuideStep(
            id: 0,
            imageName: "Import_Chat_1",
            description: "Open the app and tap on WA Backup Chats.".localized
        ),
        GuideStep(
            id: 1,
            imageName: "Import_Chat_2",
            description: "Tap Import Backup Chat.".localized
        ),
        GuideStep(
            id: 2,
            imageName: "Import_Chat_3",
            description: "Choose Wp Chat.".localized
        )
    ]
    
    private var activeSteps: [GuideStep] {
        selectedTab == .export ? exportSteps : importSteps
    }
    
    private var totalSteps: Int {
        activeSteps.count
    }
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 48 : 32) : 18
            
            VStack(spacing: 0) {
                headerBar(horizontalPadding: horizontalPadding)
                
                tabSelector
                    .frame(maxWidth: isIPad ? 520 : .infinity)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? (isLandscape ? 8 : 14) : 8)
                
                stepBadge
                    .padding(.top, isIPad ? (isLandscape ? 10 : 16) : 12)
                
                stepDescriptionText
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? (isLandscape ? 8 : 12) : 10)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                
                devicePreviewCarousel(geo: geo, isLandscape: isLandscape)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                
                bottomControls(isLandscape: isLandscape)
                    .padding(.top, isIPad ? (isLandscape ? 4 : 10) : 6)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom + (isIPad ? (isLandscape ? 8 : 14) : 6), isIPad ? (isLandscape ? 16 : 24) : 14))
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
        .onChange(of: selectedTab) { _ in
            currentStepIndex = 0
        }
    }
    
    // MARK: - Header Bar
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: {
                HapticFeedback.generate(.light)
                TabBarManager.shared.isHidden = true
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
            
            Text("Export Chat Guide".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 6)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
    }
    
    // MARK: - Liquid Glass Segmented Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(GuideTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    HapticFeedback.generate(.light)
                    currentStepIndex = 0
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: isIPad ? 18 : 14, weight: .semibold))
                        
                        Text(tab.title)
                            .font(.inter(isSelected ? .bold : .medium, size: isIPad ? 17 : 14))
                    }
                    .foregroundColor(isSelected ? .white : AppColors.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 52 : 42)
                    .background(
                        Group {
                            if isSelected {
                                Capsule()
                                    .fill(AppColors.primaryGreen)
                                    .shadow(color: AppColors.primaryGreen.opacity(0.35), radius: 6, x: 0, y: 3)
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(0)
        .background(
            Capsule()
                .fill(
                    colorScheme == .dark
                        ? Color.clear
                        : Color.clear
                )
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
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 6, x: 0, y: 2)
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
        .id("\(selectedTab.rawValue)_badge_\(safeCurrentStepIndex)")
        .padding(.horizontal, isIPad ? 22 : 16)
        .padding(.vertical, isIPad ? 8 : 6)
        .background(
            Capsule()
                .fill(
                    colorScheme == .dark
                        ? Color.clear
                        : Color.clear
                )
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
    
    // MARK: - Step Description Text (No Text Cutoff or Overlap)
    private var stepDescriptionText: some View {
        let currentStep = activeSteps[safeCurrentStepIndex]
        return Text(currentStep.description)
            .font(.inter(.semiBold, size: isIPad ? 20 : 15))
            .foregroundColor(AppColors.textPrimary(for: colorScheme))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .id("\(selectedTab.rawValue)_desc_\(safeCurrentStepIndex)")
    }
    
    // MARK: - Device Preview Carousel
    private func devicePreviewCarousel(geo: GeometryProxy, isLandscape: Bool) -> some View {
        TabView(selection: $currentStepIndex) {
            ForEach(activeSteps) { step in
                VStack {
                    Spacer(minLength: 0)
                    
                    Image(step.imageName)
                        .resizable()
                        .aspectRatio(contentMode: isIPad ? .fit : .fill)
                        .frame(
                            maxWidth: isIPad
                                ? (isLandscape ? (geo.size.width * 0.36) : (geo.size.width * 0.68))
                                : (geo.size.width * 0.82),
                            maxHeight: isIPad
                                ? (isLandscape ? (geo.size.height * 0.56) : (geo.size.height * 0.60))
                                : (geo.size.height * 0.52)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 12, x: 0, y: 6)
                    
                    Spacer(minLength: 0)
                }
                .tag(step.id)
            }
        }
        .id(selectedTab)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bottom Controls (< and >)
    private func bottomControls(isLandscape: Bool) -> some View {
        HStack(spacing: isIPad ? (isLandscape ? 24 : 32) : 20) {
            Button(action: {
                if currentStepIndex > 0 {
                    HapticFeedback.generate(.light)
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
        let size: CGFloat = isIPad ? (isLandscape ? 50 : 60) : 50
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
                .font(.system(size: isIPad ? (isLandscape ? 18 : 22) : 17, weight: .bold))
                .foregroundColor(
                    enabled
                        ? AppColors.textPrimary(for: colorScheme)
                        : AppColors.textSecondary(for: colorScheme).opacity(0.35)
                )
        }
        .opacity(enabled ? 1.0 : 0.45)
    }
    
    private var safeCurrentStepIndex: Int {
        min(max(currentStepIndex, 0), max(totalSteps - 1, 0))
    }
}

#Preview {
    ExportChatGuideView()
}
