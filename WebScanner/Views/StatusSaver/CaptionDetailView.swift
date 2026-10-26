//
//  CaptionDetailView.swift
//  WebScanner
//
//

import SwiftUI

public struct CaptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let category: CaptionCategory
    
    @State private var copiedCaption: String? = nil
    @State private var shareText: String? = nil
    @State private var showShareSheet: Bool = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(category: CaptionCategory) {
        self.category = category
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 40 : 28) : 18
            
            VStack(spacing: 0) {
                // 1. Top Custom Navigation Header: < [Category Name] Caption
                headerBar(horizontalPadding: horizontalPadding)
                
                // 2. Captions List
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: isIPad ? 16 : 14) {
                        ForEach(Array(category.captions.enumerated()), id: \.offset) { _, caption in
                            captionCard(for: caption)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 16 : 12)
                    .padding(.bottom, isIPad ? 40 : 28)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
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
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .sheet(isPresented: $showShareSheet) {
            if let text = shareText {
                ActivityView(activityItems: [text])
            }
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
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("\(category.title.localized) \("Caption".localized)")
                .font(.inter(.bold, size: isIPad ? 22 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - Caption Card
    private func captionCard(for caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Caption text
            Text(caption)
                .font(.inter(.medium, size: isIPad ? 17 : 14.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, isIPad ? 20 : 16)
                .padding(.top, isIPad ? 18 : 14)
                .padding(.bottom, isIPad ? 16 : 12)
            
            // Divider
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                .frame(height: 0.8)
                .padding(.horizontal, isIPad ? 16 : 12)
            
            // Actions (Copy & Share)
            HStack(spacing: 0) {
                // Copy Button
                Button(action: {
                    HapticFeedback.generate(.medium)
                    TR_AdCountViewModel.sharedd.registerTap()
                    UIPasteboard.general.string = caption
                    withAnimation(.easeInOut(duration: 0.2)) {
                        copiedCaption = caption
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedCaption == caption {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                copiedCaption = nil
                            }
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        if copiedCaption == caption {
                            Image(systemName: "checkmark")
                                .font(.system(size: isIPad ? 16 : 13.scaled, weight: .semibold))
                                .foregroundColor(AppColors.primaryGreen)
                            
                            Text("Copied!".localized)
                                .font(.inter(.semiBold, size: isIPad ? 15 : 13.scaled))
                                .foregroundColor(AppColors.primaryGreen)
                        } else {
                            Image("ic_copy")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: isIPad ? 18 : 15.scaled, height: isIPad ? 18 : 15.scaled)
                            
                            Text("Copy".localized)
                                .font(.inter(.medium, size: isIPad ? 15 : 13.scaled))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 46 : 38)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Vertical Separator
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                    .frame(width: 0.8, height: isIPad ? 22 : 18)
                
                // Share Button
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    shareText = caption
                    showShareSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image("ic_status_Share")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 18 : 15.scaled, height: isIPad ? 18 : 15.scaled)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text("Share".localized)
                            .font(.inter(.medium, size: isIPad ? 15 : 13.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 46 : 38)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
//        .background(
//            RoundedRectangle(cornerRadius: isIPad ? 22 : 16, style: .continuous)
//                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.85))
//                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: isIPad ? 22 : 16, style: .continuous))
//        )
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 22 : 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.30 : 0.80),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
//        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04), radius: 6, x: 0, y: 3)
        .glassModifier(cornerRadius: isIPad ? 22 : 16)
    }
}

#Preview {
    CaptionDetailView(category: CaptionStatusData.categories[2])
}
