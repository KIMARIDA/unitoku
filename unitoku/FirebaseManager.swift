import SwiftUI
import CoreData
import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// MARK: - Firebase Manager
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private lazy var db: Firestore = {
        return Firestore.firestore()
    }()
    
    private lazy var storage: Storage = {
        return Storage.storage()
    }()
    private var listeners: [ListenerRegistration] = []
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isOnline = true
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle, syncing, success, error(String)
    }
    
    private init() {
        // FirebaseApp.configure()는 unitokuApp.swift에서만 호출합니다.
        setupFirestore()
        observeNetworkStatus()
    }
    
    deinit {
        removeAllListeners()
    }
    
    private func setupFirestore() {
        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
        print("✅ Firestore offline persistence enabled")
    }
    
    private func observeNetworkStatus() {
        // Monitor network connectivity
        db.enableNetwork { [weak self] error in
            DispatchQueue.main.async {
                self?.isOnline = error == nil
                print("🌐 Network status: \(error == nil ? "Online" : "Offline")")
            }
        }
    }
    
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Database Access
    func getFirestore() -> Firestore {
        return db
    }
    
    // MARK: - Current User Helper
    private var currentUserId: String {
        return UserDefaults.standard.string(forKey: "currentUserId") ?? "anonymous_user"
    }
}

// MARK: - User Management
extension FirebaseManager {
    func syncUserProfile(_ userProfile: UserProfile) async throws {
        let userData: [String: Any] = [
            "name": userProfile.name,
            "email": userProfile.email,
            "studentID": userProfile.studentID ?? "",
            "department": userProfile.department ?? "",
            "grade": userProfile.grade ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(userProfile.id).setData(userData, merge: true)
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile? {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else { return nil }
        
        return UserProfile(
            id: userId,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            studentID: data["studentID"] as? String,
            department: data["department"] as? String,
            grade: data["grade"] as? String
        )
    }
}

// MARK: - Posts Management
extension FirebaseManager {
    func syncPost(_ post: Post, context: NSManagedObjectContext) async throws {
        guard let postId = post.id?.uuidString else { return }
        
        // Calculate comment count from relationship
        let commentCount = post.comments?.count ?? 0
        
        let postData: [String: Any] = [
            "title": post.title ?? "",
            "content": post.content ?? "",
            "authorId": post.authorId ?? currentUserId,
            "authorName": getAuthorName(for: post.authorId),
            "categoryId": post.category?.id?.uuidString ?? "",
            "categoryName": post.category?.name ?? "",
            "likeCount": post.likeCount,
            "commentCount": commentCount,
            "viewCount": post.viewCount,
            "createdAt": Timestamp(date: post.timestamp ?? Date()),
            "updatedAt": FieldValue.serverTimestamp(),
            "isAnonymous": post.isAnonymous
        ]
        
        try await db.collection("posts").document(postId).setData(postData, merge: true)
        
        // Sync images if any
        if post.hasImages {
            try await syncPostImages(postId: postId, images: post.images)
        }
    }
    
    private func syncPostImages(postId: String, images: [UIImage]) async throws {
        var imageUrls: [String] = []
        
        for (index, image) in images.enumerated() {
            let imageUrl = try await uploadImage(image, path: "posts/\(postId)/image_\(index).jpg")
            imageUrls.append(imageUrl)
        }
        
        try await db.collection("posts").document(postId).updateData([
            "imageUrls": imageUrls
        ])
    }
    
    func listenToPostsInCategory(_ categoryName: String, context: NSManagedObjectContext) {
        let listener = db.collection("posts")
            .whereField("categoryName", isEqualTo: categoryName)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                Task {
                    await self.updateLocalPostsFromFirestore(documents, context: context)
                }
            }
        
        listeners.append(listener)
    }
    
    private func updateLocalPostsFromFirestore(_ documents: [QueryDocumentSnapshot], context: NSManagedObjectContext) async {
        await context.perform {
            for document in documents {
                let data = document.data()
                let postId = document.documentID
                
                // Find or create local post
                let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: postId) as CVarArg? ?? UUID() as CVarArg)
                fetchRequest.fetchLimit = 1
                
                do {
                    let existingPosts = try context.fetch(fetchRequest)
                    let post = existingPosts.first ?? Post(context: context)
                    
                    if existingPosts.isEmpty {
                        post.id = UUID(uuidString: postId)
                    }
                    
                    // Update post data
                    post.title = data["title"] as? String
                    post.content = data["content"] as? String
                    post.authorId = data["authorId"] as? String
                    post.likeCount = Int32(data["likeCount"] as? Int ?? 0)
                    post.viewCount = Int32(data["viewCount"] as? Int ?? 0)
                    post.isAnonymous = data["isAnonymous"] as? Bool ?? false
                    
                    if let timestamp = data["createdAt"] as? Timestamp {
                        post.timestamp = timestamp.dateValue()
                    }
                    
                    // Update category if needed
                    if let categoryName = data["categoryName"] as? String {
                        post.category = self.findOrCreateCategory(name: categoryName, context: context)
                    }
                    
                    try context.save()
                } catch {
                    print("Error updating local post: \(error)")
                }
            }
        }
    }
    
    private func getAuthorName(for authorId: String?) -> String {
        // Get author name from UserDefaults or default to anonymous
        if let authorId = authorId,
           let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
           authorId == currentUserId {
            return UserDefaults.standard.string(forKey: "currentUserName") ?? "匿名ユーザー"
        }
        return "匿名ユーザー"
    }
}

// MARK: - Comments Management
extension FirebaseManager {
    func syncComment(_ comment: Comment, context: NSManagedObjectContext) async throws {
        guard let commentId = comment.id?.uuidString,
              let postId = comment.post?.id?.uuidString else { return }
        
        let commentData: [String: Any] = [
            "postId": postId,
            "content": comment.content ?? "",
            "authorId": comment.authorId ?? currentUserId,
            "authorName": getAuthorName(for: comment.authorId),
            "likeCount": comment.likeCount,
            "createdAt": Timestamp(date: comment.timestamp ?? Date()),
            "updatedAt": FieldValue.serverTimestamp(),
            "isAnonymous": false,
            "replyCount": 0
        ]
        
        try await db.collection("comments").document(commentId).setData(commentData, merge: true)
        
        // Update post comment count
        try await updatePostCommentCount(postId: postId)
    }
    
    private func updatePostCommentCount(postId: String) async throws {
        let commentsQuery = db.collection("comments").whereField("postId", isEqualTo: postId)
        let snapshot = try await commentsQuery.getDocuments()
        let commentCount = snapshot.documents.count
        
        try await db.collection("posts").document(postId).updateData([
            "commentCount": commentCount
        ])
    }
    
    func listenToCommentsForPost(_ postId: String, context: NSManagedObjectContext) {
        let listener = db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                Task {
                    await self.updateLocalCommentsFromFirestore(documents, context: context)
                }
            }
        
        listeners.append(listener)
    }
    
    private func updateLocalCommentsFromFirestore(_ documents: [QueryDocumentSnapshot], context: NSManagedObjectContext) async {
        await context.perform {
            for document in documents {
                let data = document.data()
                let commentId = document.documentID
                
                let fetchRequest: NSFetchRequest<Comment> = Comment.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: commentId) as CVarArg? ?? UUID() as CVarArg)
                fetchRequest.fetchLimit = 1
                
                do {
                    let existingComments = try context.fetch(fetchRequest)
                    let comment = existingComments.first ?? Comment(context: context)
                    
                    if existingComments.isEmpty {
                        comment.id = UUID(uuidString: commentId)
                    }
                    
                    comment.content = data["content"] as? String
                    comment.authorId = data["authorId"] as? String
                    comment.likeCount = Int32(data["likeCount"] as? Int ?? 0)
                    
                    if let timestamp = data["createdAt"] as? Timestamp {
                        comment.timestamp = timestamp.dateValue()
                    }
                    
                    // Find and link to post
                    if let postId = data["postId"] as? String,
                       let postUUID = UUID(uuidString: postId) {
                        let postFetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
                        postFetchRequest.predicate = NSPredicate(format: "id == %@", postUUID as CVarArg)
                        postFetchRequest.fetchLimit = 1
                        
                        if let post = try context.fetch(postFetchRequest).first {
                            comment.post = post
                        }
                    }
                    
                    try context.save()
                } catch {
                    print("Error updating local comment: \(error)")
                }
            }
        }
    }
}

// MARK: - Categories Management
extension FirebaseManager {
    func syncCategory(_ category: Category, context: NSManagedObjectContext) async throws {
        guard let categoryId = category.id?.uuidString else { return }
        
        // Calculate post count from relationship
        let postCount = category.posts?.count ?? 0
        
        let categoryData: [String: Any] = [
            "name": category.name ?? "",
            "icon": category.icon ?? "",
            "description": "", // No categoryDescription in CoreData model
            "order": category.order,
            "postCount": postCount,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("categories").document(categoryId).setData(categoryData, merge: true)
    }
    
    func listenToCategories(context: NSManagedObjectContext) {
        let listener = db.collection("categories")
            .order(by: "order", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                Task {
                    await self.updateLocalCategoriesFromFirestore(documents, context: context)
                }
            }
        
        listeners.append(listener)
    }
    
    private func updateLocalCategoriesFromFirestore(_ documents: [QueryDocumentSnapshot], context: NSManagedObjectContext) async {
        await context.perform {
            for document in documents {
                let data = document.data()
                let categoryId = document.documentID
                
                let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: categoryId) as CVarArg? ?? UUID() as CVarArg)
                fetchRequest.fetchLimit = 1
                
                do {
                    let existingCategories = try context.fetch(fetchRequest)
                    let category = existingCategories.first ?? Category(context: context)
                    
                    if existingCategories.isEmpty {
                        category.id = UUID(uuidString: categoryId)
                    }
                    
                    category.name = data["name"] as? String
                    category.icon = data["icon"] as? String
                    category.order = Int16(data["order"] as? Int ?? 0)
                    
                    if let createdAt = data["createdAt"] as? Timestamp {
                        // Create timestamp property if it doesn't exist in CoreData
                        // For now, we'll skip setting timestamp since it's not in the model
                    }
                    
                    try context.save()
                } catch {
                    print("Error updating local category: \(error)")
                }
            }
        }
    }
    
    private func findOrCreateCategory(name: String, context: NSManagedObjectContext) -> Category {
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
                // No timestamp property in CoreData model
                return newCategory
            }
        } catch {
            print("Error finding/creating category: \(error)")
            let newCategory = Category(context: context)
            newCategory.id = UUID()
            newCategory.name = name
            newCategory.icon = "folder"
            // No timestamp property in CoreData model
            return newCategory
        }
    }
}

// MARK: - Notifications Management
extension FirebaseManager {
    func sendNotification(userId: String, type: String, title: String, message: String, relatedPostId: UUID?) async throws {
        let notificationData: [String: Any] = [
            "userId": userId,
            "type": type,
            "title": title,
            "message": message,
            "relatedPostId": relatedPostId?.uuidString as Any,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false
        ]
        
        try await db.collection("notifications").addDocument(data: notificationData)
    }
    
    func listenToNotifications(userId: String) {
        let listener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    // Update notification badge or UI
                    let unreadCount = documents.filter { doc in
                        !(doc.data()["isRead"] as? Bool ?? false)
                    }.count
                    
                    UserDefaults.standard.set(unreadCount > 0, forKey: "hasUnreadNotifications")
                    NotificationCenter.default.post(name: .notificationsUpdated, object: unreadCount)
                }
            }
        
        listeners.append(listener)
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
}

// MARK: - Chat Management
extension FirebaseManager {
    // 채팅방 실시간 구독
    func observeChatRooms(for userId: String, onUpdate: @escaping ([ChatRoom]) -> Void) -> ListenerRegistration {
        let query = db.collection("chatRooms").whereField("participants", arrayContains: userId)
        let listener = query.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("[Chat] Failed to fetch chatRooms: \(error?.localizedDescription ?? "Unknown error")")
                onUpdate([])
                return
            }
            let rooms: [ChatRoom] = documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let isGroup = data["isGroup"] as? Bool,
                      let participants = data["participants"] as? [String],
                      let lastMessage = data["lastMessage"] as? String,
                      let lastMessageTime = (data["lastMessageTime"] as? Timestamp)?.dateValue() else { return nil }
                let unreadCount = data["unreadCount"] as? Int ?? 0
                return ChatRoom(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    name: name,
                    isGroup: isGroup,
                    participants: participants,
                    lastMessage: lastMessage,
                    lastMessageTime: lastMessageTime,
                    unreadCount: unreadCount
                )
            }
            onUpdate(rooms)
        }
        listeners.append(listener)
        return listener
    }

    // 메시지 실시간 구독
    func observeMessages(roomId: UUID, onUpdate: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        let listener = db.collection("chatRooms").document(roomId.uuidString).collection("messages").order(by: "timestamp").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("[Chat] Failed to fetch messages: \(error?.localizedDescription ?? "Unknown error")")
                onUpdate([])
                return
            }
            let messages: [ChatMessage] = documents.compactMap { doc in
                let data = doc.data()
                guard let content = data["content"] as? String,
                      let senderID = data["senderID"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else { return nil }
                let isCurrentUser = senderID == self.currentUserId
                return ChatMessage(
                    id: UUID(uuidString: doc.documentID) ?? UUID(),
                    content: content,
                    senderID: senderID,
                    isCurrentUser: isCurrentUser,
                    timestamp: timestamp
                )
            }
            onUpdate(messages)
        }
        listeners.append(listener)
        return listener
    }

    // 메시지 전송
    func sendMessage(roomId: UUID, content: String, completion: ((Error?) -> Void)? = nil) {
        let messageId = UUID().uuidString
        let messageData: [String: Any] = [
            "content": content,
            "senderID": currentUserId,
            "timestamp": FieldValue.serverTimestamp()
        ]
        db.collection("chatRooms").document(roomId.uuidString).collection("messages").document(messageId).setData(messageData) { error in
            completion?(error)
        }
        // 채팅방의 lastMessage, lastMessageTime 업데이트
        db.collection("chatRooms").document(roomId.uuidString).updateData([
            "lastMessage": content,
            "lastMessageTime": FieldValue.serverTimestamp()
        ])
    }

    // 채팅방 생성
    func createChatRoom(name: String, isGroup: Bool, participants: [String], completion: @escaping (UUID?) -> Void) {
        let roomId = UUID()
        let data: [String: Any] = [
            "name": name,
            "isGroup": isGroup,
            "participants": participants,
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCount": 0
        ]
        db.collection("chatRooms").document(roomId.uuidString).setData(data) { error in
            if let error = error {
                print("[Chat] Failed to create chat room: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(roomId)
            }
        }
    }
}

// MARK: - Course Evaluations Management
extension FirebaseManager {
    func syncCourseEvaluation(_ evaluation: CourseEvaluation) async throws {
        let evaluationData: [String: Any] = [
            "courseId": evaluation.courseId.uuidString,
            "authorName": evaluation.authorName,
            "semester": evaluation.semester,
            "overallScore": evaluation.overallScore.rawValue,
            "difficultyScore": evaluation.difficultyScore.rawValue,
            "assignmentsScore": evaluation.assignmentsScore.rawValue,
            "teachingScore": evaluation.teachingScore.rawValue,
            "gradingScore": evaluation.gradingScore.rawValue,
            "comment": evaluation.comment,
            "likes": evaluation.likes,
            "createdAt": Timestamp(date: evaluation.date),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("courseEvaluations").document(evaluation.id.uuidString).setData(evaluationData, merge: true)
    }
    
    func getCourseEvaluations(courseId: UUID) async throws -> [CourseEvaluation] {
        let snapshot = try await db.collection("courseEvaluations")
            .whereField("courseId", isEqualTo: courseId.uuidString)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> CourseEvaluation? in
            let data = doc.data()
            guard let courseIdString = data["courseId"] as? String,
                  let courseUUID = UUID(uuidString: courseIdString) else { return nil }
            
            return CourseEvaluation(
                id: UUID(uuidString: doc.documentID) ?? UUID(),
                courseId: courseUUID,
                authorName: data["authorName"] as? String ?? "匿名",
                semester: data["semester"] as? String ?? "",
                overallScore: EvaluationScore(rawValue: data["overallScore"] as? Int ?? 3) ?? .three,
                difficultyScore: EvaluationScore(rawValue: data["difficultyScore"] as? Int ?? 3) ?? .three,
                assignmentsScore: EvaluationScore(rawValue: data["assignmentsScore"] as? Int ?? 3) ?? .three,
                teachingScore: EvaluationScore(rawValue: data["teachingScore"] as? Int ?? 3) ?? .three,
                gradingScore: EvaluationScore(rawValue: data["gradingScore"] as? Int ?? 3) ?? .three,
                comment: data["comment"] as? String ?? "",
                date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                likes: data["likes"] as? Int ?? 0
            )
        }
    }
}

// MARK: - Courses Management (Timetable)
extension FirebaseManager {
    func syncCourse(_ course: Course) async throws {
        let courseData: [String: Any] = [
            "name": course.name,
            "professor": course.professor,
            "room": course.room,
            "weekday": course.weekday.rawValue,
            "period": course.period.rawValue,
            "color": colorToHex(course.color),
            "userId": currentUserId,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("courses").document(course.id.uuidString).setData(courseData, merge: true)
    }
    
    func getUserCourses() async throws -> [Course] {
        let snapshot = try await db.collection("courses")
            .whereField("userId", isEqualTo: currentUserId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Course? in
            let data = doc.data()
            guard let name = data["name"] as? String,
                  let professor = data["professor"] as? String,
                  let room = data["room"] as? String,
                  let weekdayString = data["weekday"] as? String,
                  let weekday = Weekday(rawValue: weekdayString),
                  let periodInt = data["period"] as? Int,
                  let period = Period(rawValue: periodInt) else { return nil }
            
            let colorHex = data["color"] as? String ?? "#007AFF"
            let color = hexToColor(colorHex)
            
            return Course(
                id: UUID(uuidString: doc.documentID) ?? UUID(),
                name: name,
                professor: professor,
                room: room,
                weekday: weekday,
                period: period,
                color: color
            )
        }
    }
    
    private func colorToHex(_ color: Color) -> String {
        // Convert SwiftUI Color to hex string
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(format: "#%02X%02X%02X",
                     Int(red * 255),
                     Int(green * 255),
                     Int(blue * 255))
    }
    
    private func hexToColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Image Upload
extension FirebaseManager {
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
}

// MARK: - Sync Management
extension FirebaseManager {
    func startRealTimeSync(context: NSManagedObjectContext) {
        listenToCategories(context: context)
        listenToNotifications(userId: currentUserId)
        
        // Listen to posts in default category
        listenToPostsInCategory("一般", context: context)
    }
    
    func syncAllLocalData(context: NSManagedObjectContext) async {
        syncStatus = .syncing
        
        do {
            // Sync categories
            let categoryFetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
            let categories = try context.fetch(categoryFetchRequest)
            
            for category in categories {
                try await syncCategory(category, context: context)
            }
            
            // Sync posts
            let postFetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
            let posts = try context.fetch(postFetchRequest)
            
            for post in posts {
                try await syncPost(post, context: context)
            }
            
            // Sync comments
            let commentFetchRequest: NSFetchRequest<Comment> = Comment.fetchRequest()
            let comments = try context.fetch(commentFetchRequest)
            
            for comment in comments {
                try await syncComment(comment, context: context)
            }
            
            syncStatus = .success
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let notificationsUpdated = Notification.Name("notificationsUpdated")
    static let postsUpdated = Notification.Name("postsUpdated")
    static let commentsUpdated = Notification.Name("commentsUpdated")
}

// MARK: - FCM 토큰 저장
extension FirebaseManager {
    func saveFCMToken(_ token: String) {
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId") else { return }
        let data: [String: Any] = ["fcmToken": token, "updatedAt": FieldValue.serverTimestamp()]
        db.collection("users").document(userId).setData(data, merge: true) { error in
            if let error = error {
                print("[FCM] 토큰 저장 실패: \(error.localizedDescription)")
            } else {
                print("[FCM] 토큰 Firestore 저장 성공")
            }
        }
    }
}
