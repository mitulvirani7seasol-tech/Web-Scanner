//
//  SavedSplitVideosListView.swift
//  WebScanner
//
//

import SwiftUI
import AVKit

public struct SavedSplitVideosListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var manager = SplitVideoManager.shared
    
    @State private var selectedCollection: SavedSplitVideoCollection? = nil
    @State private var showDetail: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareURLs: [URL] = []
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 40 : 28) : 18
            
            VStack(spacing: 0) {
                // 1. Top Custom Navigation Header: < Saved Video
                headerBar(horizontalPadding: horizontalPadding)
                
                // 2. Content
                if manager.savedCollections.isEmpty {
                    emptyStateView
                } else {
                    collectionsListView(horizontalPadding: horizontalPadding)
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
            manager.loadSavedCollections()
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareURLs)
        }
        .navigationDestination(isPresented: $showDetail) {
            if let col = selectedCollection {
                SavedSplitVideoDetailView(collection: col)
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
            
            Text("Saved Video".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("ic_empty_video")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isIPad ? 110 : 80, height: isIPad ? 110 : 80)
            
            Text("No Saved Videos Yet".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 18))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.top, 16)
            
            Text("Split videos you save will appear here.".localized)
                .font(.inter(.regular, size: isIPad ? 15 : 13))
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 6)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Collections List View (Image 4)
    private func collectionsListView(horizontalPadding: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: isIPad ? 14 : 10) {
                ForEach(manager.savedCollections) { collection in
                    collectionCard(for: collection)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 32)
            .frame(maxWidth: isIPad ? .infinity : .infinity)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Collection Card
    private func collectionCard(for collection: SavedSplitVideoCollection) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap {
                selectedCollection = collection
                showDetail = true
            }
        }) {
            HStack(spacing: 14) {
                // Thumbnail with Play overlay
                ZStack {
                    if let cover = collection.coverImage {
                        Image(uiImage: cover)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: isIPad ? 110 : 88, height: isIPad ? 76 : 60)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.4))
                            .frame(width: isIPad ? 110 : 88, height: isIPad ? 76 : 60)
                    }
                    
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .offset(x: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.inter(.semiBold, size: isIPad ? 17 : 15))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    
                    Text(collection.formattedSubtitle)
                        .font(.inter(.regular, size: isIPad ? 14 : 12))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                // Ellipsis Menu
                Menu {
                    Button(action: {
                        TR_AdCountViewModel.sharedd.registerTap()
                        shareURLs = collection.parts.map { $0.fileURL }
                        showShareSheet = true
                    }) {
                        Label("Share".localized, systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            manager.deleteCollection(withId: collection.id)
                        }
                    }) {
                        Label("Delete".localized, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: isIPad ? 20 : 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
            }
            .padding(isIPad ? 14 : 10)
            .overlay(
                RoundedRectangle(cornerRadius: isIPad ? 18 : 14, style: .continuous)
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
            .glassModifier(cornerRadius: isIPad ? 18 : 14)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
    }
}
