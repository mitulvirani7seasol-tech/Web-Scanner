//
//  SaveSplitVideoView.swift
//  WebScanner
//
//

import SwiftUI
import AVKit

public struct SaveSplitVideoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var isPresented: Bool
    @State private var parts: [SplitVideoPart]
    private let videoTitle: String
    var onSaveAllSuccess: (() -> Void)? = nil
    
    @State private var previewVideoURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var shareURLs: [URL] = []
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(
        isPresented: Binding<Bool> = .constant(true),
        parts: [SplitVideoPart],
        videoTitle: String,
        onSaveAllSuccess: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self._parts = State(initialValue: parts)
        self.videoTitle = videoTitle
        self.onSaveAllSuccess = onSaveAllSuccess
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 40 : 28) : 18
            
            VStack(spacing: 0) {
                headerBar(horizontalPadding: horizontalPadding)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
                        successBanner
                        
                        Text("Split Video".localized)
                            .font(.inter(.bold, size: isIPad ? 20 : 17))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            .padding(.top, 4)
                        
                        VStack(spacing: isIPad ? 14 : 10) {
                            ForEach(parts) { part in
                                partCard(for: part)
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 16 : 12)
                    .padding(.bottom, isIPad ? 110 : 96)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
                }
                
                saveAllButton(horizontalPadding: horizontalPadding)
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
            ActivityView(activityItems: shareURLs)
        }
        .sheet(item: $previewVideoURL) { url in
            VideoPlayerSheet(videoURL: url)
        }
    }
    
    // MARK: - Header Bar
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: {
                HapticFeedback.generate(.light)
                isPresented = false
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 24 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 48 : 36, height: isIPad ? 48 : 36)
                    .contentShape(Rectangle())
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Save Split Video".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - Success Banner
    private var successBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isIPad ? 36 : 30))
                .foregroundColor(AppColors.primaryGreen)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Video Split Successfully".localized)
                    .font(.inter(.bold, size: isIPad ? 17 : 15))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text("\(parts.count) " + "Video Parts are Ready to Save.".localized)
                    .font(.inter(.regular, size: isIPad ? 14 : 12))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(isIPad ? 18 : 14)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16, style: .continuous)
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
        .glassModifier(cornerRadius: isIPad ? 20 : 16)
        
    }
    
    // MARK: - Part Card
    private func partCard(for part: SplitVideoPart) -> some View {
        HStack(spacing: 14) {
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
                previewVideoURL = part.fileURL
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(part.name)
                    .font(.inter(.semiBold, size: isIPad ? 17 : 15))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text("\(part.timeRangeText) (\(part.fileSizeText))")
                    .font(.inter(.regular, size: isIPad ? 14 : 12))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            
            Spacer()
            
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
                        parts.removeAll { $0.id == part.id }
                        if parts.isEmpty {
                            isPresented = false
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
        .glassModifier(cornerRadius: isIPad ? 20 : 16)

    }
    
    // MARK: - Save All Parts Button
    private func saveAllButton(horizontalPadding: CGFloat) -> some View {
        Button(action: {
            TR_AdCountViewModel.sharedd.registerTap {
                saveAllParts()
            }
        }) {
            Text("Save All Parts".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 56 : 50)
                .background(AppColors.primaryGreen)
                .clipShape(Capsule())
                .shadow(color: AppColors.primaryGreen.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.96))
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 16)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
    }
    
    private func saveAllParts() {
        HapticFeedback.generate(.medium)
        SplitVideoManager.shared.saveAllPartsToCameraRoll(parts: parts)
        
        let collection = SavedSplitVideoCollection(
            title: videoTitle,
            date: Date(),
            parts: parts
        )
        SplitVideoManager.shared.saveCollection(collection)
        
        HapticFeedback.generate(.success)
        if let onSaveAllSuccess = onSaveAllSuccess {
            onSaveAllSuccess()
        } else {
            isPresented = false
        }
    }
}

// MARK: - VideoPlayerSheet Helper
struct VideoPlayerSheet: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            VideoPlayer(player: AVPlayer(url: videoURL))
                .ignoresSafeArea()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
