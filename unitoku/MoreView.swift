import SwiftUI

struct MoreView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showFavorites = false
    @State private var showMyPosts = false
    @State private var showMyComments = false
    @State private var showBlockList = false
    @State private var showFAQ = false
    @State private var showEvents = false
    @State private var showLanguageSettings = false
    
    // Mock user data for profile
    @State private var username = "匿名ユーザー"
    @State private var profileIcon = "person.circle.fill"
    
    var body: some View {
        NavigationView {
            List {
                // 모든 메뉴 항목을 단일 섹션으로 통합
                Section {
                    // 사용자 정보
                    HStack {
                        Image(systemName: profileIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color.appTheme)
                            .padding(5)
                            .background(Color.appTheme.opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(username)
                                .font(.headline)
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    
                    // お気に入り掲示板
                    SettingsRow(title: "お気に入り掲示板", iconName: "heart.fill", iconColor: .pink) {
                        showFavorites = true
                    }
                    
                    // 自分の投稿履歴
                    SettingsRow(title: "自分の投稿履歴", iconName: "doc.text.fill", iconColor: .orange) {
                        showMyPosts = true
                    }
                    
                    // コメント履歴
                    SettingsRow(title: "コメント履歴", iconName: "bubble.left.fill", iconColor: .green) {
                        showMyComments = true
                    }
                    
                    // ブラックリスト管理
                    SettingsRow(title: "ブラックリスト管理", iconName: "person.crop.circle.badge.xmark", iconColor: .red) {
                        showBlockList = true
                    }
                    
                    // よくある質問
                    SettingsRow(title: "よくある質問", iconName: "questionmark.circle.fill", iconColor: .purple) {
                        showFAQ = true
                    }
                    
                    // イベント / キャンペーン情報
                    SettingsRow(title: "イベント / キャンペーン情報", iconName: "party.popper.fill", iconColor: .purple) {
                        showEvents = true
                    }
                    
                    // 言語設定
                    SettingsRow(title: "言語設定", iconName: "character.bubble", iconColor: .blue) {
                        showLanguageSettings = true
                    }
                    
                    // 버전 정보
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "graduationcap.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color.appTheme)
                            
                            Text("Unitoku v1.0.0")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    // 로그아웃 (맨 아래로 이동 및 빨간색 글자로 변경)
                    Button(action: {
                        // ログアウト処理
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundColor(.red)
                                .padding(6)
                                .background(Color.red.opacity(0.15))
                                .cornerRadius(8)
                            
                            Text("ログアウト")
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("設定")
            
            // シートとナビゲーションリンク
            .sheet(isPresented: $showFavorites) {
                FavoritesListView()
            }
            .sheet(isPresented: $showMyPosts) {
                MyPostsView()
            }
            .sheet(isPresented: $showMyComments) {
                MyCommentsView()
            }
            // 他のシート表示は同様に追加
        }
    }
}

// 設定行コンポーネント
struct SettingsRow: View {
    var title: String
    var iconName: String
    var iconColor: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(iconColor)
                    .padding(6)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// セクションヘッダーコンポーネント
struct SectionHeader: View {
    var title: String
    var iconName: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.appTheme)
        }
    }
}

// お気に入り投稿一覧ビュー
struct FavoritesListView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Post.timestamp, ascending: false)],
        predicate: NSPredicate(format: "id IN %@", UserDefaults.standard.stringArray(forKey: "favoritePostIds") ?? []),
        animation: .default)
    private var favoritePosts: FetchedResults<Post>
    
    var body: some View {
        NavigationView {
            List {
                if favoritePosts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "star.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            
                            Text("お気に入りはまだありません")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("投稿にいいねをすると、ここに表示されます")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 100)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(favoritePosts) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(post.title ?? "タイトルなし")
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text(post.content ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.gray)
                                    Text("匿名")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text((post.timestamp ?? Date()).relativeTimeInJapanese())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("お気に入り")
            .navigationBarItems(
                leading: Button("戻る") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// 自分の投稿履歴ビュー
struct MyPostsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Post.timestamp, ascending: false)],
        predicate: NSPredicate(format: "authorId == %@", UserDefaults.standard.string(forKey: "currentUserId") ?? "unknown"),
        animation: .default)
    private var myPosts: FetchedResults<Post>
    
    var body: some View {
        NavigationView {
            List {
                if myPosts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            
                            Text("投稿はまだありません")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("投稿すると、ここに表示されます")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 100)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(myPosts) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(post.title ?? "タイトルなし")
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text(post.content ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                
                                HStack {
                                    Image(systemName: "hand.thumbsup.fill")
                                        .foregroundColor(.gray)
                                    Text("\(post.likeCount)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Image(systemName: "bubble.left.fill")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 8)
                                    let commentCount = post.comments?.count ?? 0
                                    Text("\(commentCount)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text((post.timestamp ?? Date()).relativeTimeInJapanese())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("自分の投稿")
            .navigationBarItems(
                leading: Button("戻る") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// コメント履歴ビュー
struct MyCommentsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Comment.timestamp, ascending: false)],
        predicate: NSPredicate(format: "authorId == %@", UserDefaults.standard.string(forKey: "currentUserId") ?? "unknown"),
        animation: .default)
    private var myComments: FetchedResults<Comment>
    
    var body: some View {
        NavigationView {
            List {
                if myComments.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            
                            Text("コメントはまだありません")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("コメントすると、ここに表示されます")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 100)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(myComments) { comment in
                        Button(action: {
                            if let post = comment.post, let postId = post.id {
                                NotificationCenter.default.post(
                                    name: Notification.Name("navigateToPost"),
                                    object: nil,
                                    userInfo: ["postId": postId]
                                )
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(comment.content ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                HStack {
                                    Text(comment.post?.title ?? "削除された投稿")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text((comment.timestamp ?? Date()).relativeTimeInJapanese())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("コメント履歴")
            .navigationBarItems(
                leading: Button("戻る") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
    }
}
