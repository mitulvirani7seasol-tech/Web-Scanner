//
//  CaptionStatusListView.swift
//  WebScanner
//
//

import SwiftUI

public struct CaptionStatusListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedCategory: CaptionCategory? = nil
    @State private var navigateToDetail: Bool = false
    
    private let categories = CaptionStatusData.categories
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var horizontalPadding: CGFloat {
        isIPad ? 32 : 18
    }
    
    private var gridColumns: [GridItem] {
        let count = isIPad ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: isIPad ? 18 : 12), count: count)
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Custom Navigation Header: < Caption Status
            headerBar
            
            // 2. Categories Grid
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: isIPad ? 18 : 12) {
                    ForEach(categories) { category in
                        categoryCard(for: category)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isIPad ? 18 : 14)
                .padding(.bottom, isIPad ? 40 : 32)
                .frame(maxWidth: isIPad ? .infinity : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .navigationDestination(isPresented: $navigateToDetail) {
            if let category = selectedCategory {
                CaptionDetailView(category: category)
            }
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
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
            
            Text("Caption Status".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - Category Card
    private func categoryCard(for category: CaptionCategory) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap {
                selectedCategory = category
                navigateToDetail = true
            }
        }) {
            VStack(spacing: isIPad ? 10 : 8) {
                Image(category.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 56 : 42.scaled, height: isIPad ? 56 : 42.scaled)
                
                Text(category.title.localized)
                    .font(.inter(.medium, size: isIPad ? 16 : 13.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 140 : 106.scaled)
//            .background(
//                RoundedRectangle(cornerRadius: isIPad ? 22 : 16, style: .continuous)
//                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.88))
//            )
            .overlay(
                RoundedRectangle(cornerRadius: isIPad ? 22 : 16, style: .continuous)
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
//            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.04), radius: 6, x: 0, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: isIPad ? 22 : 16, style: .continuous))
            .glassModifier(cornerRadius: isIPad ? 22 : 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CaptionStatusListView()
}
