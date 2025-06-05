import Foundation

extension Date {
    // 일본어로 상대적 시간을 표시하는 함수
    func relativeTimeInJapanese() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        // 미래 날짜인 경우
        if let year = components.year, year < 0 {
            return "\(-year)年後"
        }
        if let month = components.month, month < 0 {
            return "\(-month)ヶ月後"
        }
        if let day = components.day, day < 0 {
            return "\(-day)日後"
        }
        if let hour = components.hour, hour < 0 {
            return "\(-hour)時間後"
        }
        if let minute = components.minute, minute < 0 {
            return "\(-minute)分後"
        }
        if let second = components.second, second < 0 {
            return "\(-second)秒後"
        }
        
        // 과거 날짜인 경우
        if let year = components.year, year > 0 {
            return "\(year)年前"
        }
        if let month = components.month, month > 0 {
            return "\(month)ヶ月前"
        }
        if let day = components.day, day > 0 {
            return "\(day)日前"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour)時間前"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute)分前"
        }
        if let second = components.second, second > 0 {
            return "\(second)秒前"
        }
        
        return "たった今" // 방금 전
    }
}