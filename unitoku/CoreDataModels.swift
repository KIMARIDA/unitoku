import Foundation
import CoreData
import SwiftUI

// MARK: - CoreData Type Aliases
// 이 파일은 CoreData 모델에 대한 타입 별칭(type alias)을 제공합니다.
// 다른 모델 정의와의 이름 충돌을 방지하기 위해 사용됩니다.

public typealias CDPost = Post
public typealias CDComment = Comment

// MARK: - 사용 지침
// CoreData를 사용하는 코드에서 이 타입 별칭을 사용하세요:
// 예시: let post = CDPost(context: viewContext)
// 대신: let post = Post(context: viewContext)

// MARK: - Post와 Comment를 사용하는 모든 파일에서 이 파일을 import 해야 합니다.
