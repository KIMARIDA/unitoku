import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
            
            TimeTableView()
                .tabItem {
                    Label("時間割", systemImage: "calendar")
                }
            
            CourseReviewView()
                .tabItem {
                    Label("授業評価", systemImage: "star")
                }
            
            ChatView()
                .tabItem {
                    Label("チャット", systemImage: "message")
                }
            
            MoreView()
                .tabItem {
                    Label("もっと", systemImage: "ellipsis.circle")
                }
        }
        .accentColor(Color.appTheme)
    }
}

// 時間割ビュー
struct TimeTableView: View {
    @State private var courses = Course.samples
    @State private var showingCourseDetail: Course? = nil
    @State private var showingNewCourseSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 時間割表示
                ScrollView {
                    timeTableContent
                }
                .navigationTitle("時間割") // 대학교 이름과 시간표 함께 표시
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        addButton
                    }
                }
                .sheet(item: $showingCourseDetail) { course in
                    CourseDetailView(course: course)
                }
                .sheet(isPresented: $showingNewCourseSheet) {
                    Text("新しい授業を登録")
                        .font(.headline)
                        .padding()
                }
            }
        }
    }
    
    // 時間割コンテンツ
    private var timeTableContent: some View {
        VStack(spacing: 0) {
            // ヘッダー行（曜日）
            weekdayHeaderRow
            
            // 各時限行
            ForEach(Period.allCases) { period in
                periodRow(period: period)
            }
        }
    }
    
    // 曜日ヘッダー行
    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            // 時限列
            Text("時限")
                .font(.caption)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.systemBackground))
            
            // 曜日列
            ForEach(Weekday.allCases) { weekday in
                Text(weekday.rawValue)
                    .font(.headline)
                    .background(Color(UIColor.systemBackground))
            }
        }
        .background(Color(.systemGray5))
    }
    
    // 時限の行
    private func periodRow(period: Period) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 時限表示
                periodCell(period: period)
                
                // 各曜日のセル
                ForEach(Weekday.allCases) { weekday in
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
                .font(.caption)
            Text(period.timeRange)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(width: 40, height: 80)
        .background(Color(UIColor.systemBackground))
    }
    
    // 追加ボタン
    private var addButton: some View {
        Button(action: {
            showingNewCourseSheet = true
        }) {
            Image(systemName: "plus")
        }
    }
    
    // 特定の曜日・時限のセルを生成
    @ViewBuilder
    private func courseCell(for weekday: Weekday, at period: Period) -> some View {
        let coursesForCell = courses.filter { $0.weekday == weekday && $0.period == period }
        
        if let course = coursesForCell.first {
            courseCellContent(course: course)
        } else {
            emptyCourseCell()
        }
    }
    
    // 授業があるセルの内容
    private func courseCellContent(course: Course) -> some View {
        Button(action: {
            showingCourseDetail = course
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.white)
                
                Text(course.room)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 80)
            .padding(4)
            .background(course.color)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 空のセル
    private func emptyCourseCell() -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 80)
            .background(Color(UIColor.systemBackground))
            .onTapGesture {
                // 空きセルをタップ時の処理も可能
            }
    }
}

// 授業詳細ビュー
struct CourseDetailView: View {
    let course: Course
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("授業情報")) {
                    HStack {
                        Text("授業名")
                        Spacer()
                        Text(course.name)
                    }
                    
                    HStack {
                        Text("教授")
                        Spacer()
                        Text(course.professor)
                    }
                    
                    HStack {
                        Text("教室")
                        Spacer()
                        Text(course.room)
                    }
                    
                    HStack {
                        Text("曜日・時限")
                        Spacer()
                        Text("\(course.weekday.rawValue)曜 \(course.period.rawValue)限")
                    }
                    
                    HStack {
                        Text("時間")
                        Spacer()
                        Text(course.period.timeRange)
                    }
                }
            }
            .navigationTitle("授業詳細")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 授業評価ビュー
struct CourseReviewView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "star")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appTheme)
                
                Text("授業の評価を確認することができます")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(icon: "magnifyingglass", text: "授業の検索と評価確認")
                    FeatureRow(icon: "pencil.and.outline", text: "レビューを書く")
                    FeatureRow(icon: "chart.bar", text: "授業別の評価と統計")
                    FeatureRow(icon: "doc.text", text: "試験情報と課題量の確認")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("授業評価")
            .padding(.top)
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }
}

// チャットビュー
struct ChatView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appTheme)
                
                Text("学科、学年、サークル別でチャットを始めましょう")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(icon: "person.3", text: "グループチャットルーム作成")
                    FeatureRow(icon: "person", text: "1:1メッセージを送る")
                    FeatureRow(icon: "building.2", text: "学科別チャットルーム")
                    FeatureRow(icon: "heart.circle", text: "趣味別チャットグループ")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("チャット")
            .padding(.top)
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }
}

// もっとビュー
struct MoreView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        FeatureRow(icon: "fork.knife", text: "学食情報")
                    }
                    
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        FeatureRow(icon: "bus", text: "シャトルバス時間表")
                    }
                    
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        FeatureRow(icon: "books.vertical", text: "図書館の座席状況")
                    }
                    
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        FeatureRow(icon: "cart", text: "フリーマーケット掲示板")
                    }
                    
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        FeatureRow(icon: "newspaper", text: "課外活動情報")
                    }
                }
                
                Section {
                    NavigationLink(destination: ProfileView()) {
                        FeatureRow(icon: "person.circle", text: "プロフィール設定")
                    }
                    
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        FeatureRow(icon: "gear", text: "アプリ設定")
                    }
                    
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        FeatureRow(icon: "questionmark.circle", text: "お問い合わせ")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("もっと")
        }
    }
}

// 기능 행 컴포넌트
struct FeatureRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(Color.appTheme)
                .frame(width: 25)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
