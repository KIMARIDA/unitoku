import Foundation
import SwiftUI

// 曜日の列挙型
enum Weekday: String, CaseIterable, Identifiable {
    case monday = "月"
    case tuesday = "火"
    case wednesday = "水"
    case thursday = "木"
    case friday = "金"
    
    var id: String { self.rawValue }
}

// 時間帯の列挙型
enum Period: Int, CaseIterable, Identifiable {
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
struct Course: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var professor: String
    var room: String
    var weekday: Weekday
    var period: Period
    var color: Color
    
    // 色のオプション
    static let colors: [Color] = [
        .blue, .green, .orange, .purple, .red, .pink, .yellow, .teal
    ]
    
    // サンプルデータ
    static let samples: [Course] = [
        Course(name: "プログラミング基礎", professor: "鈴木教授", room: "情報1-301", weekday: .monday, period: .first, color: .blue),
        Course(name: "データ構造", professor: "佐藤教授", room: "情報1-201", weekday: .monday, period: .third, color: .green),
        Course(name: "確率統計", professor: "田中教授", room: "理工3-101", weekday: .tuesday, period: .second, color: .orange),
        Course(name: "情報倫理", professor: "伊藤教授", room: "共通2-501", weekday: .wednesday, period: .fourth, color: .purple),
        Course(name: "人工知能概論", professor: "高橋教授", room: "情報2-401", weekday: .thursday, period: .first, color: .red),
        Course(name: "データベース", professor: "山本教授", room: "情報1-302", weekday: .friday, period: .second, color: .pink)
    ]
}