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
        guard
            let modelURL = Bundle.main.url(forResource: "PodcastHub", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("❌ Không tìm thấy Core Data model")
        }

        self.persistentContainer = NSPersistentContainer(name: "PodcastHub", managedObjectModel: model)

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("❌ Core Data load failed: \(error.localizedDescription)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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
