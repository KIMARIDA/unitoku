// filepath: /Users/junnykim/unitoku/CourseEvaluationModels.swift
import Foundation
import SwiftUI

// 評価項目スコア（5点満点）
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
    case grading = "成績比率"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .overall: return "授業に対する全般的な満足度"
        case .difficulty: return "講義内容の難易度"
        case .assignments: return "課題の量と質"
        case .teaching: return "教授の講義伝達力"
        case .grading: return "成績分布の公平性"
        }
    }
}

// 授業評価モデル
struct CourseEvaluation: Identifiable, Hashable {
    var id = UUID()
    var courseId: UUID
    var authorName: String = "匿名" // デフォルトは匿名
    var semester: String // 例："2023年前期"
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
            semester: "2023年前期",
            overallScore: .four,
            difficultyScore: .three,
            assignmentsScore: .four,
            teachingScore: .five,
            gradingScore: .three,
            comment: "講義内容がとても有益でした。実習時間が十分あって良かったです。教授の説明が明確でした。課題は適切でしたが、最後のプロジェクトは少し難しかったです。"
        ),
        CourseEvaluation(
            courseId: Course.samples[1].id,
            semester: "2023年後期",
            overallScore: .five,
            difficultyScore: .four,
            assignmentsScore: .three,
            teachingScore: .five,
            gradingScore: .four,
            comment: "データ構造について深い理解を得ることができました。教授が実際の事例をたくさん挙げてくれたのが良かったです。"
        ),
        CourseEvaluation(
            courseId: Course.samples[2].id,
            semester: "2023年前期",
            overallScore: .three,
            difficultyScore: .five,
            assignmentsScore: .four,
            teachingScore: .three,
            gradingScore: .four,
            comment: "内容は面白かったですが、難しすぎる部分もありました。もう少し基礎的な内容の説明があればよかったです。"
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
    
    // 新しい評価を追加
    func addEvaluation(_ evaluation: CourseEvaluation) {
        evaluations.append(evaluation)
    }
    
    // 評価のいいねを増加
    func likeEvaluation(_ evaluationId: UUID) {
        if let index = evaluations.firstIndex(where: { $0.id == evaluationId }) {
            evaluations[index].likes += 1
        }
    }
    
    // コースごとの平均評価
    func averageScoreForCourse(_ courseId: UUID) -> Double? {
        let courseEvaluations = evaluationsForCourse(courseId)
        if courseEvaluations.isEmpty {
            return nil
        }
        
        let sum = courseEvaluations.reduce(0) { $0 + $1.averageScore }
        return sum / Double(courseEvaluations.count)
    }
}

// TimeTableModels.swiftのCourseモデル拡張
extension Course {
    // 該当授業の評価を取得するメソッド
    func evaluations(viewModel: CourseEvaluationViewModel) -> [CourseEvaluation] {
        return viewModel.evaluationsForCourse(id)
    }
    
    // 平均評価
    func averageRating(viewModel: CourseEvaluationViewModel) -> Double? {
        return viewModel.averageScoreForCourse(id)
    }
}
