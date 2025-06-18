import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseCore

// 曜日の列挙型
enum Weekday: String, CaseIterable, Identifiable, Codable {
    case monday = "月"
    case tuesday = "火"
    case wednesday = "水"
    case thursday = "木"
    case friday = "金"
    
    var id: String { self.rawValue }
    
    // 日付から曜日を取得するための静的メソッド
    static func fromDate(_ date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Calendar.currentでは日曜日が1、土曜日が7
        switch weekday {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .monday // 土日の場合はデフォルトで月曜日
        }
    }
    
    // 完全な曜日名を返す
    var fullName: String {
        switch self {
        case .monday: return "月曜日"
        case .tuesday: return "火曜日"
        case .wednesday: return "水曜日"
        case .thursday: return "木曜日"
        case .friday: return "金曜日"
        }
    }
    
    // 短い曜日名を返す
    var shortName: String {
        return self.rawValue
    }
}

// 時間帯の列挙型
enum Period: Int, CaseIterable, Identifiable, Codable {
    case first = 1
    case second = 2
    case third = 3
    case fourth = 4
    case fifth = 5
    case sixth = 6
    
    var id: Int { self.rawValue }
    
    // 時間の文字列表現（例: "9:00-10:30"）
    var timeRange: String {
        switch self {
        case .first: return "8:50-10:20"
        case .second: return "10:40-12:10"
        case .third: return "13:00-14:30"
        case .fourth: return "14:50-16:20"
        case .fifth: return "16:40-18:10"
        case .sixth: return "18:30-20:00"
        }
    }
}

// 授業のモデル
struct Course: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var professor: String
    var room: String
    var weekday: Weekday
    var period: Period
    var colorIndex: Int = 0
    var userId: String = ""
    var semester: String = ""
    
    // 色は保存しない（非準拠型）
    var color: Color {
        return Course.colors[colorIndex % Course.colors.count]
    }
    
    // 色のオプション - パステルカラー
    static let colors: [Color] = [
        .blue.opacity(0.9),
        .pink.opacity(0.9),
        .mint.opacity(0.9),
        .purple.opacity(0.9),
        .yellow.opacity(0.9),
        .teal.opacity(0.9),
        .orange.opacity(0.9),
        .green.opacity(0.9)
    ]
    
    // 初期化子の追加 (colorIndex対応)
    init(id: UUID = UUID(), name: String, professor: String, room: String, weekday: Weekday, period: Period, color: Color) {
        self.id = id
        self.name = name
        self.professor = professor
        self.room = room
        self.weekday = weekday
        self.period = period
        
        // 色のインデックスを設定
        if let index = Course.colors.firstIndex(where: { $0 == color }) {
            self.colorIndex = index
        } else {
            self.colorIndex = Int.random(in: 0..<Course.colors.count)
        }
    }
    
    init(id: UUID = UUID(), name: String, professor: String, room: String, weekday: Weekday, period: Period, colorIndex: Int, userId: String = "", semester: String = "") {
        self.id = id
        self.name = name
        self.professor = professor
        self.room = room
        self.weekday = weekday
        self.period = period
        self.colorIndex = colorIndex
        self.userId = userId
        self.semester = semester
    }
    
    // サンプルデータ
    static let samples: [Course] = [
        Course(name: "プログラミング基礎", professor: "鈴木教授", room: "情報1-301", weekday: .monday, period: .first, color: colors[0]),
        Course(name: "データ構造", professor: "佐藤教授", room: "情報1-201", weekday: .monday, period: .third, color: colors[7]),
        Course(name: "確率統計", professor: "田中教授", room: "理工3-101", weekday: .tuesday, period: .second, color: colors[6]),
        Course(name: "情報倫理", professor: "伊藤教授", room: "共通2-501", weekday: .wednesday, period: .fourth, color: colors[3]),
        Course(name: "人工知能概論", professor: "高橋教授", room: "情報2-401", weekday: .thursday, period: .first, color: colors[1]),
        Course(name: "データベース", professor: "山本教授", room: "情報1-302", weekday: .friday, period: .second, color: colors[2])
    ]
    
    // Firestore用のデータ変換メソッド
    func toFirestore() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "professor": professor,
            "room": room,
            "weekday": weekday.rawValue,
            "period": period.rawValue,
            "colorIndex": colorIndex,
            "userId": userId,
            "semester": semester,
            "createdAt": FieldValue.serverTimestamp()
        ]
    }
    
    // Firestore 文書からインスタンスを作成
    static func fromFirestore(_ document: DocumentSnapshot) -> Course? {
        guard let data = document.data() else { return nil }
        
        guard 
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let professor = data["professor"] as? String,
            let room = data["room"] as? String,
            let weekdayString = data["weekday"] as? String,
            let periodInt = data["period"] as? Int,
            let colorIndex = data["colorIndex"] as? Int
        else { return nil }
        
        // 曜日と時間枠の変換
        guard 
            let weekday = Weekday(rawValue: weekdayString),
            let period = Period(rawValue: periodInt)
        else { return nil }
        
        let userId = data["userId"] as? String ?? ""
        let semester = data["semester"] as? String ?? ""
        
        return Course(
            id: id,
            name: name,
            professor: professor,
            room: room,
            weekday: weekday,
            period: period,
            colorIndex: colorIndex,
            userId: userId,
            semester: semester
        )
    }
}

// タイムテーブルのViewModel
class TimeTableViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentSemester: String = ""
    
    private let db = FirebaseManager.shared.getFirestore()
    private var listener: ListenerRegistration?
    
    init() {
        // 現在の学期を設定
        let year = Calendar.current.component(.year, from: Date())
        let month = Calendar.current.component(.month, from: Date())
        currentSemester = "\(year)年\(month <= 6 ? "前期" : "後期")"
        
        loadSampleData()  // 開発段階ではサンプルデータを使う
    }
    
    deinit {
        listener?.remove()
    }
    
    // サンプルデータをロード
    private func loadSampleData() {
        courses = Course.samples
    }
    
    // 特定ユーザーの時間割を取得
    func fetchUserCourses(userId: String) {
        isLoading = true
        errorMessage = nil
        
        db.collection("courses")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "時間割の取得に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.courses = []
                        return
                    }
                    
                    var fetchedCourses: [Course] = []
                    for document in documents {
                        if let course = Course.fromFirestore(document) {
                            fetchedCourses.append(course)
                        }
                    }
                    
                    if fetchedCourses.isEmpty {
                        // データがない場合はサンプルデータをロード
                        self.courses = Course.samples
                    } else {
                        self.courses = fetchedCourses
                    }
                }
            }
    }
    
    // リアルタイムでユーザーの時間割を監視
    func listenToUserCourses(userId: String) {
        listener?.remove()
        
        isLoading = true
        errorMessage = nil
        
        listener = db.collection("courses")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "時間割の監視中にエラーが発生しました: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.courses = []
                        return
                    }
                    
                    var fetchedCourses: [Course] = []
                    for document in documents {
                        if let course = Course.fromFirestore(document) {
                            fetchedCourses.append(course)
                        }
                    }
                    
                    if fetchedCourses.isEmpty {
                        // データがない場合はサンプルデータをロード
                        self.courses = Course.samples
                    } else {
                        self.courses = fetchedCourses
                    }
                }
            }
    }
    
    // 時間割に授業を追加
    func addCourse(_ course: Course) {
        isLoading = true
        errorMessage = nil
        
        var updatedCourse = course
        updatedCourse.userId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
        updatedCourse.semester = currentSemester
        
        let courseData = updatedCourse.toFirestore()
        
        db.collection("courses")
            .document(updatedCourse.id.uuidString)
            .setData(courseData) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "授業の追加に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    // 追加が成功したらメモリ上のデータも更新
                    if let index = self.courses.firstIndex(where: { $0.id == updatedCourse.id }) {
                        self.courses[index] = updatedCourse
                    } else {
                        self.courses.append(updatedCourse)
                    }
                }
            }
    }
    
    // 時間割から授業を削除
    func deleteCourse(courseId: UUID) {
        isLoading = true
        errorMessage = nil
        
        db.collection("courses")
            .document(courseId.uuidString)
            .delete { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "授業の削除に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    // 削除成功したらメモリ上のデータも更新
                    self.courses.removeAll { $0.id == courseId }
                }
            }
    }
    
    // 授業データを更新
    func updateCourse(_ course: Course) {
        isLoading = true
        errorMessage = nil
        
        let courseData = course.toFirestore()
        
        db.collection("courses")
            .document(course.id.uuidString)
            .updateData(courseData) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "授業の更新に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    // 更新成功したらメモリ上のデータも更新
                    if let index = self.courses.firstIndex(where: { $0.id == course.id }) {
                        self.courses[index] = course
                    }
                }
            }
    }
    
    // 特定の曜日と時間の授業を取得
    func courseFor(weekday: Weekday, period: Period) -> Course? {
        return courses.first { $0.weekday == weekday && $0.period == period }
    }
    
    // 特定の曜日の授業を取得
    func coursesFor(weekday: Weekday) -> [Course] {
        return courses.filter { $0.weekday == weekday }
    }
    
    // ランダムな色を選択
    func randomColor() -> Color {
        return Course.colors.randomElement() ?? .blue
    }
}