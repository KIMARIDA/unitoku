// filepath: /Users/junnykim/unitoku/unitoku/CourseReviewView.swift
import SwiftUI

// 평가 항목 점수 (5점 만점)
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

// 평가 항목 유형
enum EvaluationCategory: String, CaseIterable, Identifiable {
    case overall = "전체 평가"
    case difficulty = "난이도"
    case assignments = "과제량"
    case teaching = "강의력"
    case grading = "학점 비율"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .overall: return "강의에 대한 전반적인 만족도"
        case .difficulty: return "강의 내용의 난이도"
        case .assignments: return "과제의 양과 질"
        case .teaching: return "교수님의 강의 전달력"
        case .grading: return "학점 분포의 공정성"
        }
    }
}

// 강의평가 모델
struct CourseEvaluation: Identifiable, Hashable {
    var id = UUID()
    var courseId: UUID
    var authorName: String = "익명" // Default to anonymous
    var semester: String // e.g., "2023년 1학기"
    var overallScore: EvaluationScore
    var difficultyScore: EvaluationScore
    var assignmentsScore: EvaluationScore
    var teachingScore: EvaluationScore
    var gradingScore: EvaluationScore
    var comment: String
    var date: Date = Date()
    var likes: Int = 0
    
    // 평균 점수 계산
    var averageScore: Double {
        let total = overallScore.rawValue + difficultyScore.rawValue +
                    assignmentsScore.rawValue + teachingScore.rawValue + gradingScore.rawValue
        return Double(total) / 5.0
    }
    
    // 샘플 데이터
    static let samples: [CourseEvaluation] = [
        CourseEvaluation(
            courseId: Course.samples[0].id,
            semester: "2023년 1학기",
            overallScore: .four,
            difficultyScore: .three,
            assignmentsScore: .four,
            teachingScore: .five,
            gradingScore: .three,
            comment: "강의 내용이 매우 유익했습니다. 실습 시간이 충분해서 좋았고, 교수님의 설명이 명확했습니다. 과제는 적당했지만 마지막 프로젝트는 조금 어려웠습니다."
        ),
        CourseEvaluation(
            courseId: Course.samples[1].id,
            semester: "2023년 2학기",
            overallScore: .five,
            difficultyScore: .four,
            assignmentsScore: .three,
            teachingScore: .five,
            gradingScore: .four,
            comment: "데이터 구조에 대한 깊은 이해를 얻을 수 있었습니다. 교수님이 실제 사례를 많이 들어주셔서 좋았습니다."
        ),
        CourseEvaluation(
            courseId: Course.samples[2].id,
            semester: "2023년 1학기",
            overallScore: .three,
            difficultyScore: .five,
            assignmentsScore: .four,
            teachingScore: .three,
            gradingScore: .two,
            comment: "내용이 너무 어렵고 과제가 많았습니다. 시험도 까다로웠지만 많이 배운 것 같습니다."
        )
    ]
}

// 코스에 대한 평가 관리 뷰모델
class CourseEvaluationViewModel: ObservableObject {
    @Published var evaluations: [CourseEvaluation] = CourseEvaluation.samples
    
    // 특정 코스에 대한 평가만 필터링
    func evaluationsForCourse(_ courseId: UUID) -> [CourseEvaluation] {
        return evaluations.filter { $0.courseId == courseId }
    }
    
    // 새 평가 추가
    func addEvaluation(_ evaluation: CourseEvaluation) {
        evaluations.append(evaluation)
    }
    
    // 평가 좋아요 증가
    func likeEvaluation(_ evaluationId: UUID) {
        if let index = evaluations.firstIndex(where: { $0.id == evaluationId }) {
            evaluations[index].likes += 1
        }
    }
    
    // 코스별 평균 평점
    func averageScoreForCourse(_ courseId: UUID) -> Double? {
        let courseEvaluations = evaluationsForCourse(courseId)
        if courseEvaluations.isEmpty {
            return nil
        }
        
        let sum = courseEvaluations.reduce(0) { $0 + $1.averageScore }
        return sum / Double(courseEvaluations.count)
    }
}

// Course 모델 확장
extension Course {
    // 해당 강의의 평가를 가져오는 메서드
    func evaluations(viewModel: CourseEvaluationViewModel) -> [CourseEvaluation] {
        return viewModel.evaluationsForCourse(id)
    }
    
    // 평균 평점
    func averageRating(viewModel: CourseEvaluationViewModel) -> Double? {
        return viewModel.averageScoreForCourse(id)
    }
}

// 강의평가 메인 뷰 - 이름을 CourseReviewView에서 DetailedCourseReviewView로 변경
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
                    Text("수강 강의 평가")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // 최근 평가된 강의
                    VStack(alignment: .leading, spacing: 8) {
                        Text("최근 평가")
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
                    
                    // 모든 강의 목록
                    VStack(alignment: .leading, spacing: 8) {
                        Text("전체 강의")
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
            .navigationTitle("강의평가")
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

// 최근 평가된 강의 카드
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
                    Text("평가 없음")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text("\(viewModel.evaluationsForCourse(course.id).count)개 평가")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(course.color)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// 모든 강의 카드
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
                    Text("평가 없음")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("\(viewModel.evaluationsForCourse(course.id).count)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// 강의 평가 상세 화면
struct CourseEvaluationDetailView: View {
    let course: Course
    let viewModel: CourseEvaluationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddEvaluation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 강의 정보 헤더
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(course.professor) · \(course.room)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(course.weekday.rawValue)요일 \(course.period.timeRange)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        // 평균 평점
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
                                
                                Text("\(viewModel.evaluationsForCourse(course.id).count)개 평가")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // 세부 항목 평점
                            VStack(alignment: .leading, spacing: 12) {
                                ScoreBarView(category: .overall, score: averageScore(for: \.overallScore))
                                ScoreBarView(category: .difficulty, score: averageScore(for: \.difficultyScore))
                                ScoreBarView(category: .assignments, score: averageScore(for: \.assignmentsScore))
                                ScoreBarView(category: .teaching, score: averageScore(for: \.teachingScore))
                                ScoreBarView(category: .grading, score: averageScore(for: \.gradingScore))
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("아직 평가가 없습니다")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                        
                        Divider()
                    }
                    .padding()
                    
                    // 평가 목록
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("강의평")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAddEvaluation = true
                            }) {
                                Label("평가 작성", systemImage: "square.and.pencil")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.evaluationsForCourse(course.id).isEmpty {
                            Text("아직 작성된 강의평이 없습니다")
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
                leading: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingAddEvaluation) {
                NewEvaluationView(viewModel: viewModel, courseId: course.id)
            }
        }
    }
    
    // 특정 카테고리의 평균 점수 계산 헬퍼 함수
    private func averageScore<T>(for keyPath: KeyPath<CourseEvaluation, T>) -> Double where T: RawRepresentable, T.RawValue == Int {
        let evaluations = viewModel.evaluationsForCourse(course.id)
        if evaluations.isEmpty { return 0 }
        
        let sum = evaluations.reduce(0) { $0 + Double($1[keyPath: keyPath].rawValue) }
        return sum / Double(evaluations.count)
    }
}

// 평가 점수 바 컴포넌트
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
    
    // 점수에 따른 색상
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

// 개별 평가 카드
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
    
    // 날짜 포맷 변환 헬퍼
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

// 새 평가 작성 화면
struct NewEvaluationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: CourseEvaluationViewModel
    
    // Optional courseId for pre-selected course
    var courseId: UUID?
    
    @State private var selectedCourse: Course?
    @State private var semester: String = "\(Calendar.current.component(.year, from: Date()))년 \(Calendar.current.component(.month, from: Date()) <= 6 ? "1" : "2")학기" // Default to current semester
    @State private var authorName: String = "익명"
    @State private var comment: String = ""
    @State private var overallScore: EvaluationScore = .three
    @State private var difficultyScore: EvaluationScore = .three
    @State private var assignmentsScore: EvaluationScore = .three
    @State private var teachingScore: EvaluationScore = .three
    @State private var gradingScore: EvaluationScore = .three
    
    var body: some View {
        NavigationView {
            Form {
                // 강의 선택 (사전 선택된 강의가 없을 경우에만)
                if courseId == nil {
                    Section(header: Text("강의 선택")) {
                        Picker("강의", selection: $selectedCourse) {
                            Text("강의를 선택하세요").tag(nil as Course?)
                            ForEach(Course.samples) { course in
                                Text("\(course.name) (\(course.professor))").tag(course as Course?)
                            }
                        }
                    }
                }
                
                // 학기 정보
                Section(header: Text("학기")) {
                    TextField("학기", text: $semester)
                }
                
                // 평점 정보
                Section(header: Text("평가 점수")) {
                    ScoreSelectionView(title: EvaluationCategory.overall.rawValue, description: EvaluationCategory.overall.description, score: $overallScore)
                    ScoreSelectionView(title: EvaluationCategory.difficulty.rawValue, description: EvaluationCategory.difficulty.description, score: $difficultyScore)
                    ScoreSelectionView(title: EvaluationCategory.assignments.rawValue, description: EvaluationCategory.assignments.description, score: $assignmentsScore)
                    ScoreSelectionView(title: EvaluationCategory.teaching.rawValue, description: EvaluationCategory.teaching.description, score: $teachingScore)
                    ScoreSelectionView(title: EvaluationCategory.grading.rawValue, description: EvaluationCategory.grading.description, score: $gradingScore)
                }
                
                // 평가 코멘트
                Section(header: Text("강의평")) {
                    TextEditor(text: $comment)
                        .frame(minHeight: 150)
                }
                
                // 작성자 정보
                Section(header: Text("작성자")) {
                    TextField("이름 (익명 가능)", text: $authorName)
                }
            }
            .navigationTitle("강의평가 작성")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("등록") {
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
    
    // 입력 폼 유효성 검증
    private var isFormValid: Bool {
        let courseSelected = courseId != nil || selectedCourse != nil
        let hasComment = !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return courseSelected && hasComment
    }
    
    // 평가 제출
    private func submitEvaluation() {
        // courseId가 직접 전달됐거나 선택된 강의가 있어야 함
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

// 점수 선택 컴포넌트
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
