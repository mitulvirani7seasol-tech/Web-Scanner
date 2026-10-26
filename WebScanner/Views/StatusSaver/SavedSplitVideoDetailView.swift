//
//  SavedSplitVideoDetailView.swift
//  WebScanner
//
//

import SwiftUI
import AVKit

public struct SavedSplitVideoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var manager = SplitVideoManager.shared
    
    let collection: SavedSplitVideoCollection
    
    @State private var previewVideoURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var shareURLs: [URL] = []
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var currentCollection: SavedSplitVideoCollection? {
        manager.savedCollections.first(where: { $0.id == collection.id }) ?? collection
    }
    
    public init(collection: SavedSplitVideoCollection) {
        self.collection = collection
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 40 : 28) : 18
            
            VStack(spacing: 0) {
                // 1. Top Custom Navigation Header: < Collection Title
                headerBar(horizontalPadding: horizontalPadding)
                
                // 2. Parts List
                if let current = currentCollection, !current.parts.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: isIPad ? 14 : 10) {
                            ForEach(current.parts) { part in
                                partCard(for: part, collectionId: current.id)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                        .frame(maxWidth: isIPad ? .infinity : .infinity)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    Spacer()
                    Text("No parts remaining.".localized)
                        .font(.inter(.medium, size: 15))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    Spacer()
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
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareURLs)
        }
        .sheet(item: $previewVideoURL) { url in
            VideoPlayerSheet(videoURL: url)
        }
        .onChange(of: currentCollection?.parts.count) { newCount in
            if (newCount ?? 0) == 0 {
                dismiss()
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
            
            Text(currentCollection?.title ?? collection.title)
                .font(.inter(.bold, size: isIPad ? 22 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - Part Card
    private func partCard(for part: SplitVideoPart, collectionId: String) -> some View {
        HStack(spacing: 14) {
            // Thumbnail with Play overlay
            ZStack {
                if let thumb = part.thumbnailImage {
                    Image(uiImage: thumb)
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
            .onTapGesture {
                HapticFeedback.generate(.light)
                TR_AdCountViewModel.sharedd.registerTap {
                    previewVideoURL = part.fileURL
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(part.name)
                    .font(.inter(.semiBold, size: isIPad ? 17 : 15))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text("\(part.timeRangeText) (\(part.fileSizeText))")
                    .font(.inter(.regular, size: isIPad ? 14 : 12))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            
            Spacer()
            
            // Menu
            Menu {
                Button(action: {
                    TR_AdCountViewModel.sharedd.registerTap()
                    shareURLs = [part.fileURL]
                    showShareSheet = true
                }) {
                    Label("Share".localized, systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive, action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        manager.deletePart(partId: part.id, fromCollectionId: collectionId)
                        let remaining = manager.savedCollections.first(where: { $0.id == collectionId })?.parts.count ?? 0
                        if remaining == 0 {
                            dismiss()
                        }
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
}
