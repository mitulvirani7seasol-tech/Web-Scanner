//
//  AddQuickReplyMessageView.swift
//  WebScanner
//
//

import SwiftUI

public struct AddQuickReplyMessageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTextEditorFocused: Bool
    
    @State private var messageText: String = ""
    @State private var selectedCategory: String = "Greetings"
    @State private var isDropdownOpen: Bool = false
    
    private let categories = QuickReplyData.categories
    private let maxCharacters = 500
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var canSave: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedCategory.isEmpty
    }
    
    public init() {}
    
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
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: isIPad ? 26 : 22.scaled) {
                        // Section 1: Add Quick Reply
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Add Quick Reply".localized)
                                .font(.inter(.bold, size: isIPad ? 20 : 18.scaled))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            textEditorBox
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Category".localized)
                                .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            categoryDropdownMenu
                        }
                        
                        saveButton
                            .padding(.top, isIPad ? 22 : 16)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 18 : 14)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 20)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }

        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .onChange(of: isTextEditorFocused) { focused in
            if focused && isDropdownOpen {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDropdownOpen = false
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
                if isDropdownOpen {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDropdownOpen = false
                    }
                }
            }
        )
    }
    
    // MARK: - Header Bar
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismissKeyboard()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Add Message".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 10 : 6)
    }
    
    // MARK: - Text Editor Box
    private var textEditorBox: some View {
        ZStack(alignment: .topLeading) {
            // Text Editor
            TextEditor(text: Binding(
                get: { messageText },
                set: { newValue in
                    if newValue.count <= maxCharacters {
                        messageText = newValue
                    } else {
                        messageText = String(newValue.prefix(maxCharacters))
                    }
                }
            ))
            .focused($isTextEditorFocused)
            .scrollContentBackground(.hidden)
            .font(.inter(.regular, size: isIPad ? 16 : 14.scaled))
            .foregroundColor(AppColors.textPrimary(for: colorScheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .padding(.bottom, 28)
            
            if messageText.isEmpty {
                Text("Type your message here...".localized)
                    .font(.inter(.regular, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.65))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(messageText.count)/\(maxCharacters)")
                        .font(.inter(.medium, size: 12))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(height: isIPad ? 180 : 150.scaled)
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
    
    // MARK: - Category Dropdown Menu
    private var categoryDropdownMenu: some View {
        VStack(spacing: 8) {
            // Main Selector Header Box
            Button(action: {
                HapticFeedback.generate(.light)
                dismissKeyboard()
                withAnimation(.easeInOut(duration: 0.22)) {
                    isDropdownOpen.toggle()
                }
            }) {
                HStack {
                    Text(selectedCategory.isEmpty ? "Choose a category".localized : selectedCategory.localized)
                        .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(
                            selectedCategory.isEmpty
                                ? AppColors.textSecondary(for: colorScheme)
                                : AppColors.textPrimary(for: colorScheme)
                        )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        .rotationEffect(.degrees(isDropdownOpen ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 56 : 48.scaled)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                .glassModifier(cornerRadius: 14)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isDropdownOpen {
                VStack(spacing: 0) {
                    ForEach(Array(categories.enumerated()), id: \.element) { index, cat in
                        Button(action: {
                            HapticFeedback.generate(.selection)
                            selectedCategory = cat
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDropdownOpen = false
                            }
                        }) {
                            HStack {
                                if selectedCategory == cat {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AppColors.primaryGreen)
                                } else {
                                    Spacer().frame(width: 13)
                                }
                                
                                Text(cat.localized)
                                    .font(.inter(selectedCategory == cat ? .semiBold : .regular, size: isIPad ? 15 : 14.scaled))
                                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                                    .padding(.leading, 6)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .frame(height: isIPad ? 48 : 42.scaled)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < categories.count - 1 {
                            Rectangle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                                .frame(height: 0.8)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                .glassModifier(cornerRadius: 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            guard canSave else { return }
            HapticFeedback.generate(.success)
            dismissKeyboard()
            QuickReplyManager.shared.addMessage(text: messageText, category: selectedCategory)
            TR_AdCountViewModel.sharedd.registerTap {
                dismiss()
            }
        }) {
            Text("Save Message".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 56 : 48.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(canSave ? Color(hex: "#16A34A") : Color(hex: "#16A34A").opacity(0.5))
                )
                .shadow(
                    color: canSave ? Color(hex: "#16A34A").opacity(0.35) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .disabled(!canSave)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func dismissKeyboard() {
        isTextEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AddQuickReplyMessageView()
}
