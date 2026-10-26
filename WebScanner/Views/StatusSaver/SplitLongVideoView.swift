//
//  SplitLongVideoView.swift
//  WebScanner
//
//

import SwiftUI
import PhotosUI
import AVKit
import CoreTransferable
import UniformTypeIdentifiers

public struct MovieTransferable: Transferable {
    public let url: URL
    
    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempDest = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).mp4")
            try? FileManager.default.removeItem(at: tempDest)
            try FileManager.default.copyItem(at: received.file, to: tempDest)
            return MovieTransferable(url: tempDest)
        }
    }
}

public struct DurationOption: Identifiable, Equatable {
    public let id: Int // seconds
    public let title: String
}

public struct SplitLongVideoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var navPath: Binding<NavigationPath>?
    
    // Picker & Video state
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var selectedVideoThumbnail: UIImage? = nil
    @State private var selectedVideoDurationText: String = "00:00"
    @State private var selectedVideoDurationSeconds: Double = 0
    @State private var isLoadingVideo: Bool = false
    
    // Configuration
    @State private var selectedDurationIndex: Int = 1 // Default to 30 Seconds
    @State private var fileName: String = ""
    @FocusState private var isFileNameFocused: Bool
    
    private var isFileNameValid: Bool {
        !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Splitting
    @State private var isSplitting: Bool = false
    @State private var splitProgress: Double = 0.0
    @State private var generatedParts: [SplitVideoPart] = []
    
    // Navigation destinations
    @State private var navigateToSaveParts: Bool = false
    @State private var navigateToSavedVideos: Bool = false
    @State private var previewPlayerURL: URL? = nil
    
    // Duration options: 15s, 30s (Default), 1 Min, 2 Min, 3 Min ... 30 Min (+1 min each after 1 min)
    private static func buildDurationOptions() -> [DurationOption] {
        var options: [DurationOption] = [
            DurationOption(id: 15, title: "15 " + "Seconds".localized),
            DurationOption(id: 30, title: "30 " + "Seconds".localized)
        ]
        for min in 1...30 {
            let title = "\(min) " + (min == 1 ? "Minute".localized : "Minutes".localized)
            options.append(DurationOption(id: min * 60, title: title))
        }
        return options
    }
    
    private let durationOptions: [DurationOption] = SplitLongVideoView.buildDurationOptions()
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(navPath: Binding<NavigationPath>? = nil) {
        self.navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 40 : 28) : 18
            
            ZStack {
                // Background
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
                
                VStack(spacing: 0) {
                    // 1. Top Custom Navigation Header: < Split Long Video      [Folder Icon]
                    headerBar(horizontalPadding: horizontalPadding)
                    
                    if selectedVideoURL == nil {
                        // SCREEN 1: Choose a Video State
                        emptyChooseVideoView
                    } else {
                        // SCREEN 2: Video Configuration State
                        videoConfigView(horizontalPadding: horizontalPadding)
                    }
                    
                    // Bottom Button (hidden when keyboard is open so TextField is fully visible)
                    if !isFileNameFocused {
                        bottomActionButton(horizontalPadding: horizontalPadding)
                    }
                }
//                .frame(width: geo.size.width, height: geo.size.height)
                .frame(maxWidth: isIPad ? .infinity : .infinity)
                
                // Loading Overlay for Picker
                if isLoadingVideo {
                    loadingPickerOverlay
                }
                
                // Splitting Progress Overlay
                if isSplitting {
                    splittingProgressOverlay
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    dismissKeyboard()
                }
            )
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .onChange(of: selectedPickerItem) { newItem in
            handlePickerSelection(newItem)
        }
        .navigationDestination(isPresented: $navigateToSaveParts) {
            SaveSplitVideoView(
                isPresented: $navigateToSaveParts,
                parts: generatedParts,
                videoTitle: fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "My_Video_Part"
                    : fileName,
                onSaveAllSuccess: {
                    withAnimation {
                        selectedVideoURL = nil
                        selectedVideoThumbnail = nil
                        selectedPickerItem = nil
                        fileName = ""
                    }
                    navigateToSaveParts = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        navigateToSavedVideos = true
                    }
                }
            )
        }
        .navigationDestination(isPresented: $navigateToSavedVideos) {
            SavedSplitVideosListView()
        }
        .sheet(item: $previewPlayerURL) { url in
            VideoPlayerSheet(videoURL: url)
        }
    }
    
    // MARK: - Header Bar
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: {
                HapticFeedback.generate(.light)
                if selectedVideoURL != nil {
                    // Back returns to Choose a Video state
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selectedVideoURL = nil
                        selectedVideoThumbnail = nil
                        selectedPickerItem = nil
                    }
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 24 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 48 : 36, height: isIPad ? 48 : 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Split Long Video".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            // Top Right Folder Icon -> Saved Video Screen (Screen 4)
            if selectedVideoURL == nil {
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap {
                        navigateToSavedVideos = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.85))
                            .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                        
                        Image("ic_donload_video")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 22 : 18, height: isIPad ? 22 : 18)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - SCREEN 1: Empty Choose Video View (Image 1)
    private var emptyChooseVideoView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("ic_empty_split_video")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isIPad ? 110 : 80, height: isIPad ? 110 : 80)
            
            Text("Choose a Video".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 18))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.top, 16)
            
            Text("Choose a video and create multiple parts.".localized)
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
    
    // MARK: - SCREEN 2: Video Configuration View (Image 2)
    private func videoConfigView(horizontalPadding: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: isIPad ? 24 : 18) {
                    // Video Preview Card
                    videoPreviewCard
                    
                    // Select Duration (Per Video)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Duration (Per Video)".localized)
                            .font(.inter(.semiBold, size: isIPad ? 17 : 14))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        durationStepperCard
                    }
                    
                    // File Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File Name".localized)
                            .font(.inter(.semiBold, size: isIPad ? 17 : 14))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        fileNameTextField
                            .id("fileNameField")
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, isIPad ? 120 : 100)
                .frame(maxWidth: isIPad ? .infinity : .infinity)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: isFileNameFocused) { focused in
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("fileNameField", anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Video Preview Card
    private var videoPreviewCard: some View {
        ZStack {
            if let thumb = selectedVideoThumbnail {
                Image(uiImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 540 : 230)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: isIPad ? 26 : 20, style: .continuous)
                    .fill(Color.black.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 540 : 230)
            }
            
            // Duration badge at top-left (e.g. 15:36)
            VStack {
                HStack {
                    Text(selectedVideoDurationText)
                        .font(.inter(.semiBold, size: isIPad ? 13 : 11))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.65))
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                .padding(12)
                Spacer()
            }
            
            // Play Button in center
            Button(action: {
                if let url = selectedVideoURL {
                    HapticFeedback.generate(.light)
                    previewPlayerURL = url
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: isIPad ? 64 : 54, height: isIPad ? 64 : 54)
                        .background(.ultraThinMaterial, in: Circle())
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: isIPad ? 24 : 20, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
        }
        .clipShape(RoundedRectangle(cornerRadius: isIPad ? 26 : 20, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Duration Stepper Card `[-]  5 Minutes  [+]`
    private var durationStepperCard: some View {
        HStack {
            // Minus Button (-)
            Button(action: {
                TR_AdCountViewModel.sharedd.registerTap()
                if selectedDurationIndex > 0 {
                    HapticFeedback.generate(.selection)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedDurationIndex -= 1
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGreen)
                        .frame(width: isIPad ? 38 : 32, height: isIPad ? 38 : 32)
                    
                    Image(systemName: "minus")
                        .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(selectedDurationIndex == 0)
            .opacity(selectedDurationIndex == 0 ? 0.45 : 1.0)
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
            
            Spacer()
            
            // Selected Duration Text
            Text(durationOptions[selectedDurationIndex].title)
                .font(.inter(.bold, size: isIPad ? 17 : 14))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            // Plus Button (+)
            Button(action: {
                TR_AdCountViewModel.sharedd.registerTap()
                if selectedDurationIndex < durationOptions.count - 1 {
                    HapticFeedback.generate(.selection)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedDurationIndex += 1
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGreen)
                        .frame(width: isIPad ? 38 : 32, height: isIPad ? 38 : 32)
                    
                    Image(systemName: "plus")
                        .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .disabled(selectedDurationIndex == durationOptions.count - 1)
            .opacity(selectedDurationIndex == durationOptions.count - 1 ? 0.45 : 1.0)
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
        }
        .padding(.horizontal, isIPad ? 16 : 12)
        .frame(height: isIPad ? 58 : 48)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 18 : 14, style: .continuous)
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
        .glassModifier(cornerRadius: isIPad ? 18 : 14)
    }
    
    // MARK: - File Name Text Field
    private var fileNameTextField: some View {
        HStack {
            TextField("Eg. My_Video_Part".localized, text: $fileName)
                .font(.inter(.regular, size: isIPad ? 16 : 14))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .focused($isFileNameFocused)
                .onSubmit {
                    dismissKeyboard()
                }
        }
        .padding(.horizontal, isIPad ? 18 : 14)
        .frame(height: isIPad ? 58 : 48)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 18 : 14, style: .continuous)
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
        .glassModifier(cornerRadius: isIPad ? 18 : 14)
    }
    
    // MARK: - Bottom Action Button: Choose Video or Split Video
    private func bottomActionButton(horizontalPadding: CGFloat) -> some View {
        Group {
            if selectedVideoURL == nil {
                // PhotosPicker for Choose Video
                PhotosPicker(
                    selection: $selectedPickerItem,
                    matching: .videos
                ) {
                    Text("Choose Video".localized)
                        .font(.inter(.bold, size: isIPad ? 18 : 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 56 : 50)
                        .background(AppColors.primaryGreen)
                        .clipShape(Capsule())
                        .shadow(color: AppColors.primaryGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Button to perform Split Video (Disabled until file name text is entered)
                Button(action: {
                    dismissKeyboard()
                    TR_AdCountViewModel.sharedd.registerTap {
                        startSplittingVideo()
                    }
                }) {
                    Text("Split Video".localized)
                        .font(.inter(.bold, size: isIPad ? 18 : 16))
                        .foregroundColor(isFileNameValid ? .white : Color.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 56 : 50)
                        .background(isFileNameValid ? AppColors.primaryGreen : AppColors.primaryGreen.opacity(0.35))
                        .clipShape(Capsule())
                        .shadow(color: isFileNameValid ? AppColors.primaryGreen.opacity(0.35) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.96))
                .disabled(!isFileNameValid)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 16)
        .frame(maxWidth: isIPad ? .infinity : .infinity)
    }
    
    // MARK: - Overlays
    private var loadingPickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
                Text("Loading Video...".localized)
                    .font(.inter(.medium, size: 14))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }
    
    private var splittingProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(AppColors.primaryGreen)
                    .scaleEffect(1.4)
                
                Text("Splitting Video...".localized)
                    .font(.inter(.bold, size: 17))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text("\(Int(splitProgress * 100))%")
                    .font(.inter(.semiBold, size: 14))
                    .foregroundColor(AppColors.primaryGreen)
                
                Text("Please wait while we split your video.".localized)
                    .font(.inter(.regular, size: 12))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(colorScheme == .dark ? Color(hex: "#1F232D") : Color.white)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 6)
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Logic
    private func handlePickerSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isLoadingVideo = true
        
        Task {
            do {
                if let movie = try await item.loadTransferable(type: MovieTransferable.self) {
                    let asset = AVURLAsset(url: movie.url)
                    let dur = try? await asset.load(.duration)
                    let seconds = dur.map { CMTimeGetSeconds($0) } ?? 0
                    
                    let gen = AVAssetImageGenerator(asset: asset)
                    gen.appliesPreferredTrackTransform = true
                    let cgImg = try? gen.copyCGImage(at: CMTime(seconds: min(1, seconds), preferredTimescale: 600), actualTime: nil)
                    let thumb = cgImg.map { UIImage(cgImage: $0) }
                    
                    let mins = Int(seconds) / 60
                    let secs = Int(seconds) % 60
                    let durText = String(format: "%02d:%02d", mins, secs)
                    
                    await MainActor.run {
                        self.selectedVideoURL = movie.url
                        self.selectedVideoThumbnail = thumb
                        self.selectedVideoDurationSeconds = seconds
                        self.selectedVideoDurationText = durText
                        self.isLoadingVideo = false
                    }
                } else {
                    await MainActor.run { self.isLoadingVideo = false }
                }
            } catch {
                await MainActor.run { self.isLoadingVideo = false }
            }
        }
    }
    
    private func startSplittingVideo() {
        guard let sourceURL = selectedVideoURL else { return }
        HapticFeedback.generate(.medium)
        isSplitting = true
        splitProgress = 0.0
        
        Task {
            do {
                let name = fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "My_Video_Part"
                    : fileName
                let duration = Double(durationOptions[selectedDurationIndex].id)
                
                let parts = try await SplitVideoManager.shared.splitVideo(
                    sourceURL: sourceURL,
                    baseName: name,
                    splitDurationSeconds: duration,
                    progressHandler: { p in
                        DispatchQueue.main.async {
                            self.splitProgress = p
                        }
                    }
                )
                
                await MainActor.run {
                    self.generatedParts = parts
                    self.isSplitting = false
                    self.navigateToSaveParts = true
                }
            } catch {
                await MainActor.run {
                    self.isSplitting = false
                }
            }
        }
    }
    
    private func dismissKeyboard() {
        isFileNameFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SplitLongVideoView()
}
