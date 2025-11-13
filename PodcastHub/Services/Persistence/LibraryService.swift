import CoreData
import Foundation

protocol LibraryServiceType {
    func saveShow(_ show: Show) throws
    func removeSavedShow(_ showId: String) throws
    func isShowSaved(_ showId: String) -> Bool
    func getSavedShows() throws -> [Show]

    func favoriteShow(_ show: Show) throws
    func unfavoriteShow(_ showId: String) throws
    func isShowFavorited(_ showId: String) -> Bool
    func getFavoritedShows() throws -> [Show]

    func downloadShow(_ show: Show) throws
    func removeDownloadedShow(_ showId: String) throws
    func isShowDownloaded(_ showId: String) -> Bool
    func getDownloadedShows() throws -> [Show]

    func getSavedCount() -> Int
    func getFavoritedCount() -> Int
    func getDownloadedCount() -> Int
}

final class LibraryService: LibraryServiceType {
    static let shared = LibraryService()

    private let coreDataStack: CoreDataStackType

    init(coreDataStack: CoreDataStackType = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Saved Shows

    func saveShow(_ show: Show) throws {
        let context = coreDataStack.viewContext
        let entityName = "SavedShowEntity"
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "showId == %@", show.id)

        let existing = try context.fetch(request).first

        if existing == nil {
            let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            entity.setValue(show.id, forKey: "showId")
            entity.setValue(show.title, forKey: "title")
            entity.setValue(show.publisher, forKey: "publisher")
            entity.setValue(show.imageURL?.absoluteString, forKey: "imageURL")
            entity.setValue(show.thumbnailURL?.absoluteString, forKey: "thumbnailURL")
            entity.setValue(show.description, forKey: "descriptionText")
            entity.setValue(show.rss, forKey: "rss")
            entity.setValue(show.genres.joined(separator: ","), forKey: "genres")
            entity.setValue(Int32(show.totalEpisodes), forKey: "totalEpisodes")
            entity.setValue(Date(), forKey: "dateAdded")
        }

        try coreDataStack.saveContext()
    }

    func removeSavedShow(_ showId: String) throws {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedShowEntity")
        request.predicate = NSPredicate(format: "showId == %@", showId)

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try coreDataStack.saveContext()
        }
    }

    func isShowSaved(_ showId: String) -> Bool {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedShowEntity")
        request.predicate = NSPredicate(format: "showId == %@", showId)

        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }

    func getSavedShows() throws -> [Show] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedShowEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { entity in
            Show(
                id: entity.value(forKey: "showId") as? String ?? "",
                title: entity.value(forKey: "title") as? String ?? "",
                publisher: entity.value(forKey: "publisher") as? String ?? "",
                imageURL: (entity.value(forKey: "imageURL") as? String).flatMap { URL(string: $0) },
                thumbnailURL: (entity.value(forKey: "thumbnailURL") as? String).flatMap { URL(string: $0) },
                totalEpisodes: Int(entity.value(forKey: "totalEpisodes") as? Int32 ?? 0),
                description: entity.value(forKey: "descriptionText") as? String ?? "",
                rss: entity.value(forKey: "rss") as? String,
                genres: (entity.value(forKey: "genres") as? String)?.components(separatedBy: ",") ?? [],
                latestEpisodes: []
            )
        }
    }

    func getSavedCount() -> Int {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedShowEntity")

        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    // MARK: - Favorite Shows

    func favoriteShow(_ show: Show) throws {
        let context = coreDataStack.viewContext
        let entityName = "FavoriteShowEntity"
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "showId == %@", show.id)

        let existing = try context.fetch(request).first

        if existing == nil {
            let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            entity.setValue(show.id, forKey: "showId")
            entity.setValue(show.title, forKey: "title")
            entity.setValue(show.publisher, forKey: "publisher")
            entity.setValue(show.imageURL?.absoluteString, forKey: "imageURL")
            entity.setValue(show.thumbnailURL?.absoluteString, forKey: "thumbnailURL")
            entity.setValue(show.description, forKey: "descriptionText")
            entity.setValue(show.rss, forKey: "rss")
            entity.setValue(show.genres.joined(separator: ","), forKey: "genres")
            entity.setValue(Int32(show.totalEpisodes), forKey: "totalEpisodes")
            entity.setValue(Date(), forKey: "dateAdded")
        }

        try coreDataStack.saveContext()
    }

    func unfavoriteShow(_ showId: String) throws {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "FavoriteShowEntity")
        request.predicate = NSPredicate(format: "showId == %@", showId)

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try coreDataStack.saveContext()
        }
    }

    func isShowFavorited(_ showId: String) -> Bool {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "FavoriteShowEntity")
        request.predicate = NSPredicate(format: "showId == %@", showId)

        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }

    func getFavoritedShows() throws -> [Show] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "FavoriteShowEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { entity in
            Show(
                id: entity.value(forKey: "showId") as? String ?? "",
                title: entity.value(forKey: "title") as? String ?? "",
                publisher: entity.value(forKey: "publisher") as? String ?? "",
                imageURL: (entity.value(forKey: "imageURL") as? String).flatMap { URL(string: $0) },
                thumbnailURL: (entity.value(forKey: "thumbnailURL") as? String).flatMap { URL(string: $0) },
                totalEpisodes: Int(entity.value(forKey: "totalEpisodes") as? Int32 ?? 0),
                description: entity.value(forKey: "descriptionText") as? String ?? "",
                rss: entity.value(forKey: "rss") as? String,
                genres: (entity.value(forKey: "genres") as? String)?.components(separatedBy: ",") ?? [],
                latestEpisodes: []
            )
        }
    }

    func getFavoritedCount() -> Int {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "FavoriteShowEntity")

        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    // MARK: - Downloaded Shows

    func downloadShow(_ show: Show) throws {
        let context = coreDataStack.viewContext
        let entityName = "DownloadedShowEntity"
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "showId == %@", show.id)

        let existing = try context.fetch(request).first

        if existing == nil {
            let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            entity.setValue(show.id, forKey: "showId")
            entity.setValue(show.title, forKey: "title")
            entity.setValue(show.publisher, forKey: "publisher")
            entity.setValue(show.imageURL?.absoluteString, forKey: "imageURL")
            entity.setValue(show.thumbnailURL?.absoluteString, forKey: "thumbnailURL")
            entity.setValue(show.description, forKey: "descriptionText")
            entity.setValue(show.rss, forKey: "rss")
            entity.setValue(show.genres.joined(separator: ","), forKey: "genres")
            entity.setValue(Int32(show.totalEpisodes), forKey: "totalEpisodes")
            entity.setValue(Date(), forKey: "dateDownloaded")
        }

        try coreDataStack.saveContext()
    }

    func removeDownloadedShow(_ showId: String) throws {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "DownloadedShowEntity")
        request.predicate = NSPredicate(format: "showId == %@", showId)

        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try coreDataStack.saveContext()
        }
    }

    func isShowDownloaded(_ showId: String) -> Bool {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "DownloadedShowEntity")
        request.predicate = NSPredicate(format: "showId == %@", showId)

        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }

    func getDownloadedShows() throws -> [Show] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "DownloadedShowEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "dateDownloaded", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { entity in
            Show(
                id: entity.value(forKey: "showId") as? String ?? "",
                title: entity.value(forKey: "title") as? String ?? "",
                publisher: entity.value(forKey: "publisher") as? String ?? "",
                imageURL: (entity.value(forKey: "imageURL") as? String).flatMap { URL(string: $0) },
                thumbnailURL: (entity.value(forKey: "thumbnailURL") as? String).flatMap { URL(string: $0) },
                totalEpisodes: Int(entity.value(forKey: "totalEpisodes") as? Int32 ?? 0),
                description: entity.value(forKey: "descriptionText") as? String ?? "",
                rss: entity.value(forKey: "rss") as? String,
                genres: (entity.value(forKey: "genres") as? String)?.components(separatedBy: ",") ?? [],
                latestEpisodes: []
            )
        }
    }

    func getDownloadedCount() -> Int {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "DownloadedShowEntity")

        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
}
