import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseCore
import Combine

// 評価項目スコア（5点満点）
enum EvaluationScore: Int, CaseIterable, Codable {
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
struct CourseEvaluation: Identifiable, Hashable, Codable {
    var id = UUID()
    var courseId: UUID
    var authorId: String = ""
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
            semester: "2022年後期",
            overallScore: .three, 
            difficultyScore: .five,
            assignmentsScore: .five,
            teachingScore: .three,
            gradingScore: .two,
            comment: "内容は面白かったですが、課題が難しすぎました。教授の説明も時々分かりにくかったです。"
        )
    ]
    
    // Firestore用のデータ変換メソッド
    func toFirestore() -> [String: Any] {
        return [
            "id": id.uuidString,
            "courseId": courseId.uuidString,
            "authorId": authorId,
            "authorName": authorName,
            "semester": semester,
            "overallScore": overallScore.rawValue,
            "difficultyScore": difficultyScore.rawValue,
            "assignmentsScore": assignmentsScore.rawValue, 
            "teachingScore": teachingScore.rawValue,
            "gradingScore": gradingScore.rawValue,
            "comment": comment,
            "date": Timestamp(date: date),
            "likes": likes,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
    
    // Firestore 文書からインスタンスを作成
    static func fromFirestore(_ document: DocumentSnapshot) -> CourseEvaluation? {
        guard let data = document.data() else { return nil }
        
        guard 
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let courseIdString = data["courseId"] as? String,
            let courseId = UUID(uuidString: courseIdString),
            let semester = data["semester"] as? String,
            let overallScoreRaw = data["overallScore"] as? Int,
            let difficultyScoreRaw = data["difficultyScore"] as? Int,
            let assignmentsScoreRaw = data["assignmentsScore"] as? Int,
            let teachingScoreRaw = data["teachingScore"] as? Int,
            let gradingScoreRaw = data["gradingScore"] as? Int,
            let comment = data["comment"] as? String
        else { return nil }
        
        // Optional fields
        let authorName = data["authorName"] as? String ?? "匿名"
        let authorId = data["authorId"] as? String ?? ""
        let likes = data["likes"] as? Int ?? 0
        var date = Date()
        if let timestamp = data["date"] as? Timestamp {
            date = timestamp.dateValue()
        }
        
        // Score conversion
        guard 
            let overallScore = EvaluationScore(rawValue: overallScoreRaw),
            let difficultyScore = EvaluationScore(rawValue: difficultyScoreRaw),
            let assignmentsScore = EvaluationScore(rawValue: assignmentsScoreRaw),
            let teachingScore = EvaluationScore(rawValue: teachingScoreRaw),
            let gradingScore = EvaluationScore(rawValue: gradingScoreRaw)
        else { return nil }
        
        return CourseEvaluation(
            id: id,
            courseId: courseId,
            authorId: authorId,
            authorName: authorName,
            semester: semester,
            overallScore: overallScore,
            difficultyScore: difficultyScore,
            assignmentsScore: assignmentsScore,
            teachingScore: teachingScore,
            gradingScore: gradingScore,
            comment: comment,
            date: date,
            likes: likes
        )
    }
}

// 授業モデル（FirestoreとのCRUD操作を含む）
class CourseEvaluationViewModel: ObservableObject {
    @Published var evaluations: [CourseEvaluation] = []
    @Published var courseEvaluationsMap: [UUID: [CourseEvaluation]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = FirebaseManager.shared.getFirestore()
    private var listeners: [ListenerRegistration] = []
    
    init() {
        loadSampleData()  // 開発段階ではサンプルデータを使う
    }
    
    deinit {
        removeAllListeners()
    }
    
    private func loadSampleData() {
        evaluations = CourseEvaluation.samples
        
        // コースIDごとの評価をマッピング
        for evaluation in CourseEvaluation.samples {
            if var courseEvals = courseEvaluationsMap[evaluation.courseId] {
                courseEvals.append(evaluation)
                courseEvaluationsMap[evaluation.courseId] = courseEvals
            } else {
                courseEvaluationsMap[evaluation.courseId] = [evaluation]
            }
        }
    }
    
    // 全ての授業評価を取得
    func fetchAllEvaluations() {
        isLoading = true
        errorMessage = nil
        
        db.collection("courseEvaluations")
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "評価の取得に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    self.evaluations = []
                    self.courseEvaluationsMap = [:]
                    
                    guard let documents = snapshot?.documents else {
                        return
                    }
                    
                    for document in documents {
                        if let evaluation = CourseEvaluation.fromFirestore(document) {
                            self.evaluations.append(evaluation)
                            
                            // コースIDごとのマッピングを更新
                            if var courseEvals = self.courseEvaluationsMap[evaluation.courseId] {
                                courseEvals.append(evaluation)
                                self.courseEvaluationsMap[evaluation.courseId] = courseEvals
                            } else {
                                self.courseEvaluationsMap[evaluation.courseId] = [evaluation]
                            }
                        }
                    }
                }
            }
    }
    
    // 特定のコースの評価を取得
    func fetchEvaluationsForCourse(courseId: UUID) {
        isLoading = true
        errorMessage = nil
        
        db.collection("courseEvaluations")
            .whereField("courseId", isEqualTo: courseId.uuidString)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "評価の取得に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    var courseEvals: [CourseEvaluation] = []
                    
                    guard let documents = snapshot?.documents else {
                        self.courseEvaluationsMap[courseId] = []
                        return
                    }
                    
                    for document in documents {
                        if let evaluation = CourseEvaluation.fromFirestore(document) {
                            courseEvals.append(evaluation)
                        }
                    }
                    
                    self.courseEvaluationsMap[courseId] = courseEvals
                }
            }
    }
    
    // リアルタイムでコースの評価をリッスンする
    func listenToEvaluationsForCourse(courseId: UUID) {
        // 既存のリスナーを削除
        removeListenerForCourse(courseId: courseId)
        
        let listener = db.collection("courseEvaluations")
            .whereField("courseId", isEqualTo: courseId.uuidString)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "評価の監視中にエラーが発生しました: \(error.localizedDescription)"
                    }
                    return
                }
                
                var courseEvals: [CourseEvaluation] = []
                
                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.courseEvaluationsMap[courseId] = []
                    }
                    return
                }
                
                for document in documents {
                    if let evaluation = CourseEvaluation.fromFirestore(document) {
                        courseEvals.append(evaluation)
                    }
                }
                
                DispatchQueue.main.async {
                    self.courseEvaluationsMap[courseId] = courseEvals
                }
            }
        
        listeners.append(listener)
    }
    
    // 評価を追加
    func addEvaluation(_ evaluation: CourseEvaluation) {
        isLoading = true
        errorMessage = nil
        
        let evaluationData = evaluation.toFirestore()
        
        db.collection("courseEvaluations")
            .document(evaluation.id.uuidString)
            .setData(evaluationData) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "評価の保存に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    // 新しい評価を追加
                    self.evaluations.append(evaluation)
                    
                    // コースIDごとのマッピングを更新
                    if var courseEvals = self.courseEvaluationsMap[evaluation.courseId] {
                        courseEvals.append(evaluation)
                        self.courseEvaluationsMap[evaluation.courseId] = courseEvals
                    } else {
                        self.courseEvaluationsMap[evaluation.courseId] = [evaluation]
                    }
                }
            }
    }
    
    // 「いいね」を更新
    func updateLikes(for evaluationId: UUID, courseId: UUID, increment: Bool) {
        let evaluationRef = db.collection("courseEvaluations").document(evaluationId.uuidString)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(evaluationRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let likes = document.data()?["likes"] as? Int else {
                return nil
            }
            
            // いいねを増減
            let newLikes = increment ? likes + 1 : max(0, likes - 1)
            transaction.updateData(["likes": newLikes], forDocument: evaluationRef)
            
            return newLikes
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "いいねの更新に失敗しました: \(error.localizedDescription)"
                }
                return
            }
            
            if let newLikes = result as? Int {
                DispatchQueue.main.async {
                    // メモリ上のデータも更新
                    if var evaluations = self.courseEvaluationsMap[courseId] {
                        if let index = evaluations.firstIndex(where: { $0.id == evaluationId }) {
                            evaluations[index].likes = newLikes
                            self.courseEvaluationsMap[courseId] = evaluations
                        }
                    }
                    
                    if let index = self.evaluations.firstIndex(where: { $0.id == evaluationId }) {
                        self.evaluations[index].likes = newLikes
                    }
                }
            }
        }
    }
    
    // コース別の評価を取得
    func evaluationsForCourse(_ courseId: UUID) -> [CourseEvaluation] {
        return courseEvaluationsMap[courseId] ?? []
    }
    
    // コースの平均スコアを計算
    func averageScoreForCourse(_ courseId: UUID) -> Double {
        let evaluations = evaluationsForCourse(courseId)
        guard !evaluations.isEmpty else { return 0.0 }
        
        let totalScore = evaluations.reduce(0) { $0 + $1.overallScore.rawValue }
        return Double(totalScore) / Double(evaluations.count)
    }
    
    // 評価にいいねを追加/削除
    func likeEvaluation(_ evaluationId: UUID) {
        // 評価を見つけて likes を更新
        if let courseId = findCourseIdForEvaluation(evaluationId) {
            updateLikes(for: evaluationId, courseId: courseId, increment: true)
        }
    }
    
    // 評価のコースIDを検索
    private func findCourseIdForEvaluation(_ evaluationId: UUID) -> UUID? {
        for (courseId, evaluations) in courseEvaluationsMap {
            if evaluations.contains(where: { $0.id == evaluationId }) {
                return courseId
            }
        }
        return nil
    }

    // リスナーを削除
    private func removeListenerForCourse(courseId: UUID) {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    private func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}
