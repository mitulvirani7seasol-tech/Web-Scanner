//
//  QuickMessagesView.swift
//  WebScanner
//
//

import SwiftUI

public struct QuickMessagesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedMessage: String
    @Binding var selectedPill: String?
    
    @State private var copiedMessage: String? = nil
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(selectedMessage: Binding<String>, selectedPill: Binding<String?>) {
        self._selectedMessage = selectedMessage
        self._selectedPill = selectedPill
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background image
//                Image(colorScheme == .dark ? "BG_Dark" : "BG")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: geo.size.width, height: geo.size.height)
//                    .clipped()
//                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Bar (Matching Image 2)
                    headerBar(topInset: geo.safeAreaInsets.top)
                    
                    // List of Quick Messages
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: isIPad ? 14 : 12.scaled) {
                            ForEach(QuickMessageManager.defaultMessages, id: \.self) { message in
                                quickMessageRow(message)
                            }
                        }
                        .padding(.horizontal, isIPad ? 32 : 16)
                        .padding(.top, 12)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 20)
                        .frame(maxWidth: isIPad ? .infinity : .infinity)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .onDisappear {
            TabBarManager.shared.isHidden = false
        }
    }
    
    // MARK: - Header Bar (Matching Image 2: < Quick Messages)
    private func headerBar(topInset: CGFloat) -> some View {
        HStack(spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 44, height: isIPad ? 44 : 44)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Quick Messages".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, isIPad ? 32 : 16)
        .padding(.top, isIPad ? 14 : 8)
        .padding(.bottom, 12)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Quick Message Row (Matching Image 2)
    private func quickMessageRow(_ message: String) -> some View {
        Button(action: {
            HapticFeedback.generate(.selection)
            selectedMessage = message
            selectedPill = message
            TR_AdCountViewModel.sharedd.registerTap {
                dismiss()
            }
        }) {
            HStack(alignment: .center, spacing: 14.scaled) {
                Text(message)
                    .font(.inter(.semiBold, size: isIPad ? 16 : 15.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Copy Icon (Matching Image 2)
                Button(action: {
                    HapticFeedback.generate(.medium)
                    TR_AdCountViewModel.sharedd.registerTap()
                    UIPasteboard.general.string = message
                    copiedMessage = message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if copiedMessage == message {
                            copiedMessage = nil
                        }
                    }
                }) {
                    ZStack {
                        if copiedMessage == message {
                            Image(systemName: "checkmark")
                                .font(.system(size: isIPad ? 18 : 15.scaled, weight: .semibold))
                                .foregroundColor(AppColors.primaryGreen)
                        } else {
                            Image("ic_copy")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: isIPad ? 22 : 18.scaled, height: isIPad ? 22 : 18.scaled)
                        }
                    }
                    .frame(width: isIPad ? 36 : 30, height: isIPad ? 36 : 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, isIPad ? 18 : 16.scaled)
            .padding(.vertical, isIPad ? 18 : 16.scaled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 16.scaled)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
    }
}
