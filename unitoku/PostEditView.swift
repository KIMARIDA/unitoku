import Firebase

// PostEditView.swift
// 이 파일은 중복 정의 방지를 위해 비워둡니다.

extension PostEditView {
    func updateposts(postId: String, title: String, content: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("posts").document(postId).updateData([
            "title": title,
            "content": content
        ]) { error in
            if let error = error {
                print("Error updating post: \(error)")
                completion(false)
            } else {
                print("Post successfully updated in Firebase")
                completion(true)
            }
        }
    }
}
