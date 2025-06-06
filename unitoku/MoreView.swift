import SwiftUI

struct MoreView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showProfileSettings = false
    @State private var showNotificationSettings = false
    @State private var showFavorites = false
    @State private var showMyPosts = false
    @State private var showMyComments = false
    @State private var showBlockList = false
    @State private var showTutorial = false
    @State private var showCommunityRules = false
    @State private var showReportForm = false
    @State private var showBlockSettings = false
    @State private var showContactForm = false
    @State private var showBugReport = false
    @State private var showFAQ = false
    @State private var showUpdates = false
    @State private var showSurvey = false
    @State private var showEvents = false
    @State private var showAnnouncements = false
    @State private var showLanguageSettings = false
    @State private var showRegionalSettings = false
    
    // Mock user data for profile
    @State private var username = "匿名ユーザー"
    @State private var profileIcon = "person.circle.fill"
    
    var body: some View {
        NavigationView {
            List {
                // プロフィールセクション
                Section {
                    Button(action: { showProfileSettings = true }) {
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
                                Text("プロフィールを編集")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 🧑‍💼 アカウント関連
                Section(header: SectionHeader(title: "🧑‍💼 アカウント関連", iconName: "person.fill")) {
                    SettingsRow(title: "プロフィール設定", iconName: "person.crop.circle", iconColor: .blue) {
                        showProfileSettings = true
                    }
                    
                    SettingsRow(title: "通知設定", iconName: "bell.badge", iconColor: .red) {
                        showNotificationSettings = true
                    }
                    
                    SettingsRow(title: "ログアウト", iconName: "arrow.right.square", iconColor: .gray) {
                        // ログアウト処理
                    }
                    
                    SettingsRow(title: "端末引き継ぎ", iconName: "arrow.triangle.2.circlepath.circle", iconColor: .purple) {
                        // 端末引き継ぎ処理
                    }
                }
                
                // 🌟 アプリの機能 / お役立ち情報
                Section(header: SectionHeader(title: "🌟 アプリの機能", iconName: "star.fill")) {
                    SettingsRow(title: "お気に入り投稿一覧", iconName: "heart.fill", iconColor: .pink) {
                        showFavorites = true
                    }
                    
                    SettingsRow(title: "自分の投稿履歴", iconName: "doc.text.fill", iconColor: .orange) {
                        showMyPosts = true
                    }
                    
                    SettingsRow(title: "コメント履歴", iconName: "bubble.left.fill", iconColor: .green) {
                        showMyComments = true
                    }
                    
                    SettingsRow(title: "ブラックリスト管理", iconName: "person.crop.circle.badge.xmark", iconColor: .red) {
                        showBlockList = true
                    }
                    
                    SettingsRow(title: "使用チュートリアル", iconName: "questionmark.circle.fill", iconColor: .blue) {
                        showTutorial = true
                    }
                }
                
                // 👮 安全・ルール関連
                Section(header: SectionHeader(title: "👮 安全・ルール関連", iconName: "shield.fill")) {
                    SettingsRow(title: "コミュニティルール", iconName: "doc.text.fill", iconColor: .blue) {
                        showCommunityRules = true
                    }
                    
                    SettingsRow(title: "通報する", iconName: "exclamationmark.triangle.fill", iconColor: .orange) {
                        showReportForm = true
                    }
                    
                    SettingsRow(title: "ブロック機能", iconName: "nosign", iconColor: .red) {
                        showBlockSettings = true
                    }
                }
                
                // 💬 お問い合わせ・サポート
                Section(header: SectionHeader(title: "💬 お問い合わせ・サポート", iconName: "bubble.left.and.bubble.right.fill")) {
                    SettingsRow(title: "お問い合わせ", iconName: "envelope.fill", iconColor: .blue) {
                        showContactForm = true
                    }
                    
                    SettingsRow(title: "不具合報告", iconName: "ant.fill", iconColor: .red) {
                        showBugReport = true
                    }
                    
                    SettingsRow(title: "よくある質問", iconName: "questionmark.circle.fill", iconColor: .purple) {
                        showFAQ = true
                    }
                }
                
                // 🎁 キャンペーン・その他
                Section(header: SectionHeader(title: "🎁 キャンペーン・その他", iconName: "gift.fill")) {
                    SettingsRow(title: "アップデート情報", iconName: "arrow.up.circle.fill", iconColor: .green) {
                        showUpdates = true
                    }
                    
                    SettingsRow(title: "ユーザーアンケート", iconName: "list.clipboard", iconColor: .orange) {
                        showSurvey = true
                    }
                    
                    SettingsRow(title: "イベント / キャンペーン情報", iconName: "party.popper.fill", iconColor: .purple) {
                        showEvents = true
                    }
                    
                    SettingsRow(title: "運営からのお知らせ", iconName: "megaphone.fill", iconColor: .blue) {
                        showAnnouncements = true
                    }
                }
                
                // 🌐 言語 / 地域設定
                Section(header: SectionHeader(title: "🌐 言語 / 地域設定", iconName: "globe")) {
                    SettingsRow(title: "言語設定", iconName: "character.bubble", iconColor: .blue) {
                        showLanguageSettings = true
                    }
                    
                    SettingsRow(title: "地域別人気投稿", iconName: "mappin.and.ellipse", iconColor: .red) {
                        showRegionalSettings = true
                    }
                }
                
                // アプリ情報
                Section {
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
                            
                            Text("© 2025 Unitoku Team")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("設定")
            
            // シートとナビゲーションリンク
            .sheet(isPresented: $showProfileSettings) {
                ProfileSettingsView()
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
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

// プロフィール設定ビュー
struct ProfileSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var username = "匿名ユーザー"
    @State private var selectedIcon = "person.circle.fill"
    @State private var showIconPicker = false
    
    // アイコン選択肢
    let iconOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "face.smiling.fill",
        "graduationcap.fill",
        "book.fill",
        "pencil.circle.fill",
        "moonphase.new.moon.fill",
        "star.fill",
        "heart.fill",
        "leaf.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("プロフィール情報")) {
                    HStack {
                        Spacer()
                        Button(action: { showIconPicker = true }) {
                            Image(systemName: selectedIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(Color.appTheme)
                                .padding(10)
                                .background(Color.appTheme.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(Color.appTheme)
                                        .font(.system(size: 24))
                                        .offset(x: 30, y: 30)
                                )
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    TextField("ニックネーム", text: $username)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Section(footer: Text("ニックネームとアイコンのみ公開されます。個人情報は含めないでください。")) {
                    Button(action: saveProfile) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appTheme)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("プロフィール設定")
            .navigationBarItems(leading: Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
        }
    }
    
    func saveProfile() {
        // プロフィール保存処理
        // UserDefaults等に保存
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(selectedIcon, forKey: "profileIcon")
        presentationMode.wrappedValue.dismiss()
    }
}

// アイコン選択ビュー
struct IconPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedIcon: String
    
    let iconOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "face.smiling.fill",
        "graduationcap.fill",
        "book.fill",
        "pencil.circle.fill",
        "moonphase.new.moon.fill",
        "star.fill",
        "heart.fill",
        "leaf.fill",
        "globe.asia.australia.fill",
        "music.note",
        "swift",
        "gamecontroller.fill",
        "paintpalette.fill"
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding(10)
                                .foregroundColor(selectedIcon == icon ? Color.white : Color.appTheme)
                                .background(selectedIcon == icon ? Color.appTheme : Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 2)
                                .overlay(
                                    Circle()
                                        .stroke(Color.appTheme, lineWidth: selectedIcon == icon ? 3 : 1)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("アイコンを選択")
            .navigationBarItems(trailing: Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 通知設定ビュー
struct NotificationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var postNotifications = true
    @State private var commentNotifications = true
    @State private var likeNotifications = true
    @State private var eventNotifications = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("通知設定")) {
                    Toggle("新しい投稿", isOn: $postNotifications)
                    Toggle("コメント", isOn: $commentNotifications)
                    Toggle("いいね", isOn: $likeNotifications)
                    Toggle("イベントとお知らせ", isOn: $eventNotifications)
                }
                
                Section(footer: Text("通知設定はいつでも変更できます")) {
                    Button(action: saveNotificationSettings) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appTheme)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("通知設定")
            .navigationBarItems(leading: Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func saveNotificationSettings() {
        // 通知設定保存処理
        UserDefaults.standard.set(postNotifications, forKey: "postNotifications")
        UserDefaults.standard.set(commentNotifications, forKey: "commentNotifications")
        UserDefaults.standard.set(likeNotifications, forKey: "likeNotifications")
        UserDefaults.standard.set(eventNotifications, forKey: "eventNotifications")
        presentationMode.wrappedValue.dismiss()
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