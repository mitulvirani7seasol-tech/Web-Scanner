//
//  StatusSaverHelper.swift
//  WebScanner
//

import UIKit
import Photos

public final class StatusSaverHelper {
    public static let shared = StatusSaverHelper()
    public static let albumName = "Whats Web"
    
    // MARK: - Local Tracking of Saved Asset Identifiers in this App Install
    private static let savedAssetIDsKey = "saved_status_asset_ids"
    
    public static var savedAssetIDs: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: savedAssetIDsKey) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: savedAssetIDsKey)
        }
    }
    
    public static func recordSavedAssetId(_ id: String) {
        var current = savedAssetIDs
        if !current.contains(id) {
            current.append(id)
            savedAssetIDs = current
        }
    }
    
    public static func removeSavedAssetId(_ id: String) {
        var current = savedAssetIDs
        current.removeAll { $0 == id }
        savedAssetIDs = current
    }
    
    private init() {}
    
    public static func handleStatusMedia(body: Any?, presenter: UIViewController? = nil) {
        guard let dict = body as? [String: Any],
              let base64 = dict["base64Data"] as? String,
              let type = dict["mediaType"] as? String,
              let data = Data(base64Encoded: base64),
              !data.isEmpty else {
            print("❌ Invalid status media data")
            return
        }
        
        saveMedia(data: data, type: type, presenter: presenter)
    }
    
    public static func saveMedia(data: Data, type: String, presenter: UIViewController?) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    showPermissionAlert(presenter: presenter)
                }
                return
            }
            
            getOrCreateAlbum { album in
                guard let album = album else {
                    print("❌ Album creation failed")
                    return
                }
                
                var createdAssetId: String?
                
                PHPhotoLibrary.shared().performChanges({
                    var assetPlaceholder: PHObjectPlaceholder?
                    
                    if type.contains("video") || type.contains("mp4") {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
                        try? data.write(to: tempURL)
                        let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                        assetPlaceholder = request?.placeholderForCreatedAsset
                    } else {
                        if let image = UIImage(data: data) {
                            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                            assetPlaceholder = request.placeholderForCreatedAsset
                        }
                    }
                    
                    createdAssetId = assetPlaceholder?.localIdentifier
                    
                    if let placeholder = assetPlaceholder,
                       let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) {
                        albumChangeRequest.addAssets([placeholder] as NSArray)
                    }
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            if let id = createdAssetId {
                                StatusSaverHelper.recordSavedAssetId(id)
                            }
                            HapticFeedback.generate(.success)
                            showSuccessAlert(presenter: presenter)
                        } else {
                            print("❌ Error saving status: \(error?.localizedDescription ?? "")")
                        }
                    }
                }
            }
        }
    }
    
    private static func getOrCreateAlbum(completion: @escaping (PHAssetCollection?) -> Void) {
        let fetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        for i in 0..<fetch.count {
            let collection = fetch.object(at: i)
            if collection.localizedTitle == albumName {
                completion(collection)
                return
            }
        }
        
        var placeholder: PHObjectPlaceholder?
        try? PHPhotoLibrary.shared().performChangesAndWait {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            placeholder = request.placeholderForCreatedAssetCollection
        }
        
        if let placeholder = placeholder {
            let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
            completion(result.firstObject)
        } else {
            completion(nil)
        }
    }
    
    private static func showSuccessAlert(presenter: UIViewController?) {
        let alert = UIAlertController(
            title: "Saved".localized,
            message: "Status saved in Whats Web folder".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
        presentAlert(alert, fallbackPresenter: presenter)
    }
    
    private static func showPermissionAlert(presenter: UIViewController?) {
        let alert = UIAlertController(
            title: "Permission Required".localized,
            message: "Please allow photo access from Settings to save media.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings".localized, style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
        presentAlert(alert, fallbackPresenter: presenter)
    }
    
    private static func presentAlert(_ alert: UIAlertController, fallbackPresenter: UIViewController?) {
        if let presenter = fallbackPresenter, presenter.view.window != nil {
            presenter.present(alert, animated: true)
            return
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(alert, animated: true)
        }
    }
}
