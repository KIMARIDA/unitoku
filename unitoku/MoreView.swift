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
    @State private var showProfileSettings = false
    @State private var showNotificationSettings = false
    @State private var showSyncSettings = false
    @State private var showLogoutAlert = false
    
    // User data from UserDefaults
    @State private var username = UserDefaults.standard.string(forKey: "username") ?? "匿名ユーザー"
    @State private var profileIcon = UserDefaults.standard.string(forKey: "profileIcon") ?? "person.circle.fill"
    
    var body: some View {
        NavigationView {
            List {
                // 모든 메뉴 항목을 단일 섹션으로 통합
                Section {
                    // 사용자 정보
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
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 5)
                    
                    // 로그아웃
                    SettingsRow(title: "ログアウト", iconName: "arrow.right.square", iconColor: .gray) {
                        showLogoutAlert = true
                    }
                    
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
                    
                    // 通知設定
                    SettingsRow(title: "通知設定", iconName: "bell.fill", iconColor: .blue) {
                        showNotificationSettings = true
                    }
                    
                    // データ同期設定
                    SettingsRow(title: "データ同期", iconName: "arrow.clockwise.icloud", iconColor: .green) {
                        showSyncSettings = true
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
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("もっと")
            
            // シートとナビゲーションリンク
            .sheet(isPresented: $showProfileSettings) {
                ProfileSettingsView()
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
            .sheet(isPresented: $showBlockList) {
                BlockListView()
            }
            .sheet(isPresented: $showFAQ) {
                FAQView()
            }
            .sheet(isPresented: $showEvents) {
                EventsView()
            }
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView()
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showSyncSettings) {
                SyncSettingsView()
            }
            .alert(isPresented: $showLogoutAlert) {
                Alert(
                    title: Text("ログアウト"),
                    message: Text("本当にログアウトしますか？"),
                    primaryButton: .destructive(Text("ログアウト")) {
                        // ログアウト処理
                        UserDefaults.standard.removeObject(forKey: "currentUserId")
                        UserDefaults.standard.removeObject(forKey: "username")
                        // 他のユーザー関連データをクリア
                        NotificationCenter.default.post(name: Notification.Name("userDidLogout"), object: nil)
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .onAppear {
                // UserDefaultsからユーザーデータを読み込み
                username = UserDefaults.standard.string(forKey: "username") ?? "匿名ユーザー"
                profileIcon = UserDefaults.standard.string(forKey: "profileIcon") ?? "person.circle.fill"
            }
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
    
    var body: some View {
        NavigationView {
            List {
                // 임시로 빈 상태 메시지만 표시
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
    
    var body: some View {
        NavigationView {
            List {
                // 임시로 빈 상태 메시지만 표시
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
    
    var body: some View {
        NavigationView {
            List {
                // 임시로 빈 상태 메시지만 표시
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

// よくある質問ビュー
struct FAQView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // よくある質問データモデル
    struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
        var isExpanded: Bool = false
    }
    
    @State private var faqs: [FAQItem] = [
        FAQItem(question: "ユニトクとは何ですか？", answer: "大学生のためのコミュニケーションプラットフォームです。授業の情報共有や友達作りなど、大学生活をより充実させるためのサービスです。"),
        FAQItem(question: "アカウント登録は必要ですか？", answer: "匿名でも閲覧は可能ですが、投稿やコメントをするにはアカウント登録が必要です。大学のメールアドレスを使って簡単に登録できます。"),
        FAQItem(question: "投稿は匿名ですか？", answer: "はい、投稿やコメントは全て匿名で行われます。ただし、不適切な投稿をした場合は運営側で対応することがあります。"),
        FAQItem(question: "アカウントを削除したいです", answer: "設定画面から「アカウント削除」を選択して手続きを行ってください。アカウントを削除すると、すべての投稿履歴が削除されます。"),
        FAQItem(question: "不適切な投稿を見つけた場合はどうしたらいいですか？", answer: "投稿右上の「...」メニューから「報告する」を選択して理由を選び報告してください。運営チームが確認し、適切な対応を行います。"),
        FAQItem(question: "他のユーザーをブロックする方法は？", answer: "ユーザーの投稿またはプロフィールから「ブロックする」を選択できます。ブロックしたユーザーの投稿は表示されなくなります。"),
        FAQItem(question: "パスワードを忘れてしまいました", answer: "ログイン画面の「パスワードを忘れた」から、登録済みのメールアドレスにパスワードリセットのリンクを送信できます。"),
        FAQItem(question: "通知設定を変更する方法は？", answer: "設定画面から「通知設定」を選択し、受け取りたい通知の種類をカスタマイズすることができます。")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach($faqs) { $faq in
                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: {
                            withAnimation {
                                faq.isExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Text(faq.question)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: faq.isExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if faq.isExpanded {
                            Text(faq.answer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 5)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("よくある質問")
            .navigationBarItems(leading: Button("戻る") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// ブラックリスト管理ビュー
struct BlockListView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var blockedUsers: [BlockedUser] = []
    @State private var showUnblockAlert = false
    @State private var selectedUser: BlockedUser? = nil
    
    // サンプルのブロックユーザー構造体
    struct BlockedUser: Identifiable {
        let id = UUID()
        let username: String
        let blockDate: Date
        let reason: String
    }
    
    var body: some View {
        NavigationView {
            List {
                if blockedUsers.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            
                            Text("ブラックリストは空です")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("ユーザーをブロックすると、ここに表示されます")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 100)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(blockedUsers) { user in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.headline)
                                
                                Text("ブロック理由: \(user.reason)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("ブロック日: \(formatDate(user.blockDate))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedUser = user
                                showUnblockAlert = true
                            }) {
                                Text("解除")
                                    .font(.footnote)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .onAppear(perform: loadBlockedUsers)
            .alert(isPresented: $showUnblockAlert) {
                Alert(
                    title: Text("ブロック解除"),
                    message: Text("\(selectedUser?.username ?? "")のブロックを解除しますか？"),
                    primaryButton: .destructive(Text("解除する")) {
                        if let selectedUser = selectedUser {
                            unblockUser(selectedUser)
                        }
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("ブラックリスト")
            .navigationBarItems(
                leading: Button("戻る") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func loadBlockedUsers() {
        // サンプルデータをロード
        // 実際の実装では、UserDefaultsまたはCoreDataから読み込む
        if blockedUsers.isEmpty {
            let blockedUsersData = UserDefaults.standard.array(forKey: "blockedUsers") as? [[String: Any]] ?? []
            
            // 本来はデコードするが、サンプルデータを使用
            if blockedUsersData.isEmpty {
                // サンプルデータ
                blockedUsers = [
                    BlockedUser(username: "荒らしユーザー1", blockDate: Date().addingTimeInterval(-60*60*24*7), reason: "スパムの投稿"),
                    BlockedUser(username: "問題ユーザー2", blockDate: Date().addingTimeInterval(-60*60*24*3), reason: "不適切なコメント")
                ]
            }
        }
    }
    
    private func unblockUser(_ user: BlockedUser) {
        // ユーザーのブロックを解除
        blockedUsers.removeAll { $0.id == user.id }
        
        // 実際の実装では、永続的な保存も行う
        // saveBlockedUsers()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// イベント/キャンペーン情報ビュー
struct EventsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // イベントデータモデル
    struct Event: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let date: Date
        let imageSystemName: String
        let isNew: Bool
        var isBookmarked: Bool = false
    }
    
    @State private var events: [Event] = [
        Event(title: "春の新歓祭り", description: "新入生向けの大学の各サークル紹介イベント。先輩たちと交流できる機会です。", date: Date().addingTimeInterval(60*60*24*3), imageSystemName: "sparkles", isNew: true),
        Event(title: "キャリアフォーラム2025", description: "就活支援イベント。企業の採用担当と直接話せるチャンスです。履歴書を持参すると特典があります。", date: Date().addingTimeInterval(60*60*24*10), imageSystemName: "briefcase.fill", isNew: true),
        Event(title: "学園祭実行委員募集", description: "今年の学園祭の企画・運営に参加しませんか？様々な役割で募集中です。", date: Date().addingTimeInterval(60*60*24*15), imageSystemName: "figure.wave", isNew: false),
        Event(title: "留学プログラム説明会", description: "海外協定校への留学プログラムについての説明会です。奨学金情報も提供します。", date: Date().addingTimeInterval(60*60*24*20), imageSystemName: "airplane", isNew: false),
        Event(title: "スタディーグループ", description: "期末試験対策のためのスタディーグループを開催します。一緒に勉強しませんか？", date: Date().addingTimeInterval(60*60*24*7), imageSystemName: "books.vertical.fill", isNew: false)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach($events) { $event in
                    EventRowView(event: $event)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("イベント情報")
            .navigationBarItems(leading: Button("戻る") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // イベント行コンポーネント
    struct EventRowView: View {
        @Binding var event: Event
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: event.imageSystemName)
                        .font(.title2)
                        .foregroundColor(Color.appTheme)
                        .frame(width: 40, height: 40)
                        .background(Color.appTheme.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(event.title)
                                .font(.headline)
                            
                            if event.isNew {
                                Text("NEW")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(formatDate(event.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        event.isBookmarked.toggle()
                    }) {
                        Image(systemName: event.isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(event.isBookmarked ? Color.appTheme : .gray)
                    }
                }
                
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Spacer()
                    Button(action: {
                        // カレンダーに追加
                        addToCalendar(event: event)
                    }) {
                        Text("カレンダーに追加")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appTheme)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: date)
        }
        
        private func addToCalendar(event: Event) {
            // 実際にはカレンダーAPIを使用して追加する処理
            // EventKitを使ってカレンダーにイベントを追加する機能を実装
            // サンプル実装のため、成功トーストのみ表示
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// 言語設定ビュー
struct LanguageSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    struct Language: Identifiable {
        let id = UUID()
        let name: String
        let code: String
        let flag: String
    }
    
    let languages = [
        Language(name: "日本語", code: "ja", flag: "🇯🇵"),
        Language(name: "English", code: "en", flag: "🇺🇸"),
        Language(name: "한국어", code: "ko", flag: "🇰🇷"),
        Language(name: "简体中文", code: "zh-Hans", flag: "🇨🇳"),
        Language(name: "繁體中文", code: "zh-Hant", flag: "🇹🇼")
    ]
    
    @State private var selectedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "ja"
    @State private var showSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("言語を選択")) {
                    ForEach(languages) { language in
                        Button(action: {
                            selectedLanguage = language.code
                        }) {
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                Text(language.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedLanguage == language.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.appTheme)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Section(footer: Text("言語を変更すると、アプリを再起動する必要があります")) {
                    Button(action: {
                        UserDefaults.standard.set(selectedLanguage, forKey: "appLanguage")
                        showSaveConfirmation = true
                    }) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appTheme)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .alert(isPresented: $showSaveConfirmation) {
                Alert(
                    title: Text("言語設定を保存しました"),
                    message: Text("変更を適用するには、アプリを再起動してください"),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("言語設定")
            .navigationBarItems(leading: Button("戻る") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
