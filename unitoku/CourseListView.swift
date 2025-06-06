import SwiftUI

// 授業一覧画面
struct CourseListView: View {
    @ObservedObject var viewModel: TimeTableViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedFilter: CourseFilter = .all
    @State private var showingNewCourseSheet = false
    @State private var showingCourseDetail: Course? = nil
    @State private var newCourse = Course(name: "", professor: "", room: "", weekday: .monday, period: .first, color: .blue)
    
    // フィルター選択肢
    enum CourseFilter: String, CaseIterable {
        case all = "全て"
        case monday = "月曜日"
        case tuesday = "火曜日"
        case wednesday = "水曜日"
        case thursday = "木曜日"
        case friday = "金曜日"
        
        var weekday: Weekday? {
            switch self {
            case .all: return nil
            case .monday: return .monday
            case .tuesday: return .tuesday
            case .wednesday: return .wednesday
            case .thursday: return .thursday
            case .friday: return .friday
            }
        }
    }
    
    // フィルタリングされた授業リスト
    var filteredCourses: [Course] {
        var courses = viewModel.courses
        
        // 曜日フィルター
        if let weekday = selectedFilter.weekday {
            courses = courses.filter { $0.weekday == weekday }
        }
        
        // 検索フィルター
        if !searchText.isEmpty {
            courses = courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) ||
                course.professor.localizedCaseInsensitiveContains(searchText) ||
                course.room.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return courses.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                searchBar
                
                // フィルターピッカー
                filterPicker
                
                // 授業リスト
                if filteredCourses.isEmpty {
                    emptyStateView
                } else {
                    courseList
                }
            }
            .navigationTitle("授業一覧")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewCourseSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewCourseSheet) {
                CourseFormView(course: $newCourse, viewModel: viewModel, isEditing: false) { success in
                    if success {
                        showingNewCourseSheet = false
                        // 新しいコースを作成
                        newCourse = Course(name: "", professor: "", room: "", weekday: .monday, period: .first, color: viewModel.randomColor())
                    }
                }
            }
            .sheet(item: $showingCourseDetail) { course in
                CourseDetailView(course: course, viewModel: viewModel)
            }
        }
    }
    
    // 検索バー
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("授業名、教授名、教室で検索", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
    }
    
    // フィルターピッカー
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CourseFilter.allCases, id: \.rawValue) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.appTheme : Color(.systemGray6))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    // 授業リスト
    private var courseList: some View {
        List {
            Section {
                ForEach(filteredCourses) { course in
                    CourseListRow(course: course) {
                        showingCourseDetail = course
                    }
                }
                .onDelete(perform: deleteCourses)
            } header: {
                HStack {
                    Text("登録授業")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(filteredCourses.count)件")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // 空状態ビュー
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? "授業が登録されていません" : "検索結果が見つかりません")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? "新しい授業を追加してみましょう" : "別のキーワードで検索してみてください")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                Button(action: {
                    showingNewCourseSheet = true
                }) {
                    Text("授業を追加")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.appTheme)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // 授業削除
    private func deleteCourses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let course = filteredCourses[index]
                viewModel.deleteCourse(course)
            }
        }
    }
}

// 授業リスト行コンポーネント
struct CourseListRow: View {
    let course: Course
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 色サークル
                Circle()
                    .fill(course.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(course.name.prefix(1)))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // 授業情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(course.professor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(course.room, systemImage: "location")
                        
                        Label("\(course.weekday.rawValue) \(course.period.rawValue)限", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 矢印アイコン
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 授業統計ビュー
struct CourseStatsView: View {
    let viewModel: TimeTableViewModel
    
    var weekdayStats: [(Weekday, Int)] {
        let stats = Dictionary(grouping: viewModel.courses, by: \.weekday)
            .mapValues { $0.count }
        
        return Weekday.allCases.map { weekday in
            (weekday, stats[weekday] ?? 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("曜日別授業数")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(weekdayStats, id: \.0) { weekday, count in
                    VStack(spacing: 8) {
                        Text(weekday.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(count > 0 ? Color.appTheme : .gray)
                        
                        Text("授業")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    CourseListView(viewModel: TimeTableViewModel())
}
