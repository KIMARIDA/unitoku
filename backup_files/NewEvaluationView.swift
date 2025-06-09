// filepath: /Users/junnykim/unitoku/NewEvaluationView.swift
import SwiftUI

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
        guard let course = courseId != nil ? Course.samples.first { $0.id == courseId } : selectedCourse else {
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
