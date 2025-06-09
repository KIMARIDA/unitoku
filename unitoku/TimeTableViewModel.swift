import Foundation
import SwiftUI

class TimeTableViewModel: ObservableObject {
    @Published var courses: [Course] = []
    
    init() {
        // 초기 데이터 로드
        self.courses = Course.samples
    }
    
    func addCourse(_ course: Course) {
        self.courses.append(course)
    }
    
    func deleteCourse(_ course: Course) {
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses.remove(at: index)
        }
    }
    
    func updateCourse(_ course: Course) {
        if let index = courses.firstIndex(where: { $0.id == course.id }) {
            courses[index] = course
        }
    }
    
    func coursesFor(weekday: Weekday) -> [Course] {
        return courses.filter { $0.weekday == weekday }
    }
    
    func courseFor(weekday: Weekday, period: Period) -> Course? {
        return courses.first { $0.weekday == weekday && $0.period == period }
    }
    
    func randomColor() -> Color {
        return Course.colors.randomElement() ?? .blue
    }
}