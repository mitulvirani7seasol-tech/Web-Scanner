//
//  WS_AppUpdateManager.swift
//  WebScanner
//
//  Created by Kushang kaklotar on 19/10/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class TR_AppUpdateManager: ObservableObject {
    static let shared = TR_AppUpdateManager()
    
    @Published var showUpdateAlert: Bool = false
    @Published var isUpdateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var currentVersion: String = ""
    @Published var releaseNotes: String = ""
    @Published var appStoreURL: URL? = nil
    @Published var isChecking: Bool = false
    
    private var hasCheckedInSession = false
    private var completionHandlers: [((Bool) -> Void)] = []
    
    private init() {
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        self.appStoreURL = URL(string: APPURL)
    }
    
    /// Checks App Store for latest available version.
    /// Does not directly force alert display so callers can sequence presentations properly with other screens.
    func checkForUpdate(forcePrompt: Bool = false, completion: ((Bool) -> Void)? = nil) {
        if let completion = completion {
            if hasCheckedInSession && !isChecking {
                completion(isUpdateAvailable)
                return
            }
            completionHandlers.append(completion)
        }
        
        if !forcePrompt && hasCheckedInSession { return }
        hasCheckedInSession = true
        isChecking = true
        
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let lookupURLString: String
        if AppId != 0 {
            lookupURLString = "https://itunes.apple.com/lookup?id=\(AppId)"
        } else {
            lookupURLString = "https://itunes.apple.com/lookup?bundleId=\(bundleID)"
        }
        
        guard let url = URL(string: lookupURLString) else {
            self.isChecking = false
            self.notifyCompletions(isAvailable: false)
            return
        }
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 8.0
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.isChecking = false
                    self.notifyCompletions(isAvailable: false)
                    return
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let firstResult = results.first,
                      let storeVersion = firstResult["version"] as? String else {
                    self.isChecking = false
                    self.notifyCompletions(isAvailable: false)
                    return
                }
                
                self.latestVersion = storeVersion
                self.releaseNotes = (firstResult["releaseNotes"] as? String) ?? ""
                
                if let trackUrlStr = firstResult["trackViewUrl"] as? String, let trackUrl = URL(string: trackUrlStr) {
                    self.appStoreURL = trackUrl
                } else {
                    self.appStoreURL = URL(string: APPURL)
                }
                
                let currentVer = self.currentVersion
                let isNewer = storeVersion.compare(currentVer, options: .numeric) == .orderedDescending
                
                self.isChecking = false
                self.isUpdateAvailable = isNewer
                if isNewer {
                    print("🔔 [AppUpdate] New version available: \(storeVersion) (Current: \(currentVer))")
                } else {
                    print("✅ [AppUpdate] App is up to date: \(currentVer) (App Store: \(storeVersion))")
                }
                self.notifyCompletions(isAvailable: isNewer)
            } catch {
                self.isChecking = false
                self.isUpdateAvailable = false
                print("⚠️ [AppUpdate] Failed to check for app update: \(error.localizedDescription)")
                self.notifyCompletions(isAvailable: false)
            }
        }
    }
    
    private func notifyCompletions(isAvailable: Bool) {
        let handlers = completionHandlers
        completionHandlers.removeAll()
        for handler in handlers {
            handler(isAvailable)
        }
    }
    
    /// Presents the update alert directly if an update is available.
    func promptUpdateIfAvailable() {
        if isUpdateAvailable {
            self.showUpdateAlert = true
        }
    }
    
    /// Opens the App Store page for this application
    func openAppStore() {
        let targetURL = appStoreURL ?? URL(string: APPURL) ?? URL(string: "https://apps.apple.com/app/id\(AppId)")!
        if UIApplication.shared.canOpenURL(targetURL) {
            UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
        }
    }
}

typealias AppUpdateManager = TR_AppUpdateManager

