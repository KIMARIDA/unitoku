import Foundation
import Combine
import SwiftUI

// MARK: - 시간 범위 열거형
enum TimeRange: String, CaseIterable {
    case hour = "1h"
    case day = "24h" 
    case week = "7d"
    case month = "30d"
    
    var displayName: String {
        switch self {
        case .hour: return "1시간"
        case .day: return "24시간"
        case .week: return "7일"
        case .month: return "30일"
        }
    }
    
    var seconds: TimeInterval {
        switch self {
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .month: return 2592000
        }
    }
}

// MARK: - 트렌드 방향
enum TrendDirection: String, CaseIterable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    
    var iconName: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        }
    }
    
    var displayText: String {
        switch self {
        case .improving: return "개선"
        case .declining: return "악화"
        case .stable: return "안정"
        }
    }
}

// MARK: - 시스템 상태
enum SystemHealth: String, CaseIterable {
    case healthy = "healthy"
    case warning = "warning"
    case error = "error"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .healthy: return "정상"
        case .warning: return "주의"
        case .error: return "오류"
        case .unknown: return "알 수 없음"
        }
    }
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .orange
        case .error: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - 오류 심각도
enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "낮음"
        case .medium: return "보통"
        case .high: return "높음"
        case .critical: return "심각"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - 보안 이벤트 타입
enum SecurityEventType: String, CaseIterable {
    case suspiciousLogin = "suspicious_login"
    case contentViolation = "content_violation"
    case spamDetection = "spam_detection"
    case rateLimit = "rate_limit"
    case unauthorizedAccess = "unauthorized_access"
    case dataLeak = "data_leak"
    
    var displayName: String {
        switch self {
        case .suspiciousLogin: return "의심스러운 로그인"
        case .contentViolation: return "콘텐츠 위반"
        case .spamDetection: return "스팸 감지"
        case .rateLimit: return "사용량 제한"
        case .unauthorizedAccess: return "무단 접근"
        case .dataLeak: return "데이터 유출"
        }
    }
}

// MARK: - 데이터 모델
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    let category: String?
    
    init(timestamp: Date, value: Double, category: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.category = category
    }
}

struct ErrorEvent: Identifiable {
    let id = UUID()
    let message: String
    let severity: ErrorSeverity
    let timestamp: Date
    let count: Int
    let stackTrace: String?
    let userId: String?
    let sessionId: String?
    
    init(message: String, severity: ErrorSeverity, timestamp: Date = Date(), count: Int = 1, stackTrace: String? = nil, userId: String? = nil, sessionId: String? = nil) {
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
        self.count = count
        self.stackTrace = stackTrace
        self.userId = userId
        self.sessionId = sessionId
    }
}

struct SecurityEvent: Identifiable {
    let id = UUID()
    let type: SecurityEventType
    let description: String
    let severity: ErrorSeverity
    let timestamp: Date
    let userId: String?
    let ipAddress: String?
    let userAgent: String?
    
    init(type: SecurityEventType, description: String, severity: ErrorSeverity, timestamp: Date = Date(), userId: String? = nil, ipAddress: String? = nil, userAgent: String? = nil) {
        self.type = type
        self.description = description
        self.severity = severity
        self.timestamp = timestamp
        self.userId = userId
        self.ipAddress = ipAddress
        self.userAgent = userAgent
    }
}

struct SystemStatus {
    let firebase: SystemHealth
    let database: SystemHealth
    let storage: SystemHealth
    let analytics: SystemHealth
    let crashlytics: SystemHealth
    let performance: SystemHealth
    
    init(firebase: SystemHealth = .healthy, database: SystemHealth = .healthy, storage: SystemHealth = .healthy, analytics: SystemHealth = .healthy, crashlytics: SystemHealth = .healthy, performance: SystemHealth = .healthy) {
        self.firebase = firebase
        self.database = database
        self.storage = storage
        self.analytics = analytics
        self.crashlytics = crashlytics
        self.performance = performance
    }
}

struct RealTimeMetrics {
    let activeUsers: Int
    let userTrend: TrendDirection
    let errorRate: Double
    let errorTrend: TrendDirection
    let responseTime: Double
    let responseTrend: TrendDirection
    let throughput: Double
    let throughputTrend: TrendDirection
    
    init(activeUsers: Int = 0, userTrend: TrendDirection = .stable, errorRate: Double = 0.0, errorTrend: TrendDirection = .stable, responseTime: Double = 0.0, responseTrend: TrendDirection = .stable, throughput: Double = 0.0, throughputTrend: TrendDirection = .stable) {
        self.activeUsers = activeUsers
        self.userTrend = userTrend
        self.errorRate = errorRate
        self.errorTrend = errorTrend
        self.responseTime = responseTime
        self.responseTrend = responseTrend
        self.throughput = throughput
        self.throughputTrend = throughputTrend
    }
}

// MARK: - 모니터링 서비스
class MonitoringService: ObservableObject {
    static let shared = MonitoringService()
    
    // MARK: - Published Properties
    @Published var realTimeMetrics = RealTimeMetrics()
    @Published var systemStatus = SystemStatus()
    @Published var recentErrors: [ErrorEvent] = []
    @Published var securityEvents: [SecurityEvent] = []
    
    // MARK: - Chart Data
    @Published var responseTimeData: [ChartDataPoint] = []
    @Published var memoryUsageData: [ChartDataPoint] = []
    @Published var cpuUsageData: [ChartDataPoint] = []
    @Published var activeUsersData: [ChartDataPoint] = []
    @Published var eventFrequencyData: [ChartDataPoint] = []
    
    // MARK: - Private Properties
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // AnalyticsManager 대신 직접 메트릭 계산
    private var currentMemoryUsage: Double = 0
    private var currentCPUUsage: Double = 0
    
    private init() {
        startRealTimeMonitoring()
        generateInitialData()
    }
    
    deinit {
        stopRealTimeMonitoring()
    }
    
    // MARK: - 실시간 모니터링 시작
    private func startRealTimeMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.updateRealTimeMetrics()
            self.checkSystemHealth()
            self.updateChartData()
        }
    }
    
    private func stopRealTimeMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - 실시간 메트릭 업데이트
    private func updateRealTimeMetrics() {
        // 실제 메트릭 수집 (시뮬레이션)
        let previousActiveUsers = realTimeMetrics.activeUsers
        let newActiveUsers = Int.random(in: 10...100)
        
        let userTrend: TrendDirection
        if newActiveUsers > previousActiveUsers {
            userTrend = .improving
        } else if newActiveUsers < previousActiveUsers {
            userTrend = .declining
        } else {
            userTrend = .stable
        }
        
        let previousErrorRate = realTimeMetrics.errorRate
        let newErrorRate = Double.random(in: 0...5.0)
        
        let errorTrend: TrendDirection
        if newErrorRate < previousErrorRate {
            errorTrend = .improving
        } else if newErrorRate > previousErrorRate {
            errorTrend = .declining
        } else {
            errorTrend = .stable
        }
        
        realTimeMetrics = RealTimeMetrics(
            activeUsers: newActiveUsers,
            userTrend: userTrend,
            errorRate: newErrorRate,
            errorTrend: errorTrend,
            responseTime: Double.random(in: 100...500),
            responseTrend: .stable,
            throughput: Double.random(in: 50...200),
            throughputTrend: .stable
        )
    }
    
    // MARK: - 시스템 상태 확인
    private func checkSystemHealth() {
        // Firebase 연결 상태 확인
        let firebaseHealth: SystemHealth = Bool.random() ? .healthy : .warning
        let databaseHealth: SystemHealth = Bool.random() ? .healthy : .warning
        let storageHealth: SystemHealth = Bool.random() ? .healthy : .warning
        let analyticsHealth: SystemHealth = Bool.random() ? .healthy : .warning
        let crashlyticsHealth: SystemHealth = Bool.random() ? .healthy : .warning
        let performanceHealth: SystemHealth = Bool.random() ? .healthy : .warning
        
        systemStatus = SystemStatus(
            firebase: firebaseHealth,
            database: databaseHealth,
            storage: storageHealth,
            analytics: analyticsHealth,
            crashlytics: crashlyticsHealth,
            performance: performanceHealth
        )
    }
    
    // MARK: - 차트 데이터 업데이트
    private func updateChartData() {
        let now = Date()
        
        // 응답 시간 데이터
        responseTimeData.append(ChartDataPoint(
            timestamp: now,
            value: realTimeMetrics.responseTime
        ))
        
        // 메모리 사용량 데이터
        let memoryUsage = getMemoryUsage()
        currentMemoryUsage = memoryUsage
        memoryUsageData.append(ChartDataPoint(
            timestamp: now,
            value: memoryUsage
        ))
        
        // CPU 사용량 데이터
        let cpuUsage = getCPUUsage()
        currentCPUUsage = cpuUsage
        cpuUsageData.append(ChartDataPoint(
            timestamp: now,
            value: cpuUsage
        ))
        
        // 활성 사용자 데이터
        activeUsersData.append(ChartDataPoint(
            timestamp: now,
            value: Double(realTimeMetrics.activeUsers)
        ))
        
        // 이벤트 빈도 데이터
        updateEventFrequencyData()
        
        // 데이터 크기 제한 (최근 100개 포인트만 유지)
        limitDataSize()
    }
    
    private func updateEventFrequencyData() {
        let eventTypes = ["게시글", "댓글", "로그인", "검색", "오류"]
        eventFrequencyData = eventTypes.map { type in
            ChartDataPoint(
                timestamp: Date(),
                value: Double.random(in: 1...20),
                category: type
            )
        }
    }
    
    private func limitDataSize() {
        let maxDataPoints = 100
        
        if responseTimeData.count > maxDataPoints {
            responseTimeData = Array(responseTimeData.suffix(maxDataPoints))
        }
        
        if memoryUsageData.count > maxDataPoints {
            memoryUsageData = Array(memoryUsageData.suffix(maxDataPoints))
        }
        
        if cpuUsageData.count > maxDataPoints {
            cpuUsageData = Array(cpuUsageData.suffix(maxDataPoints))
        }
        
        if activeUsersData.count > maxDataPoints {
            activeUsersData = Array(activeUsersData.suffix(maxDataPoints))
        }
    }
    
    // MARK: - 초기 데이터 생성
    private func generateInitialData() {
        let now = Date()
        let timeInterval: TimeInterval = 300 // 5분 간격
        
        // 최근 24시간 데이터 생성
        for i in 0..<288 { // 24시간 * 12 (5분 간격)
            let timestamp = now.addingTimeInterval(-TimeInterval(i) * timeInterval)
            
            responseTimeData.insert(ChartDataPoint(
                timestamp: timestamp,
                value: Double.random(in: 100...500)
            ), at: 0)
            
            memoryUsageData.insert(ChartDataPoint(
                timestamp: timestamp,
                value: Double.random(in: 50...200)
            ), at: 0)
            
            cpuUsageData.insert(ChartDataPoint(
                timestamp: timestamp,
                value: Double.random(in: 10...80)
            ), at: 0)
            
            activeUsersData.insert(ChartDataPoint(
                timestamp: timestamp,
                value: Double.random(in: 10...100)
            ), at: 0)
        }
        
        updateEventFrequencyData()
        generateSampleErrors()
        generateSampleSecurityEvents()
    }
    
    // MARK: - 샘플 오류 생성
    private func generateSampleErrors() {
        let sampleErrors = [
            ErrorEvent(message: "네트워크 연결 시간 초과", severity: .medium),
            ErrorEvent(message: "이미지 로드 실패", severity: .low, count: 3),
            ErrorEvent(message: "Firebase 인증 실패", severity: .high),
            ErrorEvent(message: "메모리 부족 경고", severity: .medium, count: 2)
        ]
        
        recentErrors = sampleErrors
    }
    
    // MARK: - 샘플 보안 이벤트 생성
    private func generateSampleSecurityEvents() {
        let sampleEvents = [
            SecurityEvent(type: .spamDetection, description: "반복적인 게시글 작성 감지", severity: .medium),
            SecurityEvent(type: .contentViolation, description: "부적절한 콘텐츠 필터링", severity: .low),
            SecurityEvent(type: .rateLimit, description: "API 사용량 제한 초과", severity: .medium)
        ]
        
        securityEvents = sampleEvents
    }
    
    // MARK: - Public Methods
    func refreshMetrics() {
        updateRealTimeMetrics()
        checkSystemHealth()
        updateChartData()
    }
    
    func addError(_ error: ErrorEvent) {
        recentErrors.insert(error, at: 0)
        
        // 최대 50개 오류만 유지
        if recentErrors.count > 50 {
            recentErrors = Array(recentErrors.prefix(50))
        }
    }
    
    func addSecurityEvent(_ event: SecurityEvent) {
        securityEvents.insert(event, at: 0)
        
        // 최대 30개 보안 이벤트만 유지
        if securityEvents.count > 30 {
            securityEvents = Array(securityEvents.prefix(30))
        }
    }
    
    func clearErrors() {
        recentErrors.removeAll()
    }
    
    func clearSecurityEvents() {
        securityEvents.removeAll()
    }
    
    // MARK: - 알림 및 경고
    func checkForAlerts() {
        // 높은 오류율 경고
        if realTimeMetrics.errorRate > 3.0 {
            let alert = ErrorEvent(
                message: "높은 오류율 감지: \(String(format: "%.1f", realTimeMetrics.errorRate))%",
                severity: .high
            )
            addError(alert)
        }
        
        // 메모리 사용량 경고
        if currentMemoryUsage > 150 {
            let alert = ErrorEvent(
                message: "높은 메모리 사용량: \(String(format: "%.1f", currentMemoryUsage))MB",
                severity: .medium
            )
            addError(alert)
        }
        
        // 응답 시간 경고
        if realTimeMetrics.responseTime > 1000 {
            let alert = ErrorEvent(
                message: "느린 응답 시간: \(String(format: "%.0f", realTimeMetrics.responseTime))ms",
                severity: .medium
            )
            addError(alert)
        }
    }
}

// MARK: - System Metrics Calculation
extension MonitoringService {
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024 // MB
        }
        return Double.random(in: 50...200) // Fallback to random value
    }
    
    private func getCPUUsage() -> Double {
        // CPU 사용량 계산 (시뮬레이션)
        return Double.random(in: 10...80)
    }
}
