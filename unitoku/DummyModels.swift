import Foundation
import SwiftUI
import CoreData

// 게시글 모델 (더미)
class DummyPost: NSManagedObject, Identifiable {
    @NSManaged var id: String?
    @NSManaged var title: String?
    @NSManaged var content: String?
    @NSManaged var timestamp: Date?
    @NSManaged var authorId: String?
    @NSManaged var authorName: String?
    @NSManaged var authorIcon: String?
    @NSManaged var likeCount: Int16
    @NSManaged var comments: NSSet?
    
    // 댓글 목록 접근을 위한 계산 속성
    var commentsArray: [DummyComment] {
        let set = comments as? Set<DummyComment> ?? []
        return set.sorted {
            $0.timestamp ?? Date() < $1.timestamp ?? Date()
        }
    }
}

// 댓글 모델 (더미)
class DummyComment: NSManagedObject, Identifiable {
    @NSManaged var id: String?
    @NSManaged var content: String?
    @NSManaged var timestamp: Date?
    @NSManaged var authorId: String?
    @NSManaged var authorName: String?
    @NSManaged var post: DummyPost?
}

// 더미 포스트 상세 뷰 (이름 변경)
struct DummyPostDetailView: View {
    var post: CDPost
    
    var body: some View {
        Text("포스트 상세 페이지: \(post.title ?? "제목 없음")")
    }
}
