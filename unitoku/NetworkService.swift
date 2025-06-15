import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData
import SwiftUI
import UIKit
import FirebaseCore

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case requestFailed(Error)
    case serverError(Int)
    case decodingError(Error)
    case unknownError
    case authError(String)
    
    var message: String {
        switch self {
        case .invalidURL:
            return "無効なURLです。"
        case .invalidResponse:
            return "サーバーの応答が無効です。"
        case .invalidData:
            return "データが無効です。"
        case .requestFailed(let error):
            return "リクエスト失敗: \(error.localizedDescription)"
        case .serverError(let code):
            return "サーバーエラー (コード: \(code))"
        case .decodingError(let error):
            return "データのデコードエラー: \(error.localizedDescription)"
        case .authError(let message):
            return message
        case .unknownError:
            return "不明なエラーが発生しました。"
        }
    }
}

struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    let studentID: String?
    let department: String?
    let grade: String?
}

// 会員登録リクエストのためのモデル追加
struct SignUpRequest: Codable {
    let name: String
    let email: String
    let password: String
    let studentID: String
    let department: String
    let grade: String
}

class NetworkService {
    static let shared = NetworkService()
    
    private lazy var db = Firestore.firestore()
    private let firebaseManager = FirebaseManager.shared
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    // ログインメソッド
    func login(email: String, password: String) async -> Result<UserProfile, NetworkError> {
        do {
            // Firebase Authでログイン
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = authResult.user
            
            // Firestoreからユーザー情報を取得
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let userData = userDoc.data() else {
                return .failure(.invalidData)
            }
            
            // UserDefaultsにユーザーIDを保存
            UserDefaults.standard.set(user.uid, forKey: "currentUserId")
            
            // ユーザープロフィールオブジェクトを作成
            let userProfile = UserProfile(
                id: user.uid,
                name: userData["name"] as? String ?? "",
                email: user.email ?? "",
                studentID: userData["studentID"] as? String,
                department: userData["department"] as? String,
                grade: userData["grade"] as? String
            )
            
            return .success(userProfile)
        } catch {
            // エラー処理
            let errorMessage: String
            let nsError = error as NSError
            // Firebase AuthErrorCodeは.Code(rawValue:)ではなくrawValueで直接比較する必要がある
            switch nsError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "パスワードが正しくありません。"
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "該当するメールアドレスのユーザーが見つかりません。"
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "メールアドレスの形式が正しくありません。"
            case AuthErrorCode.userDisabled.rawValue:
                errorMessage = "このアカウントは無効化されています。"
            case AuthErrorCode.tooManyRequests.rawValue:
                errorMessage = "リクエストが多すぎます。しばらくしてから再度お試しください。"
            default:
                errorMessage = error.localizedDescription
            }
            return .failure(.authError(errorMessage))
        }
    }
    
    // 会員登録メソッド
    func signUp(name: String, email: String, password: String, studentID: String, department: String, grade: String) async -> Result<UserProfile, NetworkError> {
        do {
            // Firebase Authでユーザー作成
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = authResult.user
            // メールアドレス認証メール送信
            try await user.sendEmailVerification()
            // Firestoreにユーザー追加情報保存
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "studentID": studentID,
                "department": department,
                "grade": grade,
                "createdAt": FieldValue.serverTimestamp()
            ]
            try await db.collection("users").document(user.uid).setData(userData)
            // UserDefaultsにユーザーIDを保存
            UserDefaults.standard.set(user.uid, forKey: "currentUserId")
            // ユーザープロフィールオブジェクトを作成
            let userProfile = UserProfile(
                id: user.uid,
                name: name,
                email: email,
                studentID: studentID,
                department: department,
                grade: grade
            )
            return .success(userProfile)
        } catch {
            // エラー処理
            let errorMessage: String
            let nsError = error as NSError
            switch nsError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "すでに使用されているメールアドレスです。"
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "メールアドレスの形式が正しくありません。"
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "パスワードが弱すぎます。"
            default:
                errorMessage = error.localizedDescription
            }
            return .failure(.authError(errorMessage))
        }
    }
    
    // ログアウトメソッド
    func logout() -> Result<Void, NetworkError> {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "currentUserId")
            return .success(())
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    
    // 現在のログイン状態を確認
    var isLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // 現在のユーザー情報を取得
    func getCurrentUser() async -> Result<UserProfile, NetworkError> {
        guard let user = Auth.auth().currentUser else {
            return .failure(.authError("ログインされたユーザーがいません。"))
        }
        
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let userData = userDoc.data() else {
                return .failure(.invalidData)
            }
            
            // ユーザープロフィールオブジェクトを作成
            let userProfile = UserProfile(
                id: user.uid,
                name: userData["name"] as? String ?? "",
                email: user.email ?? "",
                studentID: userData["studentID"] as? String,
                department: userData["department"] as? String,
                grade: userData["grade"] as? String
            )
            
            return .success(userProfile)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
}

// MARK: - Real-time Sync Extensions
extension NetworkService {
    
    // MARK: - Post Sync
    func syncPost(_ post: Post, context: NSManagedObjectContext) async throws {
        guard let postId = post.id?.uuidString else { return }
        
        let postData: [String: Any] = [
            "title": post.title ?? "",
            "content": post.content ?? "",
            "authorId": post.authorId ?? currentUserId,
            "authorName": getAuthorName(for: post.authorId),
            "categoryId": post.category?.id?.uuidString ?? "",
            "categoryName": post.category?.name ?? "",
            "likeCount": post.likeCount,
            "commentCount": post.comments?.count ?? 0,
            "viewCount": post.viewCount,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "isAnonymous": false
        ]
        
        try await db.collection("posts").document(postId).setData(postData, merge: true)
        
        // Sync images if any
        if post.hasImages {
            try await syncPostImages(postId: postId, images: post.images)
        }
    }
    
    private func syncPostImages(postId: String, images: [UIImage]) async throws {
        // This would require Firebase Storage - implement when needed
        var imageUrls: [String] = []
        
        // For now, just store empty array - implement storage upload later
        try await db.collection("posts").document(postId).updateData([
            "imageUrls": imageUrls
        ])
    }
    
    func listenToPostsInCategory(_ categoryName: String, context: NSManagedObjectContext, completion: @escaping ([BoardPost]) -> Void) {
        db.collection("posts")
            .whereField("categoryName", isEqualTo: categoryName)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let posts = documents.compactMap { doc -> BoardPost? in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let content = data["content"] as? String,
                          let authorId = data["authorId"] as? String,
                          let authorName = data["authorName"] as? String else { return nil }
                    
                    return BoardPost(
                        id: doc.documentID,
                        title: title,
                        content: content,
                        authorId: authorId,
                        authorName: authorName,
                        authorProfileImage: nil,
                        categoryId: data["categoryId"] as? String ?? "",
                        categoryName: data["categoryName"] as? String ?? "",
                        imageUrls: data["imageUrls"] as? [String],
                        likeCount: data["likeCount"] as? Int ?? 0,
                        commentCount: data["commentCount"] as? Int ?? 0,
                        viewCount: data["viewCount"] as? Int ?? 0,
                        likedBy: data["likedBy"] as? [String],
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isAnonymous: data["isAnonymous"] as? Bool ?? false
                    )
                }
                
                DispatchQueue.main.async {
                    completion(posts)
                }
            }
    }
    
    // MARK: - Comment Sync
    func syncComment(_ comment: Comment, context: NSManagedObjectContext) async throws {
        guard let commentId = comment.id?.uuidString,
              let postId = comment.post?.id?.uuidString else { return }
        
        let commentData: [String: Any] = [
            "postId": postId,
            "content": comment.content ?? "",
            "authorId": comment.authorId ?? currentUserId,
            "authorName": getAuthorName(for: comment.authorId),
            "likeCount": comment.likeCount,
            "createdAt": FieldValue.serverTimestamp(),
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
    
    func listenToCommentsForPost(_ postId: String, completion: @escaping ([BoardComment]) -> Void) {
        db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let comments = documents.compactMap { doc -> BoardComment? in
                    let data = doc.data()
                    guard let content = data["content"] as? String,
                          let authorId = data["authorId"] as? String,
                          let authorName = data["authorName"] as? String,
                          let postId = data["postId"] as? String else { return nil }
                    
                    return BoardComment(
                        id: doc.documentID,
                        postId: postId,
                        content: content,
                        authorId: authorId,
                        authorName: authorName,
                        authorProfileImage: nil,
                        likeCount: data["likeCount"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isAnonymous: data["isAnonymous"] as? Bool ?? false,
                        parentId: data["parentId"] as? String,
                        replyCount: data["replyCount"] as? Int ?? 0
                    )
                }
                
                DispatchQueue.main.async {
                    completion(comments)
                }
            }
    }
    
    // MARK: - Category Sync
    func syncCategory(_ category: Category, context: NSManagedObjectContext) async throws {
        guard let categoryId = category.id?.uuidString else { return }
        
        let categoryData: [String: Any] = [
            "name": category.name ?? "",
            "icon": category.icon ?? "",
            "description": "", // No categoryDescription in CoreData model
            "order": category.order,
            "postCount": category.posts?.count ?? 0, // Calculate from relationship
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("categories").document(categoryId).setData(categoryData, merge: true)
    }
    
    func listenToCategories(completion: @escaping ([BoardCategory]) -> Void) {
        db.collection("categories")
            .order(by: "order", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let categories = documents.compactMap { doc -> BoardCategory? in
                    let data = doc.data()
                    guard let name = data["name"] as? String else { return nil }
                    
                    return BoardCategory(
                        id: doc.documentID,
                        name: name,
                        icon: data["icon"] as? String ?? "folder",
                        description: data["description"] as? String,
                        order: data["order"] as? Int ?? 0,
                        postCount: data["postCount"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                
                DispatchQueue.main.async {
                    completion(categories)
                }
            }
    }
    
    // MARK: - Notification Sync
    func sendNotification(userId: String, type: String, title: String, message: String, relatedPostId: UUID?) async throws {
        let notificationData: [String: Any] = [
            "userId": userId,
            "type": type,
            "title": title,
            "message": message,
            "relatedPostId": relatedPostId?.uuidString ?? "",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false
        ]
        
        try await db.collection("notifications").addDocument(data: notificationData)
    }
    
    func listenToNotifications(userId: String, completion: @escaping (Int) -> Void) {
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let unreadCount = documents.filter { doc in
                    !(doc.data()["isRead"] as? Bool ?? false)
                }.count
                
                DispatchQueue.main.async {
                    UserDefaults.standard.set(unreadCount > 0, forKey: "hasUnreadNotifications")
                    completion(unreadCount)
                }
            }
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - Chat Sync
    func createChatRoom(name: String, isGroup: Bool, participants: [String]) async throws -> String {
        let roomData: [String: Any] = [
            "name": name,
            "isGroup": isGroup,
            "participants": participants,
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        let docRef = try await db.collection("chatRooms").addDocument(data: roomData)
        return docRef.documentID
    }
    
    func sendMessage(roomId: String, content: String, senderId: String) async throws {
        let messageData: [String: Any] = [
            "roomId": roomId,
            "content": content,
            "senderID": senderId,
            "timestamp": FieldValue.serverTimestamp(),
            "messageType": "text"
        ]
        
        // Add message
        try await db.collection("messages").addDocument(data: messageData)
        
        // Update chat room last message
        try await db.collection("chatRooms").document(roomId).updateData([
            "lastMessage": content,
            "lastMessageTime": FieldValue.serverTimestamp()
        ])
    }
    
    func listenToMessages(roomId: String, completion: @escaping ([ChatMessage]) -> Void) {
        db.collection("messages")
            .whereField("roomId", isEqualTo: roomId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let messages = documents.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    guard let content = data["content"] as? String,
                          let senderId = data["senderID"] as? String else { return nil }
                    
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
                    
                    return ChatMessage(
                        content: content,
                        senderID: senderId,
                        isCurrentUser: senderId == currentUserId,
                        timestamp: timestamp
                    )
                }
                
                DispatchQueue.main.async {
                    completion(messages)
                }
            }
    }
    
    // MARK: - Course Evaluation Sync
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
            "createdAt": FieldValue.serverTimestamp(),
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
    
    // MARK: - Course Sync (Timetable)
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
    
    // MARK: - Helper Methods
    private var currentUserId: String {
        return UserDefaults.standard.string(forKey: "currentUserId") ?? "anonymous_user"
    }
    
    private func getAuthorName(for authorId: String?) -> String {
        if let authorId = authorId,
           let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
           authorId == currentUserId {
            return UserDefaults.standard.string(forKey: "currentUserName") ?? "匿名ユーザー"
        }
        return "匿名ユーザー"
    }
    
    private func colorToHex(_ color: Color) -> String {
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
