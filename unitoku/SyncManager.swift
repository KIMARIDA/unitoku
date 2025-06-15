import Foundation
import SwiftUI
import CoreData
import Combine
import FirebaseFirestore

// Import the model files that contain the missing types
// BoardPost and BoardCategory are in BoardModels.swift
// ChatMessage is in ChatModels.swift  
// CourseEvaluation and Course are in CourseEvaluationModels.swift and timetable models

// MARK: - Sync Manager
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    private let networkService = NetworkService.shared
    private let context = PersistenceController.shared.container.viewContext
    private var cancellables = Set<AnyCancellable>()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var isOnline = true
    
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
        
        static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.syncing, .syncing), (.success, .success):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    private init() {
        setupNetworkMonitoring()
        startRealTimeSync()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        // Monitor network status - simplified version
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkNetworkStatus()
            }
            .store(in: &cancellables)
    }
    
    private func checkNetworkStatus() {
        // Simple network check - can be enhanced
        isOnline = true
    }
    
    // MARK: - Real-time Sync Setup
    func startRealTimeSync() {
        guard isOnline else { return }
        
        // Listen to categories
        networkService.listenToCategories { [weak self] categories in
            self?.updateLocalCategories(categories)
        }
        
        // Listen to posts in default category
        networkService.listenToPostsInCategory("一般", context: context) { [weak self] (posts: [BoardPost]) in
            self?.updateLocalPosts(posts)
        }
        
        // Listen to notifications for current user
        let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? "anonymous_user"
        networkService.listenToNotifications(userId: currentUserId) { unreadCount in
            // Notification count updated automatically in NetworkService
        }
    }
    
    // MARK: - Local Data Updates
    private func updateLocalCategories(_ categories: [BoardCategory]) {
        context.perform {
            for categoryData in categories {
                let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", categoryData.name)
                fetchRequest.fetchLimit = 1
                
                do {
                    let existingCategories = try self.context.fetch(fetchRequest)
                    let category = existingCategories.first ?? Category(context: self.context)
                    
                    if existingCategories.isEmpty {
                        category.id = UUID(uuidString: categoryData.id ?? "") ?? UUID()
                    }
                    
                    category.name = categoryData.name
                    category.icon = categoryData.icon
                    // Skip categoryDescription - not in CoreData model
                    category.order = Int16(categoryData.order)
                    // Skip postCount - calculated from relationship
                    // Skip timestamp - not in CoreData model
                    
                    try self.context.save()
                } catch {
                    print("Error updating local category: \(error)")
                }
            }
        }
    }
    
    private func updateLocalPosts(_ posts: [BoardPost]) {
        context.perform {
            for postData in posts {
                guard let postId = postData.id else { continue }
                
                let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: postId) as CVarArg? ?? UUID() as CVarArg)
                fetchRequest.fetchLimit = 1
                
                do {
                    let existingPosts = try self.context.fetch(fetchRequest)
                    let post = existingPosts.first ?? Post(context: self.context)
                    
                    if existingPosts.isEmpty {
                        post.id = UUID(uuidString: postId)
                    }
                    
                    post.title = postData.title
                    post.content = postData.content
                    post.authorId = postData.authorId
                    post.likeCount = Int32(postData.likeCount)
                    // Skip commentCount - calculated from relationship
                    post.viewCount = Int32(postData.viewCount)
                    post.timestamp = postData.createdAt
                    
                    // Update category if needed
                    if !postData.categoryName.isEmpty {
                        post.category = self.findOrCreateCategory(name: postData.categoryName)
                    }
                    
                    try self.context.save()
                } catch {
                    print("Error updating local post: \(error)")
                }
            }
        }
    }
    
    private func findOrCreateCategory(name: String) -> Category {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.fetchLimit = 1
        
        do {
            if let existingCategory = try context.fetch(fetchRequest).first {
                return existingCategory
            } else {
                let newCategory = Category(context: context)
                newCategory.id = UUID()
                newCategory.name = name
                newCategory.icon = "folder"
                // Skip timestamp - not in CoreData model
                return newCategory
            }
        } catch {
            print("Error finding/creating category: \(error)")
            let newCategory = Category(context: context)
            newCategory.id = UUID()
            newCategory.name = name
            newCategory.icon = "folder"
            // Skip timestamp - not in CoreData model
            return newCategory
        }
    }
    
    // MARK: - Manual Sync Operations
    func syncAllLocalDataToFirebase() async {
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            // Sync categories
            let categoryFetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
            let categories = try context.fetch(categoryFetchRequest)
            
            for category in categories {
                try await networkService.syncCategory(category, context: context)
            }
            
            // Sync posts
            let postFetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
            let posts = try context.fetch(postFetchRequest)
            
            for post in posts {
                try await networkService.syncPost(post, context: context)
            }
            
            // Sync comments
            let commentFetchRequest: NSFetchRequest<Comment> = Comment.fetchRequest()
            let comments = try context.fetch(commentFetchRequest)
            
            for comment in comments {
                try await networkService.syncComment(comment, context: context)
            }
            
            await MainActor.run {
                syncStatus = .success
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Individual Sync Operations
    func syncPost(_ post: Post) async throws {
        try await networkService.syncPost(post, context: context)
    }
    
    func syncComment(_ comment: Comment) async throws {
        try await networkService.syncComment(comment, context: context)
    }
    
    func syncCategory(_ category: Category) async throws {
        try await networkService.syncCategory(category, context: context)
    }
    
    // MARK: - Real-time Chat
    func createChatRoom(name: String, isGroup: Bool, participants: [String]) async throws -> String {
        return try await networkService.createChatRoom(name: name, isGroup: isGroup, participants: participants)
    }
    
    func sendMessage(roomId: String, content: String) async throws {
        let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? "anonymous_user"
        try await networkService.sendMessage(roomId: roomId, content: content, senderId: currentUserId)
    }
    
    func listenToMessages(roomId: String, completion: @escaping ([ChatMessage]) -> Void) {
        networkService.listenToMessages(roomId: roomId, completion: completion)
    }
    
    // MARK: - Notifications
    func sendNotification(userId: String, type: String, title: String, message: String, relatedPostId: UUID?) async throws {
        try await networkService.sendNotification(userId: userId, type: type, title: title, message: message, relatedPostId: relatedPostId)
    }
    
    // MARK: - Course Evaluations
    func syncCourseEvaluation(_ evaluation: CourseEvaluation) async throws {
        try await networkService.syncCourseEvaluation(evaluation)
    }
    
    func getCourseEvaluations(courseId: UUID) async throws -> [CourseEvaluation] {
        return try await networkService.getCourseEvaluations(courseId: courseId)
    }
    
    // MARK: - Timetable Courses
    func syncCourse(_ course: Course) async throws {
        try await networkService.syncCourse(course)
    }
    
    func getUserCourses() async throws -> [Course] {
        return try await networkService.getUserCourses()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let syncStatusChanged = Notification.Name("syncStatusChanged")
    static let dataUpdated = Notification.Name("dataUpdated")
}
