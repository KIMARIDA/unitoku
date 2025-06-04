import Foundation
import CoreData

// Extension to add authorId property to Post
extension Post {
    // Since we can't directly add properties to CoreData entities at runtime,
    // we'll store the authorId in UserDefaults with a post-specific key
    var authorId: String {
        get {
            guard let id = self.id?.uuidString else { return "" }
            return UserDefaults.standard.string(forKey: "post_author_\(id)") ?? ""
        }
        set {
            guard let id = self.id?.uuidString else { return }
            UserDefaults.standard.set(newValue, forKey: "post_author_\(id)")
        }
    }
}