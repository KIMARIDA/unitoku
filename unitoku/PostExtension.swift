import SwiftUI
import CoreData
import Foundation
import UIKit
// CoreDataModels의 타입 별칭을 사용합니다

// UserDefaults에 이미지 데이터를 저장하기 위한 키 생성 함수
private func imageStorageKey(for postID: UUID) -> String {
    return "post_images_\(postID.uuidString)"
}

// Post 클래스 확장
extension CDPost {
    var imageData: [Data] {
        get {
            guard let id = self.id else { return [] }
            return UserDefaults.standard.array(forKey: imageStorageKey(for: id)) as? [Data] ?? []
        }
        set {
            guard let id = self.id else { return }
            UserDefaults.standard.set(newValue, forKey: imageStorageKey(for: id))
        }
    }
    
    var images: [UIImage] {
        get {
            return imageData.compactMap { UIImage(data: $0) }
        }
        set {
            imageData = newValue.compactMap { $0.jpegData(compressionQuality: 0.7) }
        }
    }
    
    var hasImages: Bool {
        return !images.isEmpty
    }
}
