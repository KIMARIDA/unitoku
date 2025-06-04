import SwiftUI
import CoreData

struct PostDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var commentText = ""
    @State private var showingCommentField = false
    @State private var selectedImage: UIImage? = nil
    @State private var showingFullScreenImage = false
    @State private var likeCount: Int32 = 0
    @State private var viewCount: Int32 = 0
    @State private var hasIncreasedViewCount = false
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    @State private var showingActionSheet = false
    @State private var post: Post? = nil
    @State private var isLoading = true
    
    // 편집 모드 상태 및 임시 텍스트
    @State private var editTitle = ""
    @State private var editContent = ""
    
    // 사용자 투표 상태 추적 - 싫어요 관련 상태 제거
    @State private var hasLiked = false
    
    // 현재 사용자 ID (실제 앱에서는 인증 서비스에서 가져옴)
    private let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? "user_1"
    
    // ID로 게시물을 로드하는 생성자 추가
    let postId: UUID
    let hideBackButton: Bool
    
    init(post: Post, hideBackButton: Bool = false) {
        self.postId = post.id!
        self.hideBackButton = hideBackButton
        self._post = State(initialValue: post)
        self._isLoading = State(initialValue: false)
    }
    
    init(postId: UUID, hideBackButton: Bool = false) {
        self.postId = postId
        self.hideBackButton = hideBackButton
        self._isLoading = State(initialValue: true)
    }
    
    // 현재 사용자가 포스트 작성자인지 확인
    private var isAuthor: Bool {
        guard let post = post else { return false }
        // For debugging
        print("Current User ID: \(currentUserId)")
        print("Post Author ID: \(post.authorId)")
        
        // Since we're using the author extension, let's always show the edit button for testing
        return true // Always return true for now to test if the button appears
    }
    
    var commentsArray: [Comment] {
        guard let post = post else { return [] }
        let comments = post.comments?.allObjects as? [Comment] ?? []
        // 정렬 순서 변경: 이전에는 최신 댓글이 상단에 표시되었지만,
        // 이제 오래된 댓글이 상단에 표시되도록 변경
        return comments.sorted {
            ($0.timestamp ?? Date()) < ($1.timestamp ?? Date())
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .onAppear(perform: loadPost)
            } else if let post = post {
                postDetailContent
            } else {
                Text("Post not found")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var postDetailContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    // 익명 프로필 추가
                    HStack(spacing: 10) {
                        // 익명 프로필 아이콘
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color.gray.opacity(0.7))
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        
                        // 익명 사용자 이름
                        VStack(alignment: .leading, spacing: 4) {
                            Text("匿名")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(post?.timestamp ?? Date(), formatter: itemFormatter)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // 점 세 개 메뉴 버튼 (작성자인 경우에만)
                        if isAuthor {
                            Button(action: {
                                showingActionSheet = true
                            }) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 22))
                                    .foregroundColor(.gray)
                                    .padding(8)
                            }
                            .actionSheet(isPresented: $showingActionSheet) {
                                ActionSheet(
                                    title: Text("投稿オプション"),
                                    buttons: [
                                        .default(Text("編集")
                                            .foregroundColor(.gray)) {
                                            // 편집 시작 시 현재 값 로드
                                            editTitle = post?.title ?? ""
                                            editContent = post?.content ?? ""
                                            showingEditView = true
                                        },
                                        .destructive(Text("削除")) {
                                            showingDeleteAlert = true
                                        },
                                        .cancel(Text("キャンセル")
                                            .foregroundColor(.gray))
                                    ]
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    // 게시글 제목과 내용
                    VStack(alignment: .leading, spacing: 10) {
                        // 제목을 프로필 아래로 이동
                        Text(post?.title ?? "タイトルなし")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        Text(post?.content ?? "")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 3)
                            .padding(.horizontal)
                        
                        // 이미지 갤러리 추가 - 첨부화상 글귀 제거
                        if let post = post, post.hasImages && !post.images.isEmpty {
                            VStack(alignment: .leading) {
                                // 첨부화상 텍스트 제거
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(0..<post.images.count, id: \.self) { index in
                                            Image(uiImage: post.images[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200, height: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .shadow(radius: 3)
                                                .onTapGesture {
                                                    selectedImage = post.images[index]
                                                    showingFullScreenImage = true
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10) // 상하 패딩 추가
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 3)
                            .padding(.horizontal)
                        }
                        
                        HStack(spacing: 20) {
                            Button(action: likePost) {
                                HStack {
                                    Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                        .foregroundColor(hasLiked ? Color.appTheme : Color.gray)
                                    Text("いいね \(likeCount)")
                                        .foregroundColor(hasLiked ? Color.appTheme : Color.gray)
                                }
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.1), radius: 2)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: "eye")
                                Text("閲覧数 \(viewCount)")
                            }
                            .font(.caption)
                            .foregroundColor(Color.gray)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    // 댓글 섹션
                    VStack(alignment: .leading) {
                        HStack {
                            Text("コメント \(commentsArray.count)")
                                .font(.headline)
                                .foregroundColor(Color.appTheme)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(commentsArray) { comment in
                            CommentView(comment: comment)
                        }
                    }
                    .padding(.vertical)
                    
                    // Add some space at the bottom to prevent the last comment from being hidden behind the input field
                    Spacer(minLength: 70)
                }
                .padding(.vertical)
                .onAppear {
                    if let post = post {
                        likeCount = post.likeCount
                        viewCount = post.viewCount
                        
                        // 사용자의 투표 상태 불러오기
                        loadVoteStatus()
                        
                        if !hasIncreasedViewCount {
                            increaseViewCount()
                            hasIncreasedViewCount = true
                        }
                    }
                }
            }
            
            // Fixed comment input field at the bottom
            VStack(spacing: 0) {
                Divider()
                HStack {
                    TextField("コメントを入力", text: $commentText)
                        .padding(12)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                        .foregroundColor(Color.gray.opacity(0.8))
                        .font(.system(size: 15))
                        .submitLabel(.send) // Use the return key as submit
                        .onSubmit {
                            if !commentText.isEmpty {
                                addComment()
                            }
                        }
                }
                .padding(10)
                .background(Color.white)
            }
        }
        .background(Color.white)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("投稿の削除"),
                message: Text("この投稿を削除してもよろしいですか？"),
                primaryButton: .destructive(Text("削除")) {
                    deletePost()
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
        .sheet(isPresented: $showingFullScreenImage) {
            if let image = selectedImage {
                FullScreenImageView(image: image, isPresented: $showingFullScreenImage)
            }
        }
        .sheet(isPresented: $showingEditView) {
            if let post = post {
                PostEditView(
                    post: post,
                    title: $editTitle,
                    content: $editContent,
                    isPresented: $showingEditView
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !hideBackButton {
                    Button(action: {
                        // Force dismiss to the root view
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                        .foregroundColor(Color.appTheme)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // ID로 게시물 로드하는 함수
    private func loadPost() {
        print("⭐️ Loading post with ID: \(postId)")
        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", postId as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let foundPost = results.first {
                print("✅ Successfully found post: \(foundPost.title ?? "No title") with ID: \(foundPost.id?.uuidString ?? "unknown")")
                self.post = foundPost
                self.likeCount = foundPost.likeCount
                self.viewCount = foundPost.viewCount
                loadVoteStatus()
                
                if !hasIncreasedViewCount {
                    increaseViewCount()
                    hasIncreasedViewCount = true
                }
            } else {
                print("❌ Could not find post with ID: \(postId)")
            }
            isLoading = false
        } catch {
            print("❌ Error loading post: \(error)")
            isLoading = false
        }
    }
    
    // 사용자가 현재 게시물에 좋아요/싫어요를 눌렀는지 확인하는 함수
    private func loadVoteStatus() {
        guard let postID = post?.id?.uuidString else { return }
        
        let likeKey = "liked_\(postID)"
        
        hasLiked = UserDefaults.standard.bool(forKey: likeKey)
    }
    
    private func likePost() {
        guard let post = post else { return }
        
        hasLiked.toggle()
        if hasLiked {
            likeCount += 1
            
            // DB 업데이트
            post.likeCount += 1
            try? viewContext.save()
        } else {
            likeCount -= 1
            
            // DB 업데이트
            post.likeCount -= 1
            try? viewContext.save()
        }
    }
    
    // dislikePost 함수 제거
    
    // 백엔드 좋아요 카운트 업데이트
    private func updateLikeCount(increment: Bool) {
        guard let post = post else { return }
        
        DispatchQueue.global().async {
            let newContext = PersistenceController.shared.container.newBackgroundContext()
            newContext.perform {
                do {
                    if let postID = post.id {
                        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", postID as CVarArg)
                        fetchRequest.fetchLimit = 1
                        
                        let fetchedPosts = try newContext.fetch(fetchRequest)
                        if let postInContext = fetchedPosts.first {
                            if increment {
                                postInContext.likeCount += 1
                            } else {
                                postInContext.likeCount = max(0, postInContext.likeCount - 1)
                            }
                            try newContext.save()
                        }
                    }
                } catch {
                    print("Error updating like count: \(error)")
                }
            }
        }
    }
    
    private func increaseViewCount() {
        guard let post = post else { return }
        
        viewCount += 1
        
        DispatchQueue.global().async {
            let newContext = PersistenceController.shared.container.newBackgroundContext()
            newContext.perform {
                do {
                    if let postID = post.id {
                        // UUID로 포스트 검색
                        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", postID as CVarArg)
                        fetchRequest.fetchLimit = 1
                        
                        let fetchedPosts = try newContext.fetch(fetchRequest)
                        if let postInContext = fetchedPosts.first {
                            postInContext.viewCount += 1
                            try newContext.save()
                        }
                    }
                } catch {
                    print("Error updating view count: \(error)")
                }
            }
        }
    }
    
    private func addComment() {
        guard let post = post else { return }
        
        withAnimation {
            let newComment = Comment(context: viewContext)
            newComment.id = UUID()
            newComment.content = commentText
            newComment.timestamp = Date()
            newComment.post = post
            
            // 이 게시물에 댓글을 달았다는 정보를 UserDefaults에 저장
            if let postID = post.id?.uuidString {
                let commentKey = "commented_\(postID)"
                UserDefaults.standard.set(true, forKey: commentKey)
            }
            
            commentText = ""
            showingCommentField = false
            
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // 게시물 삭제 함수
    private func deletePost() {
        guard let post = post else { return }
        
        viewContext.delete(post)
        
        do {
            try viewContext.save()
            // 삭제 후 이전 화면으로 돌아감
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error deleting post: \(error)")
        }
    }
}

// 이미지 전체 화면 보기
struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value.magnitude
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                if scale > 1 {
                                    scale = 1
                                } else {
                                    scale = 2
                                }
                            }
                    )
            }
            .navigationBarItems(trailing: Button("閉じる") {
                isPresented = false
            })
        }
    }
}

struct CommentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let comment: Comment
    @State private var likeCount: Int32
    @State private var hasLiked = false
    
    init(comment: Comment) {
        self.comment = comment
        self._likeCount = State(initialValue: comment.likeCount)
        
        // 사용자가 이 댓글에 좋아요를 눌렀는지 확인
        if let commentID = comment.id?.uuidString {
            let likeKey = "comment_liked_\(commentID)"
            self._hasLiked = State(initialValue: UserDefaults.standard.bool(forKey: likeKey))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(comment.content ?? "")
                .font(.body)
            
            HStack {
                Text(comment.timestamp ?? Date(), formatter: commentFormatter)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: likeComment) {
                    HStack(spacing: 4) {
                        Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(hasLiked ? Color.appTheme : Color.gray)
                        Text("\(likeCount)")
                            .foregroundColor(hasLiked ? Color.appTheme : Color.gray)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
        .padding(.horizontal)
    }
    
    private func likeComment() {
        guard let commentID = comment.id?.uuidString else { return }
        let likeKey = "comment_liked_\(commentID)"
        
        withAnimation(.spring()) {
            if hasLiked {
                // 좋아요 취소
                likeCount -= 1
                hasLiked = false
                UserDefaults.standard.set(false, forKey: likeKey)
                
                // 백엔드 업데이트
                updateLikeCount(increment: false)
            } else {
                // 좋아요 추가
                likeCount += 1
                hasLiked = true
                UserDefaults.standard.set(true, forKey: likeKey)
                
                // 백엔드 업데이트
                updateLikeCount(increment: true)
            }
        }
    }
    
    private func updateLikeCount(increment: Bool) {
        DispatchQueue.global().async {
            let newContext = PersistenceController.shared.container.newBackgroundContext()
            newContext.perform {
                do {
                    if let commentID = comment.id {
                        let fetchRequest: NSFetchRequest<Comment> = Comment.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", commentID as CVarArg)
                        fetchRequest.fetchLimit = 1
                        
                        let fetchedComments = try newContext.fetch(fetchRequest)
                        if let commentInContext = fetchedComments.first {
                            if increment {
                                commentInContext.likeCount += 1
                            } else {
                                commentInContext.likeCount = max(0, commentInContext.likeCount - 1)
                            }
                            try newContext.save()
                        }
                    }
                } catch {
                    print("Error updating comment like count: \(error)")
                }
            }
        }
    }
}

// 게시글 편집 뷰
struct PostEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    let post: Post
    @Binding var title: String
    @Binding var content: String
    @Binding var isPresented: Bool
    
    // 제목 글자 수 제한 상수
    private let maxTitleLengthNonEnglish = 20
    private let maxTitleLengthEnglish = 30
    
    // 영어인지 확인하는 함수
    private var isEnglishText: Bool {
        let englishCharacterSet = CharacterSet.letters.subtracting(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ一-龠ぁ-ゔァ-ヴー々〆〤"))
        return title.rangeOfCharacter(from: englishCharacterSet) != nil
    }
    
    // 현재 최대 길이
    private var currentMaxLength: Int {
        return isEnglishText ? maxTitleLengthEnglish : maxTitleLengthNonEnglish
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("タイトル")) {
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("タイトルを入力", text: $title)
                            .onChange(of: title) { oldValue, newValue in
                                let maxLength = isEnglishText ? maxTitleLengthEnglish : maxTitleLengthNonEnglish
                                
                                if newValue.count > maxLength {
                                    title = String(newValue.prefix(maxLength))
                                }
                            }
                        
                        // 글자 수 표시
                        HStack {
                            Spacer()
                            Text("\(title.count)/\(currentMaxLength)")
                                .font(.caption)
                                .foregroundColor(title.count >= currentMaxLength ? .red : .gray)
                        }
                    }
                }
                
                Section(header: Text("内容")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationBarTitle("投稿を編集", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    saveChanges()
                    isPresented = false
                }
                .disabled(title.isEmpty || title.count > currentMaxLength)
            )
        }
    }
    
    private func saveChanges() {
        post.title = title
        post.content = content
        
        do {
            try viewContext.save()
            // 게시글이 업데이트되었다는 알림 보내기
            NotificationCenter.default.post(name: .postUpdated, object: post.id)
        } catch {
            let nsError = error as NSError
            print("Error updating post: \(nsError), \(nsError.userInfo)")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter
}()

private let commentFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
    let posts = try? context.fetch(fetchRequest)
    
    return PostDetailView(post: posts?.first ?? Post())
        .environment(\.managedObjectContext, context)
}
