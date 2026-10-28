//
//  StatusSaverView.swift
//  WebScanner
//
//

import SwiftUI
import Photos
import QuickLook
import AVKit

// MARK: - Date Section Model
public struct MediaDateSection: Identifiable {
    public var id: String { title }
    public let title: String
    public let date: Date
    public var items: [StatusMediaItem]
}

public struct StatusSaverView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Int = 0
    @State private var photos: [StatusMediaItem] = []
    @State private var videos: [StatusMediaItem] = []
    @State private var isLoading: Bool = false
    @State private var hasPermission: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var previewURL: URL?
    @State private var selectedItemIds: Set<String> = []
    @State private var showDeleteConfirmAlert: Bool = false
    @State private var showSavedToast: Bool = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var activeItems: [StatusMediaItem] {
        selectedTab == 0 ? photos : videos
    }
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 40 : 28) : 16
            
            ZStack(alignment: .bottom) {
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerBar(horizontalPadding: horizontalPadding)
                    
                    segmentedControl
                        .padding(.top, isIPad ? 14 : 10)
                        .padding(.bottom, isIPad ? 16 : 12)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(AppColors.primaryGreen)
                            .scaleEffect(1.2)
                        Spacer()
                    } else if activeItems.isEmpty {
                        emptyStateView
                    } else {
                        mediaGridView(items: activeItems, horizontalPadding: horizontalPadding)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                if !selectedItemIds.isEmpty {
                    bottomActionBar(horizontalPadding: horizontalPadding)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
                
                if showSavedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                            .foregroundColor(AppColors.primaryGreen)
                        
                        Text("Saved".localized)
                            .font(.inter(.semiBold, size: isIPad ? 16 : 14))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, isIPad ? 24 : 20)
                    .padding(.vertical, isIPad ? 14 : 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#1E2A30").opacity(0.95))
                            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
                    )
                    .padding(.bottom, isIPad ? 40 : 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
            requestPhotoPermission()
        }
        .quickLookPreview($previewURL)
        .alert("Photo Access Required".localized, isPresented: $showPermissionAlert) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Open Settings".localized) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please allow photo library access in Settings to view and save status media.".localized)
        }
        .alert("Delete Items".localized, isPresented: $showDeleteConfirmAlert) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Delete".localized, role: .destructive) {
                deleteSelectedItems()
            }
        } message: {
            Text("Are you sure you want to delete the selected items?".localized)
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
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Saved Status".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 4)
    }
    
    // MARK: - Segmented Control [ Photo | Video ]
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            tabButton(
                title: "Photo".localized,
                iconSelected: "ic_selected_Photo",
                iconUnselected: "ic_Photo",
                index: 0
            )
            
            tabButton(
                title: "Video".localized,
                iconSelected: "ic_ic_selected_Video",
                iconUnselected: "ic_video",
                index: 1
            )
        }
        .padding(3)
        .frame(width: isIPad ? 320 : 250, height: isIPad ? 50 : 42)
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
        .glassModifier()
    }
    
    private func tabButton(
        title: String,
        iconSelected: String,
        iconUnselected: String,
        index: Int
    ) -> some View {
        let isSelected = selectedTab == index
        return Button(action: {
            TR_AdCountViewModel.sharedd.registerTap()
            HapticFeedback.generate(.selection)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = index
                selectedItemIds.removeAll()
            }
        }) {
            HStack(spacing: 8) {
                Image(isSelected ? iconSelected : iconUnselected)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 20 : 16, height: isIPad ? 20 : 16)
                
                Text(title)
                    .font(.inter(isSelected ? .bold : .medium, size: isIPad ? 16 : 14))
            }
            .foregroundColor(isSelected ? .white : AppColors.textSecondary(for: colorScheme))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(AppColors.primaryGreen)
                            .shadow(color: AppColors.primaryGreen.opacity(0.35), radius: 5, x: 0, y: 2)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty State View (Image 1)
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Image("ic_Empty_Status")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isIPad ? 110 : 80, height: isIPad ? 110 : 80)
            
            Text("Nothing Saved Yet".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 18))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.top, 16)
            
            Text("Save your favorite statuses for later.".localized)
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
    
    // MARK: - Media Grid View Grouped by Date (Image 2 & 3)
    private func mediaGridView(items: [StatusMediaItem], horizontalPadding: CGFloat) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        let sections = groupedSections(for: items)
        
        return ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: isIPad ? 22 : 16) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
                        Text(section.title)
                            .font(.inter(.bold, size: isIPad ? 19 : 16))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            .padding(.horizontal, 2)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(section.items) { item in
                                mediaGridCell(for: item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 6)
            .padding(.bottom, selectedItemIds.isEmpty ? 32 : 110)
        }
    }
    
    // MARK: - Media Grid Cell Component
    private func mediaGridCell(for item: StatusMediaItem) -> some View {
        let isSelected = selectedItemIds.contains(item.id)
        let cellHeight: CGFloat = isIPad ? 220 : 120
        
        return ZStack(alignment: .topLeading) {
            Group {
                if let thumb = item.thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: cellHeight)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: isIPad ? 20 : 16, style: .continuous)
                        .fill(AppColors.card(for: colorScheme))
                        .frame(height: cellHeight)
                        .overlay(ProgressView())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: isIPad ? 20 : 16, style: .continuous))
            
            if item.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 7))
                            Text(item.durationText)
                                .font(.inter(.medium, size: 9))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.65))
                        .clipShape(Capsule())
                        .padding(6)
                    }
                }
            }
            
            Button(action: {
                toggleSelection(for: item)
            }) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isIPad ? 26 : 22, height: isIPad ? 26 : 22)
                            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: isIPad ? 13 : 11, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                            .background(Circle().fill(Color.black.opacity(0.12)))
                            .frame(width: isIPad ? 26 : 22, height: isIPad ? 26 : 22)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(8)
        }
        .contentShape(RoundedRectangle(cornerRadius: isIPad ? 20 : 16, style: .continuous))
        .onTapGesture {
            if !selectedItemIds.isEmpty {
                toggleSelection(for: item)
            } else {
                openPreview(for: item)
            }
        }
        .onLongPressGesture {
            toggleSelection(for: item)
        }
    }
    
    // MARK: - Floating Bottom Action Bar (Image 4)
    private func bottomActionBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Selected".localized)
                    .font(.inter(.medium, size: isIPad ? 14 : 12))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                
                Text(String(format: "%02d", selectedItemIds.count))
                    .font(.inter(.bold, size: isIPad ? 22 : 18))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
            }
            .padding(.leading, isIPad ? 24 : 18)
            
            Spacer()
            
            HStack(spacing: isIPad ? 32 : 24) {
                actionButton(
                    title: "Save".localized,
                    iconName: "ic_status_Save"
                ) {
                    saveSelectedItems()
                }
                
                actionButton(
                    title: "Share".localized,
                    iconName: "ic_status_Share"
                ) {
                    shareSelectedItems()
                }
                
                actionButton(
                    title: "Delete".localized,
                    iconName: "ic_status_Delete",
                    isDestructive: false
                ) {
                    showDeleteConfirmAlert = true
                }
            }
            .padding(.trailing, isIPad ? 24 : 18)
        }
        .frame(maxWidth: isIPad ? 600 : .infinity)
        .frame(height: isIPad ? 80 : 70)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 28 : 24, style: .continuous)
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
        .glassModifier(cornerRadius: 24)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 14)
    }
    
    private func actionButton(
        title: String,
        iconName: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 24 : 20, height: isIPad ? 24 : 20)
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text(title)
                    .font(.inter(.medium, size: isIPad ? 13 : 11))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
    }
    
    // MARK: - Grouping Logic
    private func groupedSections(for items: [StatusMediaItem]) -> [MediaDateSection] {
        let calendar = Calendar.current
        var sectionsDict: [String: (date: Date, items: [StatusMediaItem])] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        for item in items {
            let key: String
            let normalizedDate: Date
            
            if calendar.isDateInToday(item.creationDate) {
                key = "Today".localized
                normalizedDate = calendar.startOfDay(for: item.creationDate)
            } else if calendar.isDateInYesterday(item.creationDate) {
                key = "Yesterday".localized
                normalizedDate = calendar.startOfDay(for: item.creationDate)
            } else {
                key = dateFormatter.string(from: item.creationDate)
                normalizedDate = calendar.startOfDay(for: item.creationDate)
            }
            
            if sectionsDict[key] != nil {
                sectionsDict[key]?.items.append(item)
            } else {
                sectionsDict[key] = (date: normalizedDate, items: [item])
            }
        }
        
        return sectionsDict.map { (key, val) in
            MediaDateSection(title: key, date: val.date, items: val.items)
        }.sorted { sec1, sec2 in
            if calendar.isDateInToday(sec1.date) { return true }
            if calendar.isDateInToday(sec2.date) { return false }
            if calendar.isDateInYesterday(sec1.date) { return true }
            if calendar.isDateInYesterday(sec2.date) { return false }
            return sec1.date > sec2.date
        }
    }
    
    // MARK: - Actions
    private func toggleSelection(for item: StatusMediaItem) {
        HapticFeedback.generate(.selection)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            if selectedItemIds.contains(item.id) {
                selectedItemIds.remove(item.id)
            } else {
                selectedItemIds.insert(item.id)
            }
        }
    }
    
    private func saveSelectedItems() {
        HapticFeedback.generate(.medium)
        let allItems = photos + videos
        let selected = allItems.filter { selectedItemIds.contains($0.id) }
        
        for item in selected {
            if item.isVideo {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                PHImageManager.default().requestAVAsset(forVideo: item.asset, options: options) { avAsset, _, _ in
                    if let urlAsset = avAsset as? AVURLAsset {
                        UISaveVideoAtPathToSavedPhotosAlbum(urlAsset.url.path, nil, nil, nil)
                    }
                }
            } else {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                PHImageManager.default().requestImageDataAndOrientation(for: item.asset, options: options) { data, _, _, _ in
                    if let data = data, let img = UIImage(data: data) {
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    } else if let img = item.thumbnail {
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    }
                }
            }
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedItemIds.removeAll()
            showSavedToast = true
        }
        HapticFeedback.generate(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showSavedToast = false
            }
        }
    }
    
    private func shareSelectedItems() {
        HapticFeedback.generate(.light)
        let allItems = photos + videos
        let selected = allItems.filter { selectedItemIds.contains($0.id) }
        guard !selected.isEmpty else { return }
        
        var toShare: [Any] = []
        let group = DispatchGroup()
        let imageManager = PHImageManager.default()
        
        for item in selected {
            if item.isVideo {
                group.enter()
                let options = PHVideoRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                imageManager.requestAVAsset(forVideo: item.asset, options: options) { avAsset, _, _ in
                    if let urlAsset = avAsset as? AVURLAsset {
                        DispatchQueue.main.async {
                            let source = StatusShareActivityItemSource(item: urlAsset.url, title: "Status Video", thumbnail: item.thumbnail)
                            toShare.append(source)
                            group.leave()
                        }
                    } else if let asset = avAsset {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
                        if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
                            exportSession.outputURL = tempURL
                            exportSession.outputFileType = .mp4
                            exportSession.exportAsynchronously {
                                DispatchQueue.main.async {
                                    if exportSession.status == .completed {
                                        let source = StatusShareActivityItemSource(item: tempURL, title: "Status Video", thumbnail: item.thumbnail)
                                        toShare.append(source)
                                    }
                                    group.leave()
                                }
                            }
                        } else {
                            DispatchQueue.main.async { group.leave() }
                        }
                    } else {
                        DispatchQueue.main.async { group.leave() }
                    }
                }
            } else {
                group.enter()
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                imageManager.requestImageDataAndOrientation(for: item.asset, options: options) { data, _, _, _ in
                    DispatchQueue.main.async {
                        if let data = data, let image = UIImage(data: data) {
                            let source = StatusShareActivityItemSource(item: image, title: "Status Photo", thumbnail: image)
                            toShare.append(source)
                        } else if let img = item.thumbnail {
                            let source = StatusShareActivityItemSource(item: img, title: "Status Photo", thumbnail: img)
                            toShare.append(source)
                        }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !toShare.isEmpty {
                ShareHelper.share(items: toShare)
            }
        }
    }
    
    private func shareSingleMedia(_ item: StatusMediaItem) {
        if item.isVideo {
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: item.asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    DispatchQueue.main.async {
                        let source = StatusShareActivityItemSource(item: urlAsset.url, title: "Status Video", thumbnail: item.thumbnail)
                        ShareHelper.share(items: [source])
                    }
                } else if let asset = avAsset {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
                    if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
                        exportSession.outputURL = tempURL
                        exportSession.outputFileType = .mp4
                        exportSession.exportAsynchronously {
                            if exportSession.status == .completed {
                                DispatchQueue.main.async {
                                    let source = StatusShareActivityItemSource(item: tempURL, title: "Status Video", thumbnail: item.thumbnail)
                                    ShareHelper.share(items: [source])
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            PHImageManager.default().requestImageDataAndOrientation(for: item.asset, options: options) { data, _, _, _ in
                DispatchQueue.main.async {
                    if let data = data, let image = UIImage(data: data) {
                        let source = StatusShareActivityItemSource(item: image, title: "Status Photo", thumbnail: image)
                        ShareHelper.share(items: [source])
                    } else if let img = item.thumbnail {
                        let source = StatusShareActivityItemSource(item: img, title: "Status Photo", thumbnail: img)
                        ShareHelper.share(items: [source])
                    }
                }
            }
        }
    }
    
    private func deleteSelectedItems() {
        let allItems = photos + videos
        let idsToDelete = selectedItemIds
        let assetsToDelete = allItems.filter { idsToDelete.contains($0.id) }.map { $0.asset }
        guard !assetsToDelete.isEmpty else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    HapticFeedback.generate(.success)
                    for id in idsToDelete {
                        StatusSaverHelper.removeSavedAssetId(id)
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        self.photos.removeAll { idsToDelete.contains($0.id) }
                        self.videos.removeAll { idsToDelete.contains($0.id) }
                        self.selectedItemIds.removeAll()
                    }
                }
            }
        }
    }
    
    // MARK: - Photo Library Fetching
    private func requestPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            hasPermission = true
            loadMedia()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.hasPermission = true
                        self.loadMedia()
                    } else {
                        self.showPermissionAlert = true
                    }
                }
            }
        default:
            showPermissionAlert = true
        }
    }
    
    private func loadMedia() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let savedIDs = StatusSaverHelper.savedAssetIDs
            guard !savedIDs.isEmpty else {
                DispatchQueue.main.async {
                    self.photos = []
                    self.videos = []
                    self.isLoading = false
                }
                return
            }
            
            let fetchOpts = PHFetchOptions()
            fetchOpts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: savedIDs, options: fetchOpts)
            
            var fetchedPhotos: [StatusMediaItem] = []
            var fetchedVideos: [StatusMediaItem] = []
            
            if assets.count > 0 {
                let imageManager = PHImageManager.default()
                let requestOpts = PHImageRequestOptions()
                requestOpts.isSynchronous = true
                requestOpts.deliveryMode = .highQualityFormat
                let isPad = UIDevice.current.userInterfaceIdiom == .pad
                let targetThumbSize = isPad ? CGSize(width: 800, height: 800) : CGSize(width: 400, height: 400)
                
                assets.enumerateObjects { asset, _, _ in
                    let cDate = asset.creationDate ?? Date()
                    if asset.mediaType == .image {
                        imageManager.requestImage(
                            for: asset,
                            targetSize: targetThumbSize,
                            contentMode: .aspectFill,
                            options: requestOpts
                        ) { image, _ in
                            if let img = image {
                                fetchedPhotos.append(StatusMediaItem(
                                    id: asset.localIdentifier,
                                    asset: asset,
                                    thumbnail: img,
                                    isVideo: false,
                                    duration: 0,
                                    creationDate: cDate
                                ))
                            }
                        }
                    } else if asset.mediaType == .video {
                        imageManager.requestImage(
                            for: asset,
                            targetSize: targetThumbSize,
                            contentMode: .aspectFill,
                            options: requestOpts
                        ) { image, _ in
                            fetchedVideos.append(StatusMediaItem(
                                id: asset.localIdentifier,
                                asset: asset,
                                thumbnail: image,
                                isVideo: true,
                                duration: asset.duration,
                                creationDate: cDate
                            ))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.photos = fetchedPhotos
                self.videos = fetchedVideos
                self.isLoading = false
            }
        }
    }
    
    private func openPreview(for item: StatusMediaItem) {
        if item.isVideo {
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: item.asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    DispatchQueue.main.async {
                        self.previewURL = urlAsset.url
                    }
                }
            }
        } else {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            PHImageManager.default().requestImageDataAndOrientation(for: item.asset, options: options) { data, uti, _, _ in
                if let data = data {
                    let ext = (uti?.lowercased().contains("png") == true) ? "png" : "jpg"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
                    try? data.write(to: tempURL)
                    DispatchQueue.main.async {
                        self.previewURL = tempURL
                    }
                } else if let img = item.thumbnail {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
                    if let data = img.jpegData(compressionQuality: 0.95) {
                        try? data.write(to: tempURL)
                        DispatchQueue.main.async {
                            self.previewURL = tempURL
                        }
                    }
                }
            }
        }
    }
}

// MARK: - StatusMediaItem Model
public struct StatusMediaItem: Identifiable, Hashable {
    public let id: String
    public let asset: PHAsset
    public let thumbnail: UIImage?
    public let isVideo: Bool
    public let duration: TimeInterval
    public let creationDate: Date
    
    public init(
        id: String,
        asset: PHAsset,
        thumbnail: UIImage?,
        isVideo: Bool,
        duration: TimeInterval,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.asset = asset
        self.thumbnail = thumbnail
        self.isVideo = isVideo
        self.duration = duration
        self.creationDate = creationDate
    }
    
    public var durationText: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    StatusSaverView()
}
