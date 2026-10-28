//
//  QuickReplyView.swift
//  WebScanner
//
//

import SwiftUI

public enum QuickReplyTab {
    case templates
    case saved
}

public struct QuickReplyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var quickReplyManager = QuickReplyManager.shared
    
    @State private var currentTab: QuickReplyTab = .templates
    @State private var selectedCategory: String = "All"
    @State private var copiedMessageId: String? = nil
    @State private var navigateToAddMessage: Bool = false
    @State private var messageToDelete: SavedQuickReplyMessage? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var shareItem: ShareTextItem? = nil
    
    private var navPath: Binding<NavigationPath>?
    
    private let pillCategories = ["All"] + QuickReplyData.categories
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(navPath: Binding<NavigationPath>? = nil) {
        self.navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 48 : 32) : 18
            
            ZStack(alignment: .bottom) {
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerBar(horizontalPadding: horizontalPadding)
                    
                    if currentTab == .templates {
                        categoryPillsBar(horizontalPadding: horizontalPadding)
                        
                        templatesList(horizontalPadding: horizontalPadding)
                    } else {
                        savedList(horizontalPadding: horizontalPadding)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                floatingBottomBar
                    .padding(.bottom, 12)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
            quickReplyManager.loadSavedMessages()
        }
        .navigationDestination(isPresented: $navigateToAddMessage) {
            AddQuickReplyMessageView()
        }
        .alert("Are you sure you want to delete this message.".localized, isPresented: $showDeleteAlert, presenting: messageToDelete) { item in
            Button("No".localized, role: .cancel) {
                messageToDelete = nil
            }
            Button("Yes".localized, role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    quickReplyManager.deleteMessage(id: item.id)
                }
                messageToDelete = nil
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.text])
        }
    }
    
    // MARK: - Header Bar (< Quick Replay  [+] )
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Quick Replay".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            if currentTab == .saved {
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap {
                        if let nav = navPath {
                            nav.wrappedValue.append(HomeDestination.addQuickReplyMessage)
                        } else {
                            navigateToAddMessage = true
                        }
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: isIPad ? 20 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                        .background(
                            Circle()
                                .fill(Color(hex: "#16A34A"))
                        )
                        .shadow(color: Color(hex: "#16A34A").opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 6)
    }
    
    // MARK: - Category Pills Bar
    private func categoryPillsBar(horizontalPadding: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(pillCategories, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    Button(action: {
                        HapticFeedback.generate(.selection)
                        TR_AdCountViewModel.sharedd.registerTap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat
                        }
                    }) {
                        Text(cat.localized)
                            .font(.inter(isSelected ? .bold : .medium, size: isIPad ? 15 : 13.scaled))
                            .foregroundColor(
                                isSelected
                                    ? .white
                                    : AppColors.textPrimary(for: colorScheme).opacity(0.75)
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        isSelected
                                            ? Color(hex: "#16A34A")
                                            : (colorScheme == .dark ? Color.clear : Color.clear)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isSelected
                                            ? Color.clear
                                            : Color.white.opacity(colorScheme == .dark ? 0.2 : 0.8),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .glassModifier(cornerRadius: 18)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Templates List
    private func templatesList(horizontalPadding: CGFloat) -> some View {
        let items = QuickReplyData.templates(for: selectedCategory)
        
        return ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: isIPad ? 16 : 12.scaled) {
                ForEach(items) { item in
                    templateCard(item: item)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 110)
            .frame(maxWidth: isIPad ? .infinity : .infinity)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Template Card Component
    private func templateCard(item: QuickReplyTemplate) -> some View {
        let isCopied = copiedMessageId == item.id
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(item.text)
                    .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.category.localized)
                    .font(.inter(.regular, size: isIPad ? 13 : 11.scaled))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.8))
            }
            
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                .frame(height: 0.8)
                .padding(.vertical, 2)
            
            HStack(spacing: 0) {
                Button(action: {
                    TR_AdCountViewModel.sharedd.registerTap()
                    copyMessage(id: item.id, text: item.text)
                }) {
                    HStack(spacing: 6) {
                        if isCopied {
                            Image(systemName: "checkmark")
                                .font(.system(size: isIPad ? 14 : 12.scaled, weight: .bold))
                                .foregroundColor(AppColors.primaryGreen)
                            
                            Text("Copied!".localized)
                                .font(.inter(.semiBold, size: isIPad ? 14 : 12.scaled))
                                .foregroundColor(AppColors.primaryGreen)
                        } else {
                            Image("ic_copy")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: isIPad ? 16 : 13.scaled, height: isIPad ? 16 : 13.scaled)
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            Text("Copy".localized)
                                .font(.inter(.medium, size: isIPad ? 14 : 12.scaled))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                    .frame(width: 0.8, height: 18)
                
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    shareItem = ShareTextItem(text: item.text)
                }) {
                    HStack(spacing: 6) {
                        Image("ic_status_Share")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 16 : 13.scaled, height: isIPad ? 16 : 13.scaled)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text("Share".localized)
                            .font(.inter(.medium, size: isIPad ? 14 : 12.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, isIPad ? 18 : 16.scaled)
        .padding(.top, isIPad ? 16 : 14.scaled)
        .padding(.bottom, isIPad ? 10 : 8.scaled)
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
    
    // MARK: - Saved List / Empty State
    private func savedList(horizontalPadding: CGFloat) -> some View {
        let savedItems = quickReplyManager.savedMessages
        
        return Group {
            if savedItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    
                    Image("ic_empty_save_massage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isIPad ? 120 : 96.scaled, height: isIPad ? 120 : 96.scaled)
                        .padding(.bottom, 6)
                    
                    Text("No Saved Messages Yet".localized)
                        .font(.inter(.bold, size: isIPad ? 20 : 17.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Text("Save your favorite replies for quick access.".localized)
                        .font(.inter(.regular, size: isIPad ? 15 : 13.scaled))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 110)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: isIPad ? 16 : 12.scaled) {
                        ForEach(savedItems) { item in
                            savedCard(item: item)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 110)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Saved Card Component (Copy | Delete)
    private func savedCard(item: SavedQuickReplyMessage) -> some View {
        let isCopied = copiedMessageId == item.id.uuidString
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(item.text)
                    .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.category.localized)
                    .font(.inter(.regular, size: isIPad ? 13 : 11.scaled))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.8))
            }
            
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                .frame(height: 0.8)
                .padding(.vertical, 2)
            
            HStack(spacing: 0) {
                Button(action: {
                    TR_AdCountViewModel.sharedd.registerTap()
                    copyMessage(id: item.id.uuidString, text: item.text)
                }) {
                    HStack(spacing: 6) {
                        if isCopied {
                            Image(systemName: "checkmark")
                                .font(.system(size: isIPad ? 14 : 12.scaled, weight: .bold))
                                .foregroundColor(AppColors.primaryGreen)
                            
                            Text("Copied!".localized)
                                .font(.inter(.semiBold, size: isIPad ? 14 : 12.scaled))
                                .foregroundColor(AppColors.primaryGreen)
                        } else {
                            Image("ic_copy")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: isIPad ? 16 : 13.scaled, height: isIPad ? 16 : 13.scaled)
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            Text("Copy".localized)
                                .font(.inter(.medium, size: isIPad ? 14 : 12.scaled))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))
                    .frame(width: 0.8, height: 18)
                
                // Share Action
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    shareItem = ShareTextItem(text: item.text)
                }) {
                    HStack(spacing: 6) {
                        Image("ic_status_Share")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 16 : 13.scaled, height: isIPad ? 16 : 13.scaled)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text("Share".localized)
                            .font(.inter(.medium, size: isIPad ? 14 : 12.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Vertical Divider
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08))
                    .frame(width: 0.8, height: 18)
                
                // Delete Action
                Button(action: {
                    HapticFeedback.generate(.medium)
                    TR_AdCountViewModel.sharedd.registerTap()
                    messageToDelete = item
                    showDeleteAlert = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: isIPad ? 14 : 12.scaled, weight: .medium))
                            .foregroundColor(Color(hex: "#FF3B30"))
                        
                        Text("Delete".localized)
                            .font(.inter(.medium, size: isIPad ? 14 : 12.scaled))
                            .foregroundColor(Color(hex: "#FF3B30"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, isIPad ? 18 : 16.scaled)
        .padding(.top, isIPad ? 16 : 14.scaled)
        .padding(.bottom, isIPad ? 10 : 8.scaled)
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
    
    // MARK: - Floating Bottom Bar (Templates | Saved)
    private var floatingBottomBar: some View {
        HStack(spacing: 0) {
            // Templates Button
            Button(action: {
                if currentTab != .templates {
                    HapticFeedback.generate(.selection)
                    TR_AdCountViewModel.sharedd.registerTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentTab = .templates
                    }
                }
            }) {
                VStack(spacing: 4) {
                    if currentTab == .templates {
                        Image("ic_Templates_selected")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 36)
                            .background(Capsule().fill(Color(hex: "#16A34A")))
                    } else {
                        Image("ic_Templates")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                            .frame(width: 50, height: 36)
                    }
                    
                    Text("Templates".localized)
                        .font(.inter(currentTab == .templates ? .bold : .medium, size: 11))
                        .foregroundColor(
                            currentTab == .templates
                                ? Color(hex: "#16A34A")
                                : AppColors.textSecondary(for: colorScheme)
                        )
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Saved Button
            Button(action: {
                if currentTab != .saved {
                    HapticFeedback.generate(.selection)
                    TR_AdCountViewModel.sharedd.registerTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentTab = .saved
                    }
                }
            }) {
                VStack(spacing: 4) {
                    if currentTab == .saved {
                        Image("ic_Saved_selected")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 36)
                            .background(
                                Capsule()
                                .fill(Color(hex: "#16A34A")))
                    } else {
                        Image("ic_Saved")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                            .frame(width: 50, height: 36)
                    }
                    
                    Text("Saved".localized)
                        .font(.inter(currentTab == .saved ? .bold : .medium, size: 11))
                        .foregroundColor(
                            currentTab == .saved
                                ? Color(hex: "#16A34A")
                                : AppColors.textSecondary(for: colorScheme)
                        )
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(width: isIPad ? 260 : 220, height: isIPad ? 80 : 75)

        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.9),
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .glassModifier(cornerRadius: 32)
    }
    
    // MARK: - Helper Copy
    private func copyMessage(id: String, text: String) {
        HapticFeedback.generate(.light)
        UIPasteboard.general.string = text
        withAnimation(.easeInOut(duration: 0.2)) {
            copiedMessageId = id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedMessageId == id {
                withAnimation(.easeInOut(duration: 0.2)) {
                    copiedMessageId = nil
                }
            }
        }
    }
}

#Preview {
    QuickReplyView()
}
