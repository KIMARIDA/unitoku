//
//  Persistence.swift
//  unitoku
//
//  Created by 김준용 on 5/29/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newPost = Post(context: viewContext)
            newPost.timestamp = Date()
            newPost.content = "샘플 게시글 #\(i+1)"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "unitoku")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Migrate existing posts to use CoreData authorId field
        migrateAuthorIds()
    }
    
    // Migrate existing posts from UserDefaults-based authorId to CoreData authorId
    private func migrateAuthorIds() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "authorId == nil OR authorId == ''")
        
        do {
            let postsToMigrate = try context.fetch(fetchRequest)
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? "user_1"
            
            for post in postsToMigrate {
                // Try to get authorId from UserDefaults first
                if let postId = post.id?.uuidString {
                    let userDefaultsAuthorId = UserDefaults.standard.string(forKey: "post_author_\(postId)")
                    post.authorId = userDefaultsAuthorId ?? currentUserId
                    
                    // Clean up UserDefaults entry
                    if userDefaultsAuthorId != nil {
                        UserDefaults.standard.removeObject(forKey: "post_author_\(postId)")
                    }
                } else {
                    // Fallback to current user
                    post.authorId = currentUserId
                }
            }
            
            if !postsToMigrate.isEmpty {
                try context.save()
                print("✅ Migrated \(postsToMigrate.count) posts to use CoreData authorId")
            }
        } catch {
            print("❌ Error migrating authorIds: \(error)")
        }
    }
}
