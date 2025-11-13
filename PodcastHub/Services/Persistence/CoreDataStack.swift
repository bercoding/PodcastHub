import CoreData
import Foundation

protocol CoreDataStackType {
    var viewContext: NSManagedObjectContext { get }
    func saveContext() throws
    func newBackgroundContext() -> NSManagedObjectContext
}

final class CoreDataStack: CoreDataStackType {
    static let shared = CoreDataStack()

    private let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {
        // Tạo model programmatically
        let model = CoreDataStack.createManagedObjectModel()
        
        self.persistentContainer = NSPersistentContainer(name: "PodcastHub", managedObjectModel: model)

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError(" Core Data load failed: \(error.localizedDescription)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // SavedShowEntity
        let savedShowEntity = NSEntityDescription()
        savedShowEntity.name = "SavedShowEntity"
        savedShowEntity.managedObjectClassName = "SavedShowEntity"
        
        savedShowEntity.properties = [
            CoreDataStack.createAttribute(name: "showId", type: .stringAttributeType, optional: false),
            CoreDataStack.createAttribute(name: "title", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "publisher", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "imageURL", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "thumbnailURL", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "descriptionText", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "rss", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "genres", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "totalEpisodes", type: .integer32AttributeType, optional: false),
            CoreDataStack.createAttribute(name: "dateAdded", type: .dateAttributeType, optional: true)
        ]
        
        // FavoriteShowEntity
        let favoriteShowEntity = NSEntityDescription()
        favoriteShowEntity.name = "FavoriteShowEntity"
        favoriteShowEntity.managedObjectClassName = "FavoriteShowEntity"
        
        favoriteShowEntity.properties = [
            CoreDataStack.createAttribute(name: "showId", type: .stringAttributeType, optional: false),
            CoreDataStack.createAttribute(name: "title", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "publisher", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "imageURL", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "thumbnailURL", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "descriptionText", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "rss", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "genres", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "totalEpisodes", type: .integer32AttributeType, optional: false),
            CoreDataStack.createAttribute(name: "dateAdded", type: .dateAttributeType, optional: true)
        ]
        
        // DownloadedShowEntity
        let downloadedShowEntity = NSEntityDescription()
        downloadedShowEntity.name = "DownloadedShowEntity"
        downloadedShowEntity.managedObjectClassName = "DownloadedShowEntity"
        
        downloadedShowEntity.properties = [
            CoreDataStack.createAttribute(name: "showId", type: .stringAttributeType, optional: false),
            CoreDataStack.createAttribute(name: "title", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "publisher", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "imageURL", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "thumbnailURL", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "descriptionText", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "rss", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "genres", type: .stringAttributeType, optional: true),
            CoreDataStack.createAttribute(name: "totalEpisodes", type: .integer32AttributeType, optional: false),
            CoreDataStack.createAttribute(name: "dateDownloaded", type: .dateAttributeType, optional: true)
        ]
        
        model.entities = [savedShowEntity, favoriteShowEntity, downloadedShowEntity]
        
        return model
    }
    
    private static func createAttribute(name: String, type: NSAttributeType, optional: Bool) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }

    func saveContext() throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
}
