import SwiftUI
import CoreData
import Foundation

// 새로고침 관련 코드 삭제 (CustomRefreshViewHome, InlineRefreshableScrollView 제거)

struct AnimatedFlameView: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotate: Double = 0
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Image(systemName: "flame.fill")
            .foregroundColor(Color(hex: "FF3B30")) // Apple's system red color
            .font(.system(size: 24))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotate))
            .offset(y: yOffset)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    self.scale = 1.2
                }
                
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    self.rotate = 5
                }
                
                withAnimation(Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    self.yOffset = -3
                }
            }
    }
}

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var isShowingNewPost = false
    @State private var showingAlert = false
    @State private var sortOption: SortOption = .popular // Default to popular sort
    @State private var isRefreshing = false // 새로고침 상태 추적
    @State private var refreshID = UUID() // 화면 강제 새로고침용 ID
    
    // 인기 게시물 FetchRequest
    @FetchRequest(
        entity: Post.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Post.likeCount, ascending: false)
        ],
        predicate: nil,
        animation: .default)
    private var hotPosts: FetchedResults<Post>
    
    // 카테고리 FetchRequest
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.order, ascending: true)
        ],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    // 일반 게시판 글 목록 FetchRequest - 일반 카테고리의 게시물만 표시
    @FetchRequest(
        entity: Post.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Post.timestamp, ascending: false)
        ],
        predicate: NSPredicate(format: "category.name == %@", "一般"),
        animation: .default)
    private var generalPosts: FetchedResults<Post>
    
    // Enum for sort options
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "最新順"
        case popular = "人気順"
        
        var id: String { self.rawValue }
        
        mutating func toggle() {
            self = self == .popular ? .newest : .popular
        }
    }
    
    var sortedPosts: [Post] {
        let posts = Array(generalPosts)
        switch sortOption {
        case .newest:
            return posts.sorted(by: { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) })
        case .popular:
            return posts.sorted(by: { $0.likeCount > $1.likeCount })
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading, spacing: 20) {
                    // 人気の投稿セクション
                    VStack(alignment: .leading) {
                        HStack {
                            AnimatedFlameView()
                                .foregroundColor(Color(hex: "FF3B30"))
                            Text("人気")
                                .font(.headline)
                                .foregroundColor(Color(hex: "FF3B30"))
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(hotPosts.prefix(5)) { post in
                                    NavigationLink(destination: PostDetailView(post: post)) {
                                        HotPostCard(post: post)
                                    }
                                }
                                
                                // 投稿がない場合のプレースホルダー表示
                                if (hotPosts.isEmpty) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        EmptyPostCard()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 게시판 섹션 - 정렬 버튼 추가
                    VStack(alignment: .leading) {
                        HStack {
                            // 정렬 버튼 (왼쪽에 위치) - 색상을 회색으로 변경
                            Button(action: {
                                sortOption.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: sortOption == .popular ? "flame.fill" : "clock.fill")
                                        .foregroundColor(.gray)
                                        .frame(width: 16, height: 16) // 고정 크기로 아이콘 사이즈 설정
                                    Text(sortOption.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                                .frame(height: 32) // 버튼 높이 고정
                            }
                            .buttonStyle(BorderlessButtonStyle()) // 정렬 버튼 탭 영역 분리
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        // 게시판 글 목록 - 정렬된 결과 사용
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(sortedPosts) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostRow(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                            }
                            
                            // 게시물이 없을 경우
                            if sortedPosts.isEmpty {
                                Text("投稿がありません")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.horizontal, 5)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 3)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .refreshable {
                await refreshData()
            }
            .id(refreshID) // 새로고침할 때 화면을 강제로 갱신
            .navigationTitle("立命館大学")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // 알림 버튼 추가 - 테두리만 핑크색
                        Button {
                            // 알림 기능은 나중에 구현
                        } label: {
                            Image(systemName: "bell")
                                .foregroundColor(Color(hex: "fd72ae"))
                                .imageScale(.large)
                        }
                        
                        // 항상 활성화된 글쓰기 버튼
                        Button {
                            handleWriteButtonTap()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(Color.appTheme)
                                .imageScale(.large)
                        }
                        
                        NavigationLink(destination: SearchView()) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingNewPost) {
                if let firstCategory = categories.first {
                    NewPostView(isPresented: $isShowingNewPost, category: firstCategory)
                        .environment(\.managedObjectContext, viewContext)
                } else if let defaultCategory = createDefaultCategory() {
                    NewPostView(isPresented: $isShowingNewPost, category: defaultCategory)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("エラー"),
                    message: Text("カテゴリーの作成に失敗しました。"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                print("HomeView appeared, categories count: \(categories.count)")
                if categories.isEmpty {
                    _ = createDefaultCategory()
                }
            }
        }
    }
    
    // 글쓰기 버튼 탭 처리 함수
    private func handleWriteButtonTap() {
        if categories.isEmpty && createDefaultCategory() == nil {
            showingAlert = true
            return
        }
        isShowingNewPost = true
    }
    
    // 기본 카테고리 생성 함수
    @discardableResult
    private func createDefaultCategory() -> Category? {
        let newCategory = Category(context: viewContext)
        newCategory.id = UUID()
        newCategory.name = "一般"
        newCategory.icon = "bubble.left"
        newCategory.order = 0
        
        do {
            try viewContext.save()
            return newCategory
        } catch {
            print("Error creating default category: \(error)")
            return nil
        }
    }
    
    // 데이터 새로고침 함수
    @MainActor
    private func refreshData() async {
        isRefreshing = true
        print("Starting refresh...")
        
        // 약간의 지연 시간을 추가하여 사용자가 새로고침을 인지할 수 있게 함
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 지연
        
        // CoreData 컨텍스트 새로고침
        viewContext.refreshAllObjects()
        
        // refreshID를 업데이트하여 UI 강제 새로고침
        refreshID = UUID()
        
        print("Refresh completed")
        isRefreshing = false
    }
}

// 게시물 행 컴포넌트
struct PostRow: View {
    let post: Post
    @State private var hasLiked: Bool = false
    @State private var hasCommented: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title ?? "タイトルなし")
                .font(.headline)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Text(post.content ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                // 좋아요 수 - 좋아요 눌렀을 때 색상 변경
                HStack(spacing: 4) {
                    Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundColor(hasLiked ? Color.appTheme : Color.appTheme.opacity(0.5))
                        .imageScale(.small)
                    Text("\(post.likeCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 댓글 수 - 댓글 달았을 때 색상 변경
                HStack(spacing: 4) {
                    Image(systemName: hasCommented ? "bubble.left.fill" : "bubble.left")
                        .foregroundColor(hasCommented ? Color.appTheme : Color.appTheme.opacity(0.5))
                        .imageScale(.small)
                    Text("\(post.comments?.count ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // 날짜
                Text(post.timestamp ?? Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .onAppear {
            // 게시물이 화면에 나타날 때 사용자 상호작용 확인
            checkIfUserLikedPost()
            checkIfUserCommentedPost()
        }
    }
    
    // 사용자가 해당 게시물에 좋아요를 눌렀는지 확인하는 함수
    private func checkIfUserLikedPost() {
        guard let postID = post.id?.uuidString else { return }
        let likeKey = "liked_\(postID)"
        hasLiked = UserDefaults.standard.bool(forKey: likeKey)
    }
    
    // 사용자가 해당 게시물에 댓글을 달았는지 확인하는 함수
    private func checkIfUserCommentedPost() {
        guard let postID = post.id?.uuidString else { return }
        let commentKey = "commented_\(postID)"
        hasCommented = UserDefaults.standard.bool(forKey: commentKey)
    }
}

// 投稿がない場合のプレースホルダー
struct EmptyPostCard: View {
    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(Color.gray.opacity(0.5))
                .padding(.bottom, 5)
            
            Text("投稿なし")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct HotPostCard: View {
    let post: Post
    @State private var hasLiked: Bool = false
    @State private var hasCommented: Bool = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title ?? "タイトルなし")
                .font(.headline)
                .lineLimit(1)
            
            Text(post.content ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Spacer()
            
            // 좋아요 및 댓글 수만 표시
            HStack {
                // 좋아요 (엄지 척) 표시 - 사용자가 좋아요 누른 경우 채워진 아이콘과 진한 색상 표시
                Button(action: {
                    toggleLike()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(hasLiked ? Color.appTheme : Color.appTheme.opacity(0.5))
                        Text("\(post.likeCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                // 댓글 수 표시
                HStack(spacing: 4) {
                    Image(systemName: hasCommented ? "bubble.left.fill" : "bubble.left")
                        .foregroundColor(hasCommented ? Color.appTheme : Color.appTheme.opacity(0.5))
                    Text("\(post.comments?.count ?? 0)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(width: 200, height: 130)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onAppear {
            // 게시물이 화면에 나타날 때 사용자가 좋아요를 눌렀는지 확인
            checkIfUserLikedPost()
            checkIfUserCommentedPost()
        }
    }
    
    // 사용자가 해당 게시물에 좋아요를 눌렀는지 확인하는 함수
    private func checkIfUserLikedPost() {
        guard let postID = post.id?.uuidString else { return }
        let likeKey = "liked_\(postID)"
        hasLiked = UserDefaults.standard.bool(forKey: likeKey)
    }
    
    // 사용자가 해당 게시물에 댓글을 달았는지 확인하는 함수
    private func checkIfUserCommentedPost() {
        guard let postID = post.id?.uuidString else { return }
        let commentKey = "commented_\(postID)"
        hasCommented = UserDefaults.standard.bool(forKey: commentKey)
    }
    
    // 좋아요 토글 기능
    private func toggleLike() {
        guard let postID = post.id?.uuidString else { return }
        let likeKey = "liked_\(postID)"
        
        // 좋아요 상태 토글
        hasLiked.toggle()
        
        // UserDefaults에 좋아요 상태 저장
        UserDefaults.standard.set(hasLiked, forKey: likeKey)
        
        // 게시물의 좋아요 수 업데이트
        if hasLiked {
            post.likeCount += 1
        } else {
            if post.likeCount > 0 {
                post.likeCount -= 1
            }
        }
        
        // CoreData에 변경사항 저장
        do {
            try viewContext.save()
        } catch {
            print("좋아요 업데이트 저장 실패: \(error)")
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
