// filepath: /Users/junnykim/unitoku/unitoku/CourseReviewView.swift
import SwiftUI

// 評価項目スコア (5点満点)
enum EvaluationScore: Int, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    
    var icon: String {
        switch self {
        case .one: return "star"
        case .two: return "star"
        case .three: return "star"
        case .four: return "star"
        case .five: return "star"
        }
    }
    
    var color: Color {
        switch self {
        case .one: return .red
        case .two: return .orange
        case .three: return .yellow
        case .four: return .mint
        case .five: return .green
        }
    }
}

// 評価項目タイプ
enum EvaluationCategory: String, CaseIterable, Identifiable {
    case overall = "全体評価"
    case difficulty = "難易度"
    case assignments = "課題量"
    case teaching = "講義力"
    case grading = "GPA割合"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .overall: return "講義に対する満足度"
        case .difficulty: return "講義内容の難易度"
        case .assignments: return "課題の量と質"
        case .teaching: return "教授の講義伝達力"
        case .grading: return "成績分布の公平性"
        }
    }
}

// 講義評価モデル
struct CourseEvaluation: Identifiable, Hashable {
    var id = UUID()
    var courseId: UUID
    var authorName: String = "匿名" // Default to anonymous
    var semester: String // e.g., "2023년 1학기"
    var overallScore: EvaluationScore
    var difficultyScore: EvaluationScore
    var assignmentsScore: EvaluationScore
    var teachingScore: EvaluationScore
    var gradingScore: EvaluationScore
    var comment: String
    var date: Date = Date()
    var likes: Int = 0
    
    // 平均スコア計算
    var averageScore: Double {
        let total = overallScore.rawValue + difficultyScore.rawValue +
                    assignmentsScore.rawValue + teachingScore.rawValue + gradingScore.rawValue
        return Double(total) / 5.0
    }
    
    // サンプルデータ
    static let samples: [CourseEvaluation] = [
        CourseEvaluation(
            courseId: Course.samples[0].id,
            semester: "2023年 1学期",
            overallScore: .four,
            difficultyScore: .three,
            assignmentsScore: .four,
            teachingScore: .five,
            gradingScore: .three,
            comment: "講義内容がとても有益でした。実習時間が十分あって良かったです。教授の説明が明確でした。課題は適切でしたが、最後のプロジェクトは少し難しかったです。"
        ),
        CourseEvaluation(
            courseId: Course.samples[1].id,
            semester: "2023年 2学期",
            overallScore: .five,
            difficultyScore: .four,
            assignmentsScore: .three,
            teachingScore: .five,
            gradingScore: .four,
            comment: "データ構造について深い理解を得ることができました。教授が実際の事例をたくさん紹介してくださったので良かったです。"
        ),
        CourseEvaluation(
            courseId: Course.samples[2].id,
            semester: "2023年 1学期",
            overallScore: .three,
            difficultyScore: .five,
            assignmentsScore: .four,
            teachingScore: .three,
            gradingScore: .two,
            comment: "内容がとても難しく課題が多かったです。試験も厳しかったですが多くを学んだと思います。"
        )
    ]
}

// コースに対する評価管理ビューモデル
class CourseEvaluationViewModel: ObservableObject {
    @Published var evaluations: [CourseEvaluation] = CourseEvaluation.samples
    
    // 特定のコースに対する評価のみフィルタリング
    func evaluationsForCourse(_ courseId: UUID) -> [CourseEvaluation] {
        return evaluations.filter { $0.courseId == courseId }
    }
    
    // 新しい評価追加
    func addEvaluation(_ evaluation: CourseEvaluation) {
        evaluations.append(evaluation)
    }
    
    // 評価いいね増加
    func likeEvaluation(_ evaluationId: UUID) {
        if let index = evaluations.firstIndex(where: { $0.id == evaluationId }) {
            evaluations[index].likes += 1
        }
    }
    
    // コース別平均評価
    func averageScoreForCourse(_ courseId: UUID) -> Double? {
        let courseEvaluations = evaluationsForCourse(courseId)
        if courseEvaluations.isEmpty {
            return nil
        }
        
        let sum = courseEvaluations.reduce(0) { $0 + $1.averageScore }
        return sum / Double(courseEvaluations.count)
    }
}

// Course モデル拡張
extension Course {
    // 該当講義の評価を取得するメソッド
    func evaluations(viewModel: CourseEvaluationViewModel) -> [CourseEvaluation] {
        return viewModel.evaluationsForCourse(id)
    }
    
    // 平均評価
    func averageRating(viewModel: CourseEvaluationViewModel) -> Double? {
        return viewModel.averageScoreForCourse(id)
    }
}

// 講義評価メインビュー - 名前を CourseReviewView から DetailedCourseReviewView に変更
struct DetailedCourseReviewView: View {
    @StateObject private var viewModel = CourseEvaluationViewModel()
    @State private var showingAddEvaluation = false
    @State private var selectedCourse: Course?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                
                    // 最近評価された講義
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近の評価")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Course.samples) { course in
                                    Button(action: {
                                        selectedCourse = course
                                    }) {
                                        CourseReviewCard(course: course, viewModel: viewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // すべての講義リスト
                    VStack(alignment: .leading, spacing: 8) {
                        Text("全ての授業")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Course.samples) { course in
                                Button(action: {
                                    selectedCourse = course
                                }) {
                                    CourseGridCard(course: course, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("講義評価")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEvaluation = true
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(item: $selectedCourse) { course in
                CourseEvaluationDetailView(course: course, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddEvaluation) {
                NewEvaluationView(viewModel: viewModel)
            }
        }
    }
}

// 最近評価された講義カード
struct CourseReviewCard: View {
    let course: Course
    let viewModel: CourseEvaluationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(course.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
            }
            
            Text(course.professor)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            
            Spacer()
            
            HStack {
                if let rating = course.averageRating(viewModel: viewModel) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                        .foregroundColor(.white)
                } else {
                    Text("評価なし")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                

            }
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(course.color)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// すべての講義カード
struct CourseGridCard: View {
    let course: Course
    let viewModel: CourseEvaluationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(course.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(course.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            Text(course.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(course.professor)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack {
                if let rating = course.averageRating(viewModel: viewModel) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                } else {
                    Text("評価なし")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 講義 評価詳細画面
struct CourseEvaluationDetailView: View {
    let course: Course
    let viewModel: CourseEvaluationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddEvaluation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 講義情報ヘッダー
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(course.professor) · \(course.room)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(course.weekday.rawValue)曜日 \(course.period.timeRange)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        // 平均評価
                        if let rating = course.averageRating(viewModel: viewModel) {
                            HStack(spacing: 8) {
                                Text(String(format: "%.1f", rating))
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                                
                                Spacer()
                            } // Added missing closing bracket for HStack
                            
                            // 詳細項目評価
                            VStack(alignment: .leading, spacing: 12) {
                                ScoreBarView(category: .overall, score: averageScore(for: \.overallScore))
                                ScoreBarView(category: .difficulty, score: averageScore(for: \.difficultyScore))
                                ScoreBarView(category: .assignments, score: averageScore(for: \.assignmentsScore))
                                ScoreBarView(category: .teaching, score: averageScore(for: \.teachingScore))
                                ScoreBarView(category: .grading, score: averageScore(for: \.gradingScore))
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("まだ評価がありません")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                        
                        Divider()
                    }
                    .padding()
                    
                    // 評価リスト
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("講義評価")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddEvaluation = true
                            }) {
                                Label("評価作成", systemImage: "square.and.pencil")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.evaluationsForCourse(course.id).isEmpty {
                            Text("まだ作成された講義評価がありません")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.evaluationsForCourse(course.id)) { evaluation in
                                EvaluationCard(evaluation: evaluation, viewModel: viewModel)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("閉じる") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingAddEvaluation) {
                NewEvaluationView(viewModel: viewModel, courseId: course.id)
            }
        }
    }
    
    // 特定カテゴリの平均スコア計算ヘルパー関数
    private func averageScore<T>(for keyPath: KeyPath<CourseEvaluation, T>) -> Double where T: RawRepresentable, T.RawValue == Int {
        let evaluations = viewModel.evaluationsForCourse(course.id)
        if evaluations.isEmpty { return 0 }
        
        let sum = evaluations.reduce(0) { $0 + Double($1[keyPath: keyPath].rawValue) }
        return sum / Double(evaluations.count)
    }
}

// 評価スコアバーコンポーネント
struct ScoreBarView: View {
    let category: EvaluationCategory
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.rawValue)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.1f", score))
                    .font(.subheadline)
                    .foregroundColor(scoreColor(score: score))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.1)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(score) / 5.0 * geometry.size.width, geometry.size.width), height: 8)
                        .foregroundColor(scoreColor(score: score))
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            
            Text(category.description)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // スコアに応じた色
    private func scoreColor(score: Double) -> Color {
        switch score {
        case 0..<2: return .red
        case 2..<3: return .orange
        case 3..<4: return .yellow
        case 4...5: return .green
        default: return .gray
        }
    }
}

// 個別評価カード
struct EvaluationCard: View {
    let evaluation: CourseEvaluation
    let viewModel: CourseEvaluationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= evaluation.overallScore.rawValue ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Text(String(format: "%.1f", evaluation.averageScore))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(evaluation.semester)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(evaluation.comment)
                .font(.body)
                .lineLimit(5)
            
            HStack {
                Text(evaluation.authorName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(formatDate(evaluation.date))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    viewModel.likeEvaluation(evaluation.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                        Text("\(evaluation.likes)")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 日付フォーマット変換ヘルパー
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

// 新しい評価作成画面
struct NewEvaluationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CourseEvaluationViewModel
    
    // Optional courseId for pre-selected course
    var courseId: UUID?
    
    @State private var selectedCourse: Course?
    @State private var semester: String = "\(Calendar.current.component(.year, from: Date()))年 \(Calendar.current.component(.month, from: Date()) <= 6 ? "1" : "2")学期" // Default to current semester
    @State private var authorName: String = "匿名"
    @State private var comment: String = ""
    @State private var overallScore: EvaluationScore = .three
    @State private var difficultyScore: EvaluationScore = .three
    @State private var assignmentsScore: EvaluationScore = .three
    @State private var teachingScore: EvaluationScore = .three
    @State private var gradingScore: EvaluationScore = .three
    
    var body: some View {
        NavigationView {
            Form {
                // 講義選択 (事前選択された講義がない場合のみ)
                if courseId == nil {
                    Section(header: Text("講義選択")) {
                        Picker("講義", selection: $selectedCourse) {
                            Text("講義を選択してください").tag(nil as Course?)
                            ForEach(Course.samples) { course in
                                Text("\(course.name) (\(course.professor))").tag(course as Course?)
                            }
                        }
                    }
                }
                
                // 学期情報
                Section(header: Text("学期")) {
                    TextField("学期", text: $semester)
                }
                
                // 評点情報
                Section(header: Text("評価点数")) {
                    ScoreSelectionView(title: EvaluationCategory.overall.rawValue, description: EvaluationCategory.overall.description, score: $overallScore)
                    ScoreSelectionView(title: EvaluationCategory.difficulty.rawValue, description: EvaluationCategory.difficulty.description, score: $difficultyScore)
                    ScoreSelectionView(title: EvaluationCategory.assignments.rawValue, description: EvaluationCategory.assignments.description, score: $assignmentsScore)
                    ScoreSelectionView(title: EvaluationCategory.teaching.rawValue, description: EvaluationCategory.teaching.description, score: $teachingScore)
                    ScoreSelectionView(title: EvaluationCategory.grading.rawValue, description: EvaluationCategory.grading.description, score: $gradingScore)
                }
                
                // 評価コメント
                Section(header: Text("講義評価")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 150)
                }
                
                // 作成者情報
                Section(header: Text("作成者")) {
                    TextField("名前（匿名可能）", text: $authorName)
                }
            }
            .navigationTitle("講義評価作成")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("登録") {
                    submitEvaluation()
                }
                .disabled(!isFormValid)
            )
        }
        .onAppear {
            if let id = courseId {
                selectedCourse = Course.samples.first { $0.id == id }
            }
        }
    }
    
    // 入力フォームの有効性検証
    private var isFormValid: Bool {
        let courseSelected = courseId != nil || selectedCourse != nil
        let hasComment = !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return courseSelected && hasComment
    }
    
    // 評価提出
    private func submitEvaluation() {
        // courseIdが直接渡されたか、選択された講義が必要
        guard let course = courseId != nil ? Course.samples.first(where: { $0.id == courseId }) : selectedCourse else {
            return
        }
        
        let newEvaluation = CourseEvaluation(
            courseId: course.id,
            authorName: authorName,
            semester: semester,
            overallScore: overallScore,
            difficultyScore: difficultyScore,
            assignmentsScore: assignmentsScore,
            teachingScore: teachingScore,
            gradingScore: gradingScore,
            comment: comment,
            date: Date()
        )
        
        viewModel.addEvaluation(newEvaluation)
        presentationMode.wrappedValue.dismiss()
    }
}

// スコア選択コンポーネント
struct ScoreSelectionView: View {
    let title: String
    let description: String
    @Binding var score: EvaluationScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(score.rawValue)")
                    .font(.headline)
                    .foregroundColor(score.color)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                ForEach(EvaluationScore.allCases, id: \.rawValue) { value in
                    Image(systemName: value.rawValue <= score.rawValue ? "star.fill" : "star")
                        .foregroundColor(value.rawValue <= score.rawValue ? value.color : .gray)
                        .onTapGesture {
                            score = value
                        }
                }
            }
            .font(.title3)
            .padding(.vertical, 4)
        }
    }
}
