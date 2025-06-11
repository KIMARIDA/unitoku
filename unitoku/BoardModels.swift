import Foundation
import FirebaseFirestore

// 게시판 카테고리 모델
struct BoardCategory: Identifiable, Codable {
    var id: String?
    var name: String
    var icon: String
    var description: String?
    var order: Int
    var postCount: Int = 0
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case description
        case order
        case postCount
        case createdAt
        case updatedAt
    }
    
    var documentId: String {
        return id ?? ""
    }
}

// 게시글 모델
struct BoardPost: Identifiable, Codable {
    var id: String?
    var title: String
    var content: String
    var authorId: String
    var authorName: String
    var authorProfileImage: String?
    var categoryId: String
    var categoryName: String
    var imageUrls: [String]?
    var likeCount: Int = 0
    var commentCount: Int = 0
    var viewCount: Int = 0
    var likedBy: [String]?
    var createdAt: Date
    var updatedAt: Date
    var isAnonymous: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case authorId
        case authorName
        case authorProfileImage
        case categoryId
        case categoryName
        case imageUrls
        case likeCount
        case commentCount
        case viewCount
        case likedBy
        case createdAt
        case updatedAt
        case isAnonymous
    }
    
    var documentId: String {
        return id ?? ""
    }
}

// 댓글 모델
struct BoardComment: Identifiable, Codable {
    var id: String?
    var postId: String
    var content: String
    var authorId: String
    var authorName: String
    var authorProfileImage: String?
    var likeCount: Int = 0
    var createdAt: Date
    var updatedAt: Date
    var isAnonymous: Bool = false
    var parentId: String?
    var replyCount: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId
        case content
        case authorId
        case authorName
        case authorProfileImage
        case likeCount
        case createdAt
        case updatedAt
        case isAnonymous
        case parentId
        case replyCount
    }
    
    var documentId: String {
        return id ?? ""
    }
}

// 이미지 업로드 상태 추적용 모델
struct UploadImage: Identifiable {
    var id = UUID()
    var uiImage: UIImage
    var url: String?
    var isUploaded: Bool = false
    var isUploading: Bool = false
    var uploadError: Error?
}

// 게시판 필터 옵션
enum BoardSortOption: String, CaseIterable {
    case newest = "最新順"
    case popular = "人気順"
    case commented = "コメント数順"
    case viewed = "閲覧数順"
}
