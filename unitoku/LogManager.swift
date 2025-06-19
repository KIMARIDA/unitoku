import Foundation
import Combine
import SwiftUI

// MARK: - 로그 레벨
enum LogLevel: String, CaseIterable, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
}

// MARK: - 로그 카테고리
enum LogCategory: String, CaseIterable, Codable {
    case system = "SYSTEM"
    case user = "USER"
    case network = "NETWORK"
    case database = "DATABASE"
    case security = "SECURITY"
    case performance = "PERFORMANCE"
    case analytics = "ANALYTICS"
    case ui = "UI"
    
    var displayName: String {
        switch self {
        case .system: return "시스템"
        case .user: return "사용자"
        case .network: return "네트워크"
        case .database: return "데이터베이스"
        case .security: return "보안"
        case .performance: return "성능"
        case .analytics: return "분석"
        case .ui: return "UI"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .user: return "person"
        case .network: return "network"
        case .database: return "externaldrive"
        case .security: return "shield"
        case .performance: return "speedometer"
        case .analytics: return "chart.bar"
        case .ui: return "rectangle.on.rectangle"
        }
    }
}

// MARK: - 로그 엔트리
struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let details: [String: String]
    let sessionId: String?
    let userId: String?
    let screenName: String?
    let errorCode: String?
    let stackTrace: String?
    
    init(level: LogLevel, category: LogCategory, message: String, details: [String: String] = [:], sessionId: String? = nil, userId: String? = nil, screenName: String? = nil, errorCode: String? = nil, stackTrace: String? = nil) {
        self.timestamp = Date()
        self.level = level
        self.category = category
        self.message = message
        self.details = details
        self.sessionId = sessionId
        self.userId = userId
        self.screenName = screenName
        self.errorCode = errorCode
        self.stackTrace = stackTrace
    }
    
    // 타임스탬프를 포함한 커스텀 이니셜라이저
    init(timestamp: Date, level: LogLevel, category: LogCategory, message: String, details: [String: String] = [:], sessionId: String? = nil, userId: String? = nil, screenName: String? = nil, errorCode: String? = nil, stackTrace: String? = nil) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.details = details
        self.sessionId = sessionId
        self.userId = userId
        self.screenName = screenName
        self.errorCode = errorCode
        self.stackTrace = stackTrace
    }
}

// MARK: - 로그 필터
struct LogFilter {
    var levels: Set<LogLevel> = Set(LogLevel.allCases)
    var categories: Set<LogCategory> = Set(LogCategory.allCases)
    var searchText: String = ""
    var dateRange: ClosedRange<Date>?
    var userId: String?
    var sessionId: String?
    
    func matches(_ entry: LogEntry) -> Bool {
        // 레벨 필터
        guard levels.contains(entry.level) else { return false }
        
        // 카테고리 필터
        guard categories.contains(entry.category) else { return false }
        
        // 검색 텍스트 필터
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            let messageMatch = entry.message.lowercased().contains(searchLower)
            let detailsMatch = entry.details.values.joined().lowercased().contains(searchLower)
            guard messageMatch || detailsMatch else { return false }
        }
        
        // 날짜 범위 필터
        if let dateRange = dateRange {
            guard dateRange.contains(entry.timestamp) else { return false }
        }
        
        // 사용자 ID 필터
        if let userId = userId, !userId.isEmpty {
            guard entry.userId == userId else { return false }
        }
        
        // 세션 ID 필터
        if let sessionId = sessionId, !sessionId.isEmpty {
            guard entry.sessionId == sessionId else { return false }
        }
        
        return true
    }
}

// MARK: - 로그 분석 결과
struct LogAnalytics {
    let totalCount: Int
    let levelCounts: [LogLevel: Int]
    let categoryCounts: [LogCategory: Int]
    let hourlyDistribution: [Int: Int] // Hour -> Count
    let topErrors: [String: Int] // Error message -> Count
    let uniqueUsers: Set<String>
    let uniqueSessions: Set<String>
    let averageLogsPerSession: Double
    let errorRate: Double
    let criticalErrorRate: Double
}

// MARK: - 로그 관리자
class LogManager: ObservableObject {
    static let shared = LogManager()
    
    // MARK: - Published Properties
    @Published var logs: [LogEntry] = []
    @Published var filteredLogs: [LogEntry] = []
    @Published var currentFilter = LogFilter()
    @Published var analytics = LogAnalytics(
        totalCount: 0,
        levelCounts: [:],
        categoryCounts: [:],
        hourlyDistribution: [:],
        topErrors: [:],
        uniqueUsers: [],
        uniqueSessions: [],
        averageLogsPerSession: 0,
        errorRate: 0,
        criticalErrorRate: 0
    )
    
    // MARK: - Private Properties
    private let maxLogEntries = 10000
    private var cancellables = Set<AnyCancellable>()
    private let fileURL: URL
    
    private init() {
        // 로그 파일 경로 설정
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("app_logs.json")
        
        loadLogsFromFile()
        setupAutoSave()
        generateSampleLogs()
        updateFilteredLogs()
        updateAnalytics()
    }
    
    // MARK: - 로그 기록
    func log(_ level: LogLevel, category: LogCategory, message: String, details: [String: String] = [:], errorCode: String? = nil, stackTrace: String? = nil) {
        let entry = LogEntry(
            level: level,
            category: category,
            message: message,
            details: details,
            sessionId: getCurrentSessionId(),
            userId: getCurrentUserId(),
            screenName: getCurrentScreenName(),
            errorCode: errorCode,
            stackTrace: stackTrace
        )
        
        DispatchQueue.main.async {
            self.logs.insert(entry, at: 0)
            
            // 로그 개수 제한
            if self.logs.count > self.maxLogEntries {
                self.logs = Array(self.logs.prefix(self.maxLogEntries))
            }
            
            self.updateFilteredLogs()
            self.updateAnalytics()
        }
        
        // 콘솔에도 출력
        print("[\(level.rawValue)] [\(category.rawValue)] \(message)")
        
        // 중요한 오류는 Crashlytics에도 전송
        if level.priority >= LogLevel.error.priority {
            // Crashlytics 연동 코드 (필요시)
        }
    }
    
    // MARK: - 편의 메서드
    func debug(_ message: String, category: LogCategory = .system, details: [String: String] = [:]) {
        log(.debug, category: category, message: message, details: details)
    }
    
    func info(_ message: String, category: LogCategory = .system, details: [String: String] = [:]) {
        log(.info, category: category, message: message, details: details)
    }
    
    func warning(_ message: String, category: LogCategory = .system, details: [String: String] = [:]) {
        log(.warning, category: category, message: message, details: details)
    }
    
    func error(_ message: String, category: LogCategory = .system, details: [String: String] = [:], errorCode: String? = nil, stackTrace: String? = nil) {
        log(.error, category: category, message: message, details: details, errorCode: errorCode, stackTrace: stackTrace)
    }
    
    func critical(_ message: String, category: LogCategory = .system, details: [String: String] = [:], errorCode: String? = nil, stackTrace: String? = nil) {
        log(.critical, category: category, message: message, details: details, errorCode: errorCode, stackTrace: stackTrace)
    }
    
    // MARK: - 필터링
    func updateFilter(_ filter: LogFilter) {
        currentFilter = filter
        updateFilteredLogs()
    }
    
    private func updateFilteredLogs() {
        filteredLogs = logs.filter { currentFilter.matches($0) }
    }
    
    // MARK: - 분석
    private func updateAnalytics() {
        let logs = self.filteredLogs
        
        // 레벨별 카운트
        var levelCounts: [LogLevel: Int] = [:]
        var categoryCounts: [LogCategory: Int] = [:]
        var hourlyDistribution: [Int: Int] = [:]
        var topErrors: [String: Int] = [:]
        var uniqueUsers: Set<String> = []
        var uniqueSessions: Set<String> = []
        
        for log in logs {
            // 레벨 카운트
            levelCounts[log.level, default: 0] += 1
            
            // 카테고리 카운트
            categoryCounts[log.category, default: 0] += 1
            
            // 시간대별 분포
            let hour = Calendar.current.component(.hour, from: log.timestamp)
            hourlyDistribution[hour, default: 0] += 1
            
            // 오류 메시지 카운트
            if log.level.priority >= LogLevel.error.priority {
                topErrors[log.message, default: 0] += 1
            }
            
            // 고유 사용자/세션
            if let userId = log.userId {
                uniqueUsers.insert(userId)
            }
            if let sessionId = log.sessionId {
                uniqueSessions.insert(sessionId)
            }
        }
        
        // 평균 세션당 로그 수
        let averageLogsPerSession = uniqueSessions.isEmpty ? 0 : Double(logs.count) / Double(uniqueSessions.count)
        
        // 오류율 계산
        let errorCount = levelCounts[.error, default: 0] + levelCounts[.critical, default: 0]
        let errorRate = logs.isEmpty ? 0 : Double(errorCount) / Double(logs.count) * 100
        
        let criticalErrorRate = logs.isEmpty ? 0 : Double(levelCounts[.critical, default: 0]) / Double(logs.count) * 100
        
        analytics = LogAnalytics(
            totalCount: logs.count,
            levelCounts: levelCounts,
            categoryCounts: categoryCounts,
            hourlyDistribution: hourlyDistribution,
            topErrors: topErrors,
            uniqueUsers: uniqueUsers,
            uniqueSessions: uniqueSessions,
            averageLogsPerSession: averageLogsPerSession,
            errorRate: errorRate,
            criticalErrorRate: criticalErrorRate
        )
    }
    
    // MARK: - 로그 관리
    func clearLogs() {
        logs.removeAll()
        updateFilteredLogs()
        updateAnalytics()
        saveLogsToFile()
    }
    
    func exportLogs() -> Data? {
        do {
            return try JSONEncoder().encode(logs)
        } catch {
            self.error("로그 내보내기 실패", category: .system, details: ["error": error.localizedDescription])
            return nil
        }
    }
    
    func importLogs(_ data: Data) {
        do {
            let importedLogs = try JSONDecoder().decode([LogEntry].self, from: data)
            logs.append(contentsOf: importedLogs)
            
            // 중복 제거 및 시간순 정렬
            logs = Array(Set(logs.map { $0.id }).compactMap { id in
                logs.first { $0.id == id }
            }).sorted { $0.timestamp > $1.timestamp }
            
            updateFilteredLogs()
            updateAnalytics()
            saveLogsToFile()
        } catch {
            self.error("로그 가져오기 실패", category: .system, details: ["error": error.localizedDescription])
        }
    }
    
    // MARK: - 파일 저장/로드
    private func saveLogsToFile() {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: fileURL)
        } catch {
            print("로그 파일 저장 실패: \(error)")
        }
    }
    
    private func loadLogsFromFile() {
        do {
            let data = try Data(contentsOf: fileURL)
            logs = try JSONDecoder().decode([LogEntry].self, from: data)
        } catch {
            print("로그 파일 로드 실패: \(error)")
            logs = []
        }
    }
    
    private func setupAutoSave() {
        // 5분마다 자동 저장
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.saveLogsToFile()
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentSessionId() -> String? {
        return UserDefaults.standard.string(forKey: "currentSessionId")
    }
    
    private func getCurrentUserId() -> String? {
        return UserDefaults.standard.string(forKey: "currentUserId")
    }
    
    private func getCurrentScreenName() -> String? {
        // 현재 화면 이름을 추적하는 로직 (실제 구현 필요)
        return nil
    }
    
    // MARK: - 샘플 데이터 생성
    private func generateSampleLogs() {
        guard logs.isEmpty else { return }
        
        let sampleMessages = [
            "사용자 로그인 성공",
            "게시글 작성 완료",
            "댓글 등록",
            "이미지 업로드 시작",
            "이미지 업로드 완료",
            "네트워크 연결 오류",
            "데이터베이스 쿼리 실행",
            "캐시 데이터 로드",
            "사용자 세션 종료",
            "앱 백그라운드 진입"
        ]
        
        let categories = LogCategory.allCases
        let levels = LogLevel.allCases
        
        // 최근 24시간 동안의 샘플 로그 생성
        for i in 0..<200 {
            let logTimestamp = Date().addingTimeInterval(-TimeInterval(i * 300)) // 5분 간격
            let category = categories.randomElement()!
            let level = levels.randomElement()!
            let message = sampleMessages.randomElement()!
            
            let entry = LogEntry(
                timestamp: logTimestamp,
                level: level,
                category: category,
                message: message,
                details: ["sample": "true"],
                sessionId: "session_\(Int.random(in: 1...10))",
                userId: "user_\(Int.random(in: 1...5))"
            )
            
            logs.append(entry)
        }
        
        logs.sort { $0.timestamp > $1.timestamp }
    }
}

// MARK: - SwiftUI 확장
extension View {
    func logEvent(_ level: LogLevel, category: LogCategory, message: String, details: [String: String] = [:]) -> some View {
        self.onAppear {
            LogManager.shared.log(level, category: category, message: message, details: details)
        }
    }
}
