import Foundation
import SwiftUI

// Model for a course/class
struct Course: Identifiable {
    var id = UUID()
    var name: String
    var professor: String
    var location: String
    var startTime: Date
    var endTime: Date
    var weekdays: [Weekday]
    var color: Color
    
    // Helper method to check if course occurs on a specific weekday
    func isOnDay(_ weekday: Weekday) -> Bool {
        return weekdays.contains(weekday)
    }
}

// Represents days of the week
enum Weekday: Int, CaseIterable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1
    
    var shortName: String {
        switch self {
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        case .sunday: return "일"
        }
    }
    
    var fullName: String {
        switch self {
        case .monday: return "월요일"
        case .tuesday: return "화요일"
        case .wednesday: return "수요일"
        case .thursday: return "목요일"
        case .friday: return "금요일"
        case .saturday: return "토요일"
        case .sunday: return "일요일"
        }
    }
    
    static func fromDate(_ date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekdayValue = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekdayValue) ?? .monday
    }
}

// View model for the timetable
class TimeTableViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var selectedWeekday: Weekday = .monday
    
    init() {
        loadSampleCourses()
    }
    
    func loadSampleCourses() {
        // Helper function to create a time
        func createTime(hour: Int, minute: Int) -> Date {
            let calendar = Calendar.current
            let components = DateComponents(hour: hour, minute: minute)
            return calendar.date(from: components) ?? Date()
        }
        
        // Sample courses data
        courses = [
            Course(
                name: "데이터베이스",
                professor: "김교수",
                location: "공학관 201호",
                startTime: createTime(hour: 9, minute: 0),
                endTime: createTime(hour: 10, minute: 30),
                weekdays: [.monday, .wednesday],
                color: .blue
            ),
            Course(
                name: "프로그래밍 기초",
                professor: "이교수",
                location: "과학관 101호",
                startTime: createTime(hour: 11, minute: 0),
                endTime: createTime(hour: 12, minute: 30),
                weekdays: [.tuesday, .thursday],
                color: .green
            ),
            Course(
                name: "알고리즘",
                professor: "박교수",
                location: "정보관 305호",
                startTime: createTime(hour: 14, minute: 0),
                endTime: createTime(hour: 15, minute: 30),
                weekdays: [.monday, .friday],
                color: .purple
            ),
            Course(
                name: "컴퓨터 구조",
                professor: "최교수",
                location: "공학관 405호",
                startTime: createTime(hour: 16, minute: 0),
                endTime: createTime(hour: 17, minute: 30),
                weekdays: [.wednesday],
                color: .orange
            )
        ]
    }
    
    // Method to add a new course
    func addCourse(_ course: Course) {
        courses.append(course)
    }
    
    // Method to delete a course
    func deleteCourse(at indexSet: IndexSet) {
        courses.remove(atOffsets: indexSet)
    }
    
    // Get courses for a specific weekday
    func coursesForWeekday(_ weekday: Weekday) -> [Course] {
        return courses.filter { $0.isOnDay(weekday) }
    }
}