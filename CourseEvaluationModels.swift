// filepath: /Users/junnykim/unitoku/CourseEvaluationModels.swift
import Foundation
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

// TimeTableModels.swift의 Course 모델 확장
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
