import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var syncManager: SyncManager
    @State private var selectedTab = 0
    @State private var navigateToPostId: UUID? = nil
    @State private var isShowingPostDetail = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "house")
                    }
                    .tag(0)
                
                TimeTableView()
                    .tabItem {
                        Label("時間割", systemImage: "calendar")
                    }
                    .tag(1)
                
                DetailedCourseReviewView()
                    .tabItem {
                        Label("授業評価", systemImage: "star")
                    }
                    .tag(2)
                
                ChatView()
                    .tabItem {
                        Label("チャット", systemImage: "message")
                    }
                    .tag(3)
                
                MoreView()
                    .tabItem {
                        Label("もっと", systemImage: "ellipsis.circle")
                    }
                    .tag(4)
            }
            .accentColor(Color.appTheme)
            .onChange(of: selectedTab) { oldValue, newValue in
                // タブ切り替えのAnalytics記録
                let tabNames = ["home", "timetable", "course_review", "chat", "more"]
                if newValue >= 0 && newValue < tabNames.count {
                    AnalyticsManager.shared.logEvent(.screenView, parameters: [
                        "from_tab": oldValue < tabNames.count ? tabNames[oldValue] : "unknown",
                        "to_tab": tabNames[newValue]
                    ])
                }
            }
            .onAppear {
                // ナビゲーション通知リスナーの設定
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("navigateToPost"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let userInfo = notification.userInfo,
                       let postId = userInfo["postId"] as? UUID {
                        navigateToPostId = postId
                        isShowingPostDetail = true
                    }
                }
            }
            
            // 投稿詳細画面をオーバーレイとして表示
            if isShowingPostDetail, let postId = navigateToPostId {
                NavigationView {
                    PostDetailView(postId: postId, hideBackButton: true)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarItems(leading: Button(action: {
                            isShowingPostDetail = false
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "chevron.left")
                                Text("戻る")
                            }
                            .foregroundColor(Color.appTheme)
                        })
                }
                .transition(.move(edge: .trailing))
                .zIndex(1) // 最上層に表示
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowingPostDetail)
    }
}

// 時間割ビュー
struct TimeTableView: View {
    @StateObject private var viewModel = TimeTableViewModel()
    @State private var showingCourseDetail: Course? = nil
    @State private var showingNewCourseSheet = false
    @State private var showingCourseList = false
    @State private var editMode = false
    @State private var newCourse = Course(name: "", professor: "", room: "", weekday: .monday, period: .first, color: .blue)
    
    let weekdays = Weekday.allCases
    let periods = Period.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // 時間割表示
                    ScrollView {
                        timeTableContent
                    }
                    
                    // コース一覧ボタン
                    courseListButton
                }
            .navigationTitle("時間割")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .onAppear {
                // ログインユーザーの時間割をロード
                if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
                    viewModel.listenToUserCourses(userId: userId)
                }
            }
            .sheet(isPresented: $showingNewCourseSheet) {
                CourseFormView(course: $newCourse, viewModel: viewModel, isEditing: false) { success in
                    if success {
                        showingNewCourseSheet = false
                    }
                }
            }
            .sheet(item: $showingCourseDetail) { course in
                CourseDetailView(course: course, viewModel: viewModel)
            }
            .sheet(isPresented: $showingCourseList) {
                CourseListView(viewModel: viewModel)
            }
            }
        }
    }
    
    // 時間割コンテンツ
    private var timeTableContent: some View {
        VStack(spacing: 1) {
            // ヘッダー行（曜日）
            weekdayHeaderRow
            
            // 各時限行
            ForEach(periods) { period in
                periodRow(period: period)
            }
        }
        .padding(.bottom, 20)
    }
    
    // 曜日ヘッダー行
    private var weekdayHeaderRow: some View {
        HStack(spacing: 1) {
            // 時限列
            Text("時限")
                .font(.caption)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.systemBackground))
            
            // 曜日列
            ForEach(weekdays) { weekday in
                Text(weekday.rawValue)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
    }
    
    // 時限の行
    private func periodRow(period: Period) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 1) {
                // 時限表示
                periodCell(period: period)
                
                // 各曜日のセル
                ForEach(weekdays) { weekday in
                    courseCell(for: weekday, at: period)
                }
            }
            
            Divider()
        }
    }
    
    // 時限セル
    private func periodCell(period: Period) -> some View {
        VStack {
            Text("\(period.rawValue)")
                .font(.headline)
            Text(period.timeRange)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 40, height: 80)
        .background(Color(UIColor.systemBackground))
    }
    
    // 追加ボタン
    private var addButton: some View {
        Button(action: {
            newCourse = Course(
                name: "",
                professor: "",
                room: "",
                weekday: .monday,
                period: .first,
                color: viewModel.randomColor()
            )
            showingNewCourseSheet = true
        }) {
            Image(systemName: "plus")
        }
    }
    
    // 編集ボタン
    private var editButton: some View {
        Button(action: {
            editMode.toggle()
        }) {
            Text(editMode ? "完了" : "編集")
        }
    }
    
    // コース一覧ボタン
    private var courseListButton: some View {
        Button(action: {
            showingCourseList = true
        }) {
            HStack {
                Image(systemName: "list.bullet")
                Text("授業一覧")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.appTheme)
            .cornerRadius(10)
            .padding()
        }
    }
    
    // 特定の曜日・時限のセルを生成
    @ViewBuilder
    private func courseCell(for weekday: Weekday, at period: Period) -> some View {
        let course = viewModel.courseFor(weekday: weekday, period: period)
        
        ZStack {
            if let course = course {
                // 授業があるセルの内容
                courseCellContent(course: course)
            } else if editMode {
                // 編集モードで授業がない場合は追加ボタン
                Button(action: {
                    newCourse = Course(
                        name: "",
                        professor: "",
                        room: "",
                        weekday: weekday,
                        period: period,
                        color: viewModel.randomColor()
                    )
                    showingNewCourseSheet = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }
    
    // 空のセル
    private func emptyCell() -> some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
    }
    
    // 授業があるセルの内容
    private func courseCellContent(course: Course) -> some View {
        Button(action: {
            // 詳細画面をスキップして直接編集画面を表示
            newCourse = course
            showingNewCourseSheet = true
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                Text(course.room)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                Text(course.professor)
                    .font(.system(size: 10))
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(course.color)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                // 詳細画面をスキップして直接編集画面を表示
                newCourse = course
                showingNewCourseSheet = true
            }) {
                Label("編集", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                viewModel.deleteCourse(courseId: course.id)
            }) {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
