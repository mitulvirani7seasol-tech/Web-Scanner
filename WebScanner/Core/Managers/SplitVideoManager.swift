//
//  SplitVideoManager.swift
//  WebScanner
//
//

import Foundation
import UIKit
import AVFoundation
import Photos
import Combine

public struct SplitVideoPart: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var timeRangeText: String
    public var fileSizeBytes: Int64
    public var localFileName: String
    public var thumbnailFileName: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        timeRangeText: String,
        fileSizeBytes: Int64,
        localFileName: String,
        thumbnailFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.timeRangeText = timeRangeText
        self.fileSizeBytes = fileSizeBytes
        self.localFileName = localFileName
        self.thumbnailFileName = thumbnailFileName
    }
    
    public var fileSizeText: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
    
    public var fileURL: URL {
        SplitVideoManager.splitVideosDirectory.appendingPathComponent(localFileName)
    }
    
    public var thumbnailURL: URL? {
        guard let thumbName = thumbnailFileName else { return nil }
        return SplitVideoManager.thumbnailsDirectory.appendingPathComponent(thumbName)
    }
    
    public var thumbnailImage: UIImage? {
        guard let url = thumbnailURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

public struct SavedSplitVideoCollection: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var date: Date
    public var parts: [SplitVideoPart]
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        date: Date = Date(),
        parts: [SplitVideoPart]
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.parts = parts
    }
    
    public var formattedSubtitle: String {
        let countText = "\(parts.count) " + (parts.count == 1 ? "Video".localized : "Videos".localized)
        let timeAgo = date.timeAgoDisplay()
        return "\(countText) • \(timeAgo)"
    }
    
    public var coverImage: UIImage? {
        parts.first?.thumbnailImage
    }
}

@MainActor
public final class SplitVideoManager: ObservableObject {
    public static let shared = SplitVideoManager()
    
    @Published public var savedCollections: [SavedSplitVideoCollection] = []
    
    private static let storageKey = "SavedSplitVideoCollections_Storage"
    
    public static var splitVideosDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("SplitVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public static var thumbnailsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("SplitVideoThumbnails", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {
        loadSavedCollections()
    }
    
    public func loadSavedCollections() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([SavedSplitVideoCollection].self, from: data) else {
            return
        }
        self.savedCollections = decoded
    }
    
    public func saveCollection(_ collection: SavedSplitVideoCollection) {
        if let idx = savedCollections.firstIndex(where: { $0.id == collection.id }) {
            savedCollections[idx] = collection
        } else {
            savedCollections.insert(collection, at: 0)
        }
        persist()
    }
    
    public func deleteCollection(withId id: String) {
        guard let collection = savedCollections.first(where: { $0.id == id }) else { return }
        for part in collection.parts {
            try? FileManager.default.removeItem(at: part.fileURL)
            if let thumbURL = part.thumbnailURL {
                try? FileManager.default.removeItem(at: thumbURL)
            }
        }
        savedCollections.removeAll { $0.id == id }
        persist()
    }
    
    public func deletePart(partId: String, fromCollectionId collectionId: String) {
        guard let colIndex = savedCollections.firstIndex(where: { $0.id == collectionId }) else { return }
        if let partIndex = savedCollections[colIndex].parts.firstIndex(where: { $0.id == partId }) {
            let part = savedCollections[colIndex].parts[partIndex]
            try? FileManager.default.removeItem(at: part.fileURL)
            if let thumbURL = part.thumbnailURL {
                try? FileManager.default.removeItem(at: thumbURL)
            }
            savedCollections[colIndex].parts.remove(at: partIndex)
            if savedCollections[colIndex].parts.isEmpty {
                savedCollections.remove(at: colIndex)
            }
            persist()
        }
    }
    
    private func persist() {
        if let encoded = try? JSONEncoder().encode(savedCollections) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }
    
    // MARK: - Video Splitting Operation
    public func splitVideo(
        sourceURL: URL,
        baseName: String,
        splitDurationSeconds: Double,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> [SplitVideoPart] {
        let asset = AVURLAsset(url: sourceURL)
        let totalDuration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(totalDuration)
        guard totalSeconds > 0 else { return [] }
        
        let partCount = max(1, Int(ceil(totalSeconds / splitDurationSeconds)))
        var generatedParts: [SplitVideoPart] = []
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 480, height: 480)
        
        let safeName = baseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "My_Video_Part"
            : baseName.replacingOccurrences(of: " ", with: "_")
        
        for i in 0..<partCount {
            let startSec = Double(i) * splitDurationSeconds
            let endSec = min(Double(i + 1) * splitDurationSeconds, totalSeconds)
            
            let startTime = CMTime(seconds: startSec, preferredTimescale: 600)
            let durationTime = CMTime(seconds: endSec - startSec, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: startTime, duration: durationTime)
            
            let uniquePartId = UUID().uuidString
            let outputFileName = "\(safeName)_\(i + 1)_\(uniquePartId.prefix(6)).mp4"
            let outputURL = Self.splitVideosDirectory.appendingPathComponent(outputFileName)
            
            try? FileManager.default.removeItem(at: outputURL)
            
            var thumbFileName: String? = nil
            do {
                let cgImage = try imageGenerator.copyCGImage(at: startTime, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                if let data = uiImage.jpegData(compressionQuality: 0.8) {
                    let tName = "thumb_\(uniquePartId.prefix(8)).jpg"
                    let tURL = Self.thumbnailsDirectory.appendingPathComponent(tName)
                    try? data.write(to: tURL)
                    thumbFileName = tName
                }
            } catch {
            }
            
            // Export Session
            guard let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetHighestQuality
            ) else {
                continue
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.timeRange = timeRange
            exportSession.shouldOptimizeForNetworkUse = true
            
            await exportSession.export()
            
            if exportSession.status == .completed {
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0
                let startText = formatTimestamp(seconds: startSec)
                let endText = formatTimestamp(seconds: endSec)
                
                let part = SplitVideoPart(
                    id: uniquePartId,
                    name: "Video \(i + 1)",
                    timeRangeText: "\(startText) - \(endText)",
                    fileSizeBytes: fileSize,
                    localFileName: outputFileName,
                    thumbnailFileName: thumbFileName
                )
                generatedParts.append(part)
            }
            
            let currentProgress = Double(i + 1) / Double(partCount)
            progressHandler(currentProgress)
        }
        
        return generatedParts
    }
    
    public func saveAllPartsToCameraRoll(parts: [SplitVideoPart]) {
        for part in parts {
            if FileManager.default.fileExists(atPath: part.fileURL.path) {
                UISaveVideoAtPathToSavedPhotosAlbum(part.fileURL.path, nil, nil, nil)
            }
        }
    }
    
    private func formatTimestamp(seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        if secondsAgo < 60 {
            return "Just Now".localized
        }
        let minutes = secondsAgo / 60
        if minutes < 60 {
            return "\(minutes) " + (minutes == 1 ? "Minute Ago".localized : "Minutes Ago".localized)
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours) " + (hours == 1 ? "Hour Ago".localized : "Hours Ago".localized)
        }
        let days = hours / 24
        return "\(days) " + "Days Ago".localized
    }
}
