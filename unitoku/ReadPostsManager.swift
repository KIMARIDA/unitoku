import Foundation
import CoreData
import SwiftUI

class ReadPostsManager {
    static let shared = ReadPostsManager()
    
    private let readPostsKey = "readPosts"
    private let maxReadPostsCount = 100
    
    private init() {}
    
    // Save a post as read
    func markAsRead(postID: UUID, title: String, timestamp: Date) {
        var readPosts = getReadPosts()
        
        // Check if post is already in the list
        if !readPosts.contains(where: { $0.id == postID }) {
            // Add the new post at the beginning of the array
            let newReadPost = ReadPost(id: postID, title: title, readAt: Date(), postTimestamp: timestamp)
            readPosts.insert(newReadPost, at: 0)
            
            // Limit the number of stored read posts
            if readPosts.count > maxReadPostsCount {
                readPosts = Array(readPosts.prefix(maxReadPostsCount))
            }
            
            // Save the updated list
            if let encodedData = try? JSONEncoder().encode(readPosts) {
                UserDefaults.standard.set(encodedData, forKey: readPostsKey)
            }
        } else {
            // Update the read timestamp for existing post
            if let index = readPosts.firstIndex(where: { $0.id == postID }) {
                readPosts[index].readAt = Date()
                
                // Move to the beginning of the array
                let post = readPosts.remove(at: index)
                readPosts.insert(post, at: 0)
                
                // Save the updated list
                if let encodedData = try? JSONEncoder().encode(readPosts) {
                    UserDefaults.standard.set(encodedData, forKey: readPostsKey)
                }
            }
        }
    }
    
    // Get all read posts
    func getReadPosts() -> [ReadPost] {
        guard let data = UserDefaults.standard.data(forKey: readPostsKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        if let readPosts = try? decoder.decode([ReadPost].self, from: data) {
            return readPosts
        }
        
        return []
    }
    
    // Clear all read posts
    func clearAllReadPosts() {
        UserDefaults.standard.removeObject(forKey: readPostsKey)
    }
    
    // Delete a specific read post
    func deleteReadPost(postID: UUID) {
        var readPosts = getReadPosts()
        readPosts.removeAll { $0.id == postID }
        
        if let encodedData = try? JSONEncoder().encode(readPosts) {
            UserDefaults.standard.set(encodedData, forKey: readPostsKey)
        }
    }
}

// Model for a read post
struct ReadPost: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var readAt: Date
    var postTimestamp: Date
    
    static func == (lhs: ReadPost, rhs: ReadPost) -> Bool {
        return lhs.id == rhs.id
    }
}