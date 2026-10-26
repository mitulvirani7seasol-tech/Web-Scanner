//
//  ShareViewController.swift
//  ExportWpChat
//
//

import UIKit
import UniformTypeIdentifiers
import ZIPFoundation

class ShareViewController: UIViewController {

    let candidateGroups = ["group.com.WebScanner.app", "group.com.WebScanner.app1"]
    
    private var processedChatName: String?

    // MARK: - UI Components
    private let containerCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(red: 0.12, green: 0.17, blue: 0.20, alpha: 0.98) : UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 0.98)
        }
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "bubble.left.and.bubble.right.fill")
        iv.tintColor = UIColor(red: 0.0, green: 0.66, blue: 0.52, alpha: 1.0) // #00A884
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "WebScanner"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Preparing chat..."
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private lazy var openButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Open in WebScanner", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = UIColor(red: 0.0, green: 0.66, blue: 0.52, alpha: 1.0) // WhatsApp Green
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 14
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(openButtonTapped), for: .touchUpInside)
        btn.alpha = 0.0 // Shown once chat is ready
        return btn
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Close", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btn.setTitleColor(.secondaryLabel, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        handleSharedData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        view.addSubview(containerCard)
        containerCard.addSubview(iconImageView)
        containerCard.addSubview(titleLabel)
        containerCard.addSubview(statusLabel)
        containerCard.addSubview(activityIndicator)
        containerCard.addSubview(openButton)
        containerCard.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerCard.widthAnchor.constraint(equalToConstant: 290),
            containerCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 230),

            iconImageView.topAnchor.constraint(equalTo: containerCard.topAnchor, constant: 22),
            iconImageView.centerXAnchor.constraint(equalTo: containerCard.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 42),
            iconImageView.heightAnchor.constraint(equalToConstant: 42),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -16),

            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 14),
            activityIndicator.centerXAnchor.constraint(equalTo: containerCard.centerXAnchor),

            openButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            openButton.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 20),
            openButton.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -20),
            openButton.heightAnchor.constraint(equalToConstant: 46),

            closeButton.topAnchor.constraint(equalTo: openButton.bottomAnchor, constant: 10),
            closeButton.centerXAnchor.constraint(equalTo: containerCard.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: -14)
        ])

        activityIndicator.startAnimating()
    }

    @objc private func openButtonTapped() {
        guard let url = makeRedirectURL(chatName: processedChatName) else {
            close()
            return
        }
        performAppRedirect(url: url, isUserInitiated: true)
    }

    private func makeRedirectURL(chatName: String?) -> URL? {
        let scheme: String
        if let name = chatName, let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            scheme = "webscanner://openChatFromShare?name=\(encoded)"
        } else {
            scheme = "webscanner://openChatFromShare"
        }
        return URL(string: scheme) ?? URL(string: "webscanner://openChatFromShare")
    }

    private func performAppRedirect(url: URL, isUserInitiated: Bool) {
        // Strategy 1: Official extensionContext open
        self.extensionContext?.open(url, completionHandler: { [weak self] success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.close()
                }
            } else if isUserInitiated {
                print("extensionContext open failed, trying fallbacks...")
            }
        })

        if isUserInitiated {
            // Strategy 2: Responder chain traversing for UIApplication
            var responder: UIResponder? = self
            while let r = responder {
                if let application = r as? UIApplication {
                    if #available(iOS 18.0, *) {
                        application.open(url, options: [:]) { [weak self] _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self?.close()
                            }
                        }
                    } else {
                        application.perform(NSSelectorFromString("openURL:"), with: url)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                            self?.close()
                        }
                    }
                    return
                }
                responder = r.next
            }

            // Strategy 3: Dynamic invocation of modern -[UIApplication openURL:options:completionHandler:]
            let sharedSel = NSSelectorFromString("sharedApplication")
            if let appClass = NSClassFromString("UIApplication") as? NSObject.Type,
               let sharedApp = appClass.perform(sharedSel)?.takeUnretainedValue() as? NSObject {
                let modernOpenSel = NSSelectorFromString("openURL:options:completionHandler:")
                if sharedApp.responds(to: modernOpenSel) {
                    typealias OpenFunc = @convention(c) (NSObject, Selector, NSURL, NSDictionary, Any?) -> Void
                    let method = sharedApp.method(for: modernOpenSel)
                    let function = unsafeBitCast(method, to: OpenFunc.self)
                    function(sharedApp, modernOpenSel, url as NSURL, [:] as NSDictionary, nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        self?.close()
                    }
                    return
                }
            }

            // Strategy 4: LSApplicationWorkspace fallback
            let wsName = ["L", "S", "Application", "Workspace"].joined()
            if let wsClass = NSClassFromString(wsName) as? NSObject.Type,
               let ws = wsClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() as? NSObject {
                let openSel = NSSelectorFromString("openURL:")
                if ws.responds(to: openSel) {
                    ws.perform(openSel, with: url)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        self?.close()
                    }
                    return
                }
            }
            
            // Auto close after attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.close()
            }
        }
    }
    
    private func handleSharedData() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        let zipType = UTType.zip.identifier
        let fileURLType = UTType.fileURL.identifier
        let textType = UTType.plainText.identifier
        let dataType = UTType.data.identifier
        
        var foundProvider: NSItemProvider?
        var matchedType: String?
        
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(zipType) {
                    foundProvider = provider
                    matchedType = zipType
                    break
                } else if provider.hasItemConformingToTypeIdentifier(fileURLType) {
                    foundProvider = provider
                    matchedType = fileURLType
                    break
                } else if provider.hasItemConformingToTypeIdentifier(textType) {
                    foundProvider = provider
                    matchedType = textType
                    break
                } else if provider.hasItemConformingToTypeIdentifier(dataType) {
                    foundProvider = provider
                    matchedType = dataType
                    break
                }
            }
            if foundProvider != nil { break }
        }
        
        guard let provider = foundProvider, let typeToLoad = matchedType else {
            close()
            return
        }
        
        provider.loadItem(forTypeIdentifier: typeToLoad, options: nil) { [weak self] (data, error) in
            guard let self = self else { return }
            
            var extractedName = "WhatsApp Chat"
            
            if let url = data as? URL {
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                extractedName = self.processIncomingFile(url)
            } else if let fileData = data as? Data {
                let isZip = typeToLoad == zipType || fileData.prefix(4) == Data([0x50, 0x4B, 0x03, 0x04])
                let ext = isZip ? "zip" : "txt"
                let tempName = provider.suggestedName ?? "WhatsApp Chat"
                let cleanBaseName = tempName.replacingOccurrences(of: ".zip", with: "").replacingOccurrences(of: ".txt", with: "")
                let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(cleanBaseName).\(ext)")
                try? fileData.write(to: tempFile, options: .atomic)
                extractedName = self.processIncomingFile(tempFile)
            } else if let textContent = data as? String {
                let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("WhatsApp Chat.txt")
                try? textContent.write(to: tempFile, atomically: true, encoding: .utf8)
                extractedName = self.processIncomingFile(tempFile)
            } else {
                self.close()
                return
            }
            
            self.processedChatName = extractedName
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.statusLabel.text = "Chat ready: \(extractedName)"
                UIView.animate(withDuration: 0.25) {
                    self.openButton.alpha = 1.0
                }
                
                // Automatically attempt to open the app (will only close if success == true)
                if let url = self.makeRedirectURL(chatName: extractedName) {
                    self.performAppRedirect(url: url, isUserInitiated: false)
                }
            }
        }
    }
    
    private func getBackupDestinationDirectories() -> [URL] {
        var dirs: [URL] = []
        for group in candidateGroups {
            if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
                let destDir = container.appendingPathComponent("ChatBackups", isDirectory: true)
                if !FileManager.default.fileExists(atPath: destDir.path) {
                    try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true, attributes: nil)
                }
                dirs.append(destDir)
            }
        }
        return dirs
    }
    
    @discardableResult
    private func processIncomingFile(_ url: URL) -> String {
        let destDirs = getBackupDestinationDirectories()
        let chatFolderName = url.deletingPathExtension().lastPathComponent
        guard !destDirs.isEmpty else {
            print("No valid App Group containers found")
            return chatFolderName
        }

        let ext = url.pathExtension.lowercased()
        
        for destDir in destDirs {
            if ext == "zip" {
                let destZipURL = destDir.appendingPathComponent(url.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: destZipURL.path) {
                        try? FileManager.default.removeItem(at: destZipURL)
                    }
                    let data = try Data(contentsOf: url)
                    try data.write(to: destZipURL, options: .atomic)
                } catch {
                    print("Copy ZIP failed for \(destDir):", error)
                    continue
                }

                let chatFolder = destDir.appendingPathComponent(chatFolderName, isDirectory: true)
                
                do {
                    if FileManager.default.fileExists(atPath: chatFolder.path) {
                        try? FileManager.default.removeItem(at: chatFolder)
                    }
                    try FileManager.default.createDirectory(at: chatFolder, withIntermediateDirectories: true, attributes: nil)
                    
                    do {
                        try FileManager.default.unzipItem(at: destZipURL, to: chatFolder)
                        print("Successfully unzipped chat to:", chatFolder.path)
                    } catch {
                        print("unzipItem failed, trying entry-by-entry:", error)
                        if let archive = Archive(url: destZipURL, accessMode: .read) {
                            for entry in archive {
                                let entryDestURL = chatFolder.appendingPathComponent(entry.path)
                                let parentDir = entryDestURL.deletingLastPathComponent()
                                try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
                                if entry.type == .directory {
                                    try? FileManager.default.createDirectory(at: entryDestURL, withIntermediateDirectories: true, attributes: nil)
                                } else {
                                    try? FileManager.default.removeItem(at: entryDestURL)
                                    try? archive.extract(entry, to: entryDestURL)
                                }
                            }
                        }
                    }
                } catch {
                    print("Extraction error:", error)
                }
            } else {
                // Direct .txt file export or single document
                let chatFolder = destDir.appendingPathComponent(chatFolderName, isDirectory: true)
                try? FileManager.default.createDirectory(at: chatFolder, withIntermediateDirectories: true, attributes: nil)
                let destFile = chatFolder.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: destFile)
                try? FileManager.default.copyItem(at: url, to: destFile)
            }
        }

        // Notify main app via UserDefaults flags in candidate groups
        for group in candidateGroups {
            UserDefaults(suiteName: group)?.set(chatFolderName, forKey: "latestSharedChatName")
            UserDefaults(suiteName: group)?.set(true, forKey: "shouldOpenAppAfterShare")
            UserDefaults(suiteName: group)?.synchronize()
        }
        return chatFolderName
    }

    @objc private func close() {
        for group in candidateGroups {
            UserDefaults(suiteName: group)?.set(false, forKey: "shouldOpenAppAfterShare")
            UserDefaults(suiteName: group)?.removeObject(forKey: "latestSharedChatName")
            UserDefaults(suiteName: group)?.synchronize()
        }
        extensionContext?.completeRequest(returningItems: nil)
    }
}
