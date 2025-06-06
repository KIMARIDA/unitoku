import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
    @State private var editMode = false
    @State private var newCourse = Course(name: "", professor: "", room: "", weekday: .monday, period: .first, color: .blue)
    
    let weekdays = Weekday.allCases
    let periods = Period.allCases
    
    var body: some View {
        NavigationView {
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
                    addButton
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    editButton
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
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
        .background(Color(.systemGray5))
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
            // View all courses in a list
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
            .background(course.color)
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
                viewModel.deleteCourse(course)
            }) {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

// 授業詳細画面
struct CourseDetailView: View {
    let course: Course
    let viewModel: TimeTableViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var editingCourse: Course
    
    init(course: Course, viewModel: TimeTableViewModel) {
        self.course = course
        self.viewModel = viewModel
        self._editingCourse = State(initialValue: course)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("授業情報")) {
                    HStack {
                        Text("授業名")
                        Spacer()
                        Text(course.name)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("教授")
                        Spacer()
                        Text(course.professor)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("教室")
                        Spacer()
                        Text(course.room)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("時間")) {
                    HStack {
                        Text("曜日")
                        Spacer()
                        Text(course.weekday.rawValue + "曜日")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("時限")
                        Spacer()
                        Text("\(course.period.rawValue)限 (\(course.period.timeRange))")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(course.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Text("編集")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("閉じる")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                CourseFormView(course: $editingCourse, viewModel: viewModel, isEditing: true) { success in
                    if success {
                        viewModel.updateCourse(editingCourse)
                        showingEditSheet = false
                    }
                }
            }
        }
    }
}

// 授業作成・編集フォーム
struct CourseFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var course: Course
    let viewModel: TimeTableViewModel
    let isEditing: Bool
    let onSave: (Bool) -> Void
    
    @State private var name: String = ""
    @State private var professor: String = ""
    @State private var room: String = ""
    @State private var weekday: Weekday = .monday
    @State private var period: Period = .first
    @State private var color: Color = .blue
    
    init(course: Binding<Course>, viewModel: TimeTableViewModel, isEditing: Bool, onSave: @escaping (Bool) -> Void = {_ in}) {
        self._course = course
        self.viewModel = viewModel
        self.isEditing = isEditing
        self.onSave = onSave
        
        _name = State(initialValue: course.wrappedValue.name)
        _professor = State(initialValue: course.wrappedValue.professor)
        _room = State(initialValue: course.wrappedValue.room)
        _weekday = State(initialValue: course.wrappedValue.weekday)
        _period = State(initialValue: course.wrappedValue.period)
        _color = State(initialValue: course.wrappedValue.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("授業情報")) {
                    TextField("授業名", text: $name)
                    TextField("教授名", text: $professor)
                    TextField("教室", text: $room)
                }
                
                Section(header: Text("時間")) {
                    Picker("曜日", selection: $weekday) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.rawValue + "曜日").tag(day)
                        }
                    }
                    
                    Picker("時限", selection: $period) {
                        ForEach(Period.allCases) { period in
                            Text("\(period.rawValue)限 (\(period.timeRange))").tag(period)
                        }
                    }
                }
                
                Section(header: Text("色")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(Course.colors, id: \.self) { colorOption in
                            ZStack {
                                Circle()
                                    .fill(colorOption)
                                    .frame(width: 30, height: 30)
                                
                                if colorOption == color {
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 2)
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .onTapGesture {
                                color = colorOption
                            }
                            .padding(5)
                        }
                    }
                }
                
                if isEditing {
                    Section {
                        Button(action: {
                            viewModel.deleteCourse(course)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("授業を削除")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "授業を編集" : "新しい授業")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveCourse()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveCourse() {
        course.name = name
        course.professor = professor
        course.room = room
        course.weekday = weekday
        course.period = period
        course.color = color
        
        if !isEditing {
            viewModel.addCourse(course)
        }
        
        onSave(true)
        presentationMode.wrappedValue.dismiss()
    }
}

// 時間割データを管理するViewModel
class TimeTableViewModel: ObservableObject {
    @Published var courses: [Course] = Course.samples
    
    // 特定の曜日のコースを取得
    func coursesFor(weekday: Weekday) -> [Course] {
        return courses.filter { $0.weekday == weekday }
    }
    
    // 特定の曜日と時間帯のコースを取得
    func courseFor(weekday: Weekday, period: Period) -> Course? {
        return courses.first { $0.weekday == weekday && $0.period == period }
    }
    
    // コースの追加
    func addCourse(_ course: Course) {
        courses.append(course)
    }
    
    // コースの削除
    func deleteCourse(_ course: Course) {
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses.remove(at: index)
        }
    }
    
    // コースの更新
    func updateCourse(_ course: Course) {
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses[index] = course
        }
    }
    
    // ランダムな色を生成
    func randomColor() -> Color {
        Course.colors.randomElement() ?? .blue
    }
}

// プレースホルダービュー - DetailedCourseReviewViewはCourseReviewView.swiftに実装済み

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
