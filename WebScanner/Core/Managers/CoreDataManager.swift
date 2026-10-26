//
//  CoreDataManager.swift
//  WebScanner
//
//

import Foundation
import CoreData
import Combine

public struct CredentialModel: Identifiable, Equatable {
    public let id: UUID
    public let platform: String
    public let username: String
    public let password: String
    public let url: String
    public let createdAt: Date
    
    public init(id: UUID = UUID(), platform: String, username: String, password: String, url: String = "", createdAt: Date = Date()) {
        self.id = id
        self.platform = platform
        self.username = username
        self.password = password
        self.url = url
        self.createdAt = createdAt
    }
}

public final class CoreDataManager: ObservableObject {
    public static let shared = CoreDataManager()
    
    @Published public private(set) var credentials: [CredentialModel] = []
    
    private let persistentContainer: NSPersistentContainer
    
    public var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {
        // Build dynamic Core Data NSManagedObjectModel programmatically
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = "UserCredential"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let platformAttr = NSAttributeDescription()
        platformAttr.name = "platform"
        platformAttr.attributeType = .stringAttributeType
        platformAttr.isOptional = false
        
        let usernameAttr = NSAttributeDescription()
        usernameAttr.name = "username"
        usernameAttr.attributeType = .stringAttributeType
        usernameAttr.isOptional = true
        
        let passwordAttr = NSAttributeDescription()
        passwordAttr.name = "password"
        passwordAttr.attributeType = .stringAttributeType
        passwordAttr.isOptional = true
        
        let urlAttr = NSAttributeDescription()
        urlAttr.name = "url"
        urlAttr.attributeType = .stringAttributeType
        urlAttr.isOptional = true
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        entity.properties = [idAttr, platformAttr, usernameAttr, passwordAttr, urlAttr, createdAtAttr]
        model.entities = [entity]
        
        persistentContainer = NSPersistentContainer(name: "WebScannerCoreData", managedObjectModel: model)
        
        // Use an SQLite persistent store in Application Support
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                print("[CoreData] Error loading persistent store: \(error.localizedDescription)")
            } else {
                print("[CoreData] Persistent store loaded successfully at: \(description.url?.path ?? "in-memory")")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        fetchCredentials()
    }
    
    public func fetchCredentials(for platform: String? = nil) {
        context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "UserCredential")
            if let platform = platform, !platform.isEmpty {
                request.predicate = NSPredicate(format: "platform ==[c] %@", platform)
            }
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            do {
                let results = try self.context.fetch(request)
                let models = results.compactMap { obj -> CredentialModel? in
                    guard let id = obj.value(forKey: "id") as? UUID,
                          let plat = obj.value(forKey: "platform") as? String,
                          let createdAt = obj.value(forKey: "createdAt") as? Date else {
                        return nil
                    }
                    let user = obj.value(forKey: "username") as? String ?? ""
                    let pass = obj.value(forKey: "password") as? String ?? ""
                    let url = obj.value(forKey: "url") as? String ?? ""
                    return CredentialModel(id: id, platform: plat, username: user, password: pass, url: url, createdAt: createdAt)
                }
                DispatchQueue.main.async {
                    self.credentials = models
                }
            } catch {
                print("[CoreData] Fetch error: \(error.localizedDescription)")
            }
        }
    }
    
    public func saveCredential(platform: String, username: String, password: String, url: String) {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUser.isEmpty || !trimmedPass.isEmpty else { return }
        
        context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "UserCredential")
            if !trimmedUser.isEmpty {
                request.predicate = NSPredicate(format: "platform ==[c] %@ AND username ==[c] %@", platform, trimmedUser)
            } else {
                request.predicate = NSPredicate(format: "platform ==[c] %@", platform)
            }
            
            do {
                let existing = try self.context.fetch(request)
                let objectToSave: NSManagedObject
                if let first = existing.first {
                    objectToSave = first
                } else {
                    objectToSave = NSEntityDescription.insertNewObject(forEntityName: "UserCredential", into: self.context)
                    objectToSave.setValue(UUID(), forKey: "id")
                }
                
                objectToSave.setValue(platform, forKey: "platform")
                if !trimmedUser.isEmpty {
                    objectToSave.setValue(trimmedUser, forKey: "username")
                }
                if !trimmedPass.isEmpty {
                    objectToSave.setValue(trimmedPass, forKey: "password")
                }
                objectToSave.setValue(url, forKey: "url")
                objectToSave.setValue(Date(), forKey: "createdAt")
                
                try self.context.save()
                print("[CoreData] Successfully saved credential for platform: \(platform), user: \(trimmedUser)")
                self.fetchCredentials()
            } catch {
                print("[CoreData] Save error: \(error.localizedDescription)")
            }
        }
    }
    
    public func getLatestCredential(for platform: String) -> CredentialModel? {
        return credentials.first { $0.platform.caseInsensitiveCompare(platform) == .orderedSame }
    }
    
    public func deleteCredential(id: UUID) {
        context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "UserCredential")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            if let results = try? self.context.fetch(request), let obj = results.first {
                self.context.delete(obj)
                try? self.context.save()
                self.fetchCredentials()
            }
        }
    }
}
