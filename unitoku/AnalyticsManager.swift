import Foundation
import FirebaseCore
import FirebaseCrashlytics
import FirebasePerformance
import Combine
import SwiftUI

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

// MARK: - 분석 이벤트 타입
enum AnalyticsEvent: String, CaseIterable {
    // 사용자 행동
    case userLogin = "user_login"
    case userLogout = "user_logout"
    case userRegistration = "user_registration"
    case profileUpdate = "profile_update"
    
    // 게시글 관련
    case postCreate = "post_create"
    case postView = "post_view"
    case postLike = "post_like"
    case postShare = "post_share"
    case postEdit = "post_edit"
    case postDelete = "post_delete"
    
    // 댓글 관련
    case commentCreate = "comment_create"
    case commentLike = "comment_like"
    case commentEdit = "comment_edit"
    case commentDelete = "comment_delete"
    
    // 강의평가 관련
    case evaluationCreate = "evaluation_create"
    case evaluationView = "evaluation_view"
    case evaluationLike = "evaluation_like"
    
    // 채팅 관련
    case chatStart = "chat_start"
    case messagesSend = "message_send"
    case chatRoomJoin = "chat_room_join"
    case chatRoomLeave = "chat_room_leave"
    
    // 검색 및 네비게이션
    case search = "search"
    case categoryView = "category_view"
    case screenView = "screen_view"
    
    // 오류 및 성능
    case errorOccurred = "error_occurred"
    case networkError = "network_error"
    case performanceIssue = "performance_issue"
    
    // 보안 이벤트
    case securityViolation = "security_violation"
    case suspiciousActivity = "suspicious_activity"
    case contentFiltered = "content_filtered"
    
    // 비즈니스 메트릭
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case featureUsed = "feature_used"
    case tutorialCompleted = "tutorial_completed"
}

// MARK: - 성능 메트릭
struct PerformanceMetrics {
    let screenLoadTime: TimeInterval
    let networkLatency: TimeInterval
    let memoryUsage: Double // MB
    let cpuUsage: Double // Percentage
    let crashFreeRate: Double // Percentage
    let activeUsers: Int
    let sessionDuration: TimeInterval
}

// MARK: - 사용자 세그먼트
enum UserSegment: String, CaseIterable {
    case newUser = "new_user"
    case activeUser = "active_user"
    case powerUser = "power_user"
    case inactiveUser = "inactive_user"
    case premiumUser = "premium_user"
    case studentUser = "student_user"
    case facultyUser = "faculty_user"
}

// MARK: - 분석 및 모니터링 매니저
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    // MARK: - Published Properties
    @Published var isAnalyticsEnabled = true
    @Published var currentUserSegment: UserSegment = .newUser
    @Published var sessionMetrics = PerformanceMetrics(
        screenLoadTime: 0,
        networkLatency: 0,
        memoryUsage: 0,
        cpuUsage: 0,
        crashFreeRate: 100.0,
        activeUsers: 0,
        sessionDuration: 0
    )
    
    // MARK: - Private Properties
    private var sessionStartTime: Date?
    private var currentScreen: String = ""
    private var eventQueue: [AnalyticsEventData] = []
    private var performanceTraces: [String: Trace] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Session Management
    private var sessionTimer: Timer?
    private var performanceTimer: Timer?
    
    private init() {
        setupAnalytics()
        startSessionTracking()
        startPerformanceMonitoring()
    }
    
    deinit {
        endSession()
    }
    
    // MARK: - 초기 설정
    private func setupAnalytics() {
        // Firebase Analytics 설정
        Analytics.setAnalyticsCollectionEnabled(isAnalyticsEnabled)
        
        // 사용자 속성 설정
        setupUserProperties()
        
        // 기본 이벤트 매개변수 설정
        Analytics.setDefaultEventParameters([
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            "platform": "ios"
        ])
    }
    
    private func setupUserProperties() {
        if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
            Analytics.setUserID(userId)
        }
        
        if let userName = UserDefaults.standard.string(forKey: "currentUserName") {
            Analytics.setUserProperty(userName, forName: "user_name")
        }
        
        if let department = UserDefaults.standard.string(forKey: "userDepartment") {
            Analytics.setUserProperty(department, forName: "department")
        }
        
        if let grade = UserDefaults.standard.string(forKey: "userGrade") {
            Analytics.setUserProperty(grade, forName: "grade")
        }
        
        Analytics.setUserProperty(currentUserSegment.rawValue, forName: "user_segment")
    }
    
    // MARK: - 이벤트 추적
    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any] = [:]) {
        guard isAnalyticsEnabled else { return }
        
        var enrichedParameters = parameters
        enrichedParameters["timestamp"] = Date().timeIntervalSince1970
        enrichedParameters["user_segment"] = currentUserSegment.rawValue
        enrichedParameters["session_id"] = getSessionId()
        
        // Firebase Analytics 전송
        Analytics.logEvent(event.rawValue, parameters: enrichedParameters)
        
        // 로컬 큐에 추가 (배치 처리용)
        let eventData = AnalyticsEventData(
            event: event,
            parameters: enrichedParameters,
            timestamp: Date()
        )
        eventQueue.append(eventData)
        
        // 특별한 이벤트 처리
        handleSpecialEvents(event, parameters: enrichedParameters)
        
        print("📊 Analytics: \(event.rawValue) - \(enrichedParameters)")
    }
    
    private func handleSpecialEvents(_ event: AnalyticsEvent, parameters: [String: Any]) {
        switch event {
        case .userLogin:
            startSession()
            updateUserSegment()
        case .userLogout:
            endSession()
        case .errorOccurred:
            logErrorToCrashlytics(parameters)
        case .securityViolation:
            logSecurityEvent(parameters)
        case .performanceIssue:
            logPerformanceIssue(parameters)
        default:
            break
        }
    }
    
    // MARK: - 화면 추적
    func logScreenView(_ screenName: String, parameters: [String: Any] = [:]) {
        currentScreen = screenName
        
        var screenParameters = parameters
        screenParameters["screen_name"] = screenName
        screenParameters["previous_screen"] = currentScreen
        
        logEvent(.screenView, parameters: screenParameters)
        
        // 화면 로드 시간 측정 시작
        startPerformanceTrace("screen_load_\(screenName)")
    }
    
    // MARK: - 성능 추적
    func startPerformanceTrace(_ traceName: String) {
        guard let trace = Performance.startTrace(name: traceName) else { return }
        performanceTraces[traceName] = trace
    }
    
    func stopPerformanceTrace(_ traceName: String, customAttributes: [String: String] = [:]) {
        guard let trace = performanceTraces[traceName] else { return }
        
        // 커스텀 속성 추가
        for (key, value) in customAttributes {
            trace.setValue(value, forAttribute: key)
        }
        
        trace.stop()
        performanceTraces.removeValue(forKey: traceName)
    }
    
    func recordNetworkRequest(url: String, method: String, responseTime: TimeInterval, statusCode: Int) {
        let parameters: [String: Any] = [
            "url": url,
            "method": method,
            "response_time": responseTime,
            "status_code": statusCode,
            "network_type": getNetworkType()
        ]
        
        if statusCode >= 400 {
            logEvent(.networkError, parameters: parameters)
        }
        
        // Firebase Performance Monitoring에 자동으로 기록됨
    }
    
    // MARK: - 사용자 세그먼트 분석
    private func updateUserSegment() {
        let loginCount = UserDefaults.standard.integer(forKey: "loginCount")
        let postCount = UserDefaults.standard.integer(forKey: "userPostCount")
        let commentCount = UserDefaults.standard.integer(forKey: "userCommentCount")
        let lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date ?? Date()
        
        let daysSinceLastActive = Calendar.current.dateComponents([.day], from: lastActiveDate, to: Date()).day ?? 0
        
        // 세그먼트 결정 로직
        if loginCount <= 3 {
            currentUserSegment = .newUser
        } else if daysSinceLastActive > 30 {
            currentUserSegment = .inactiveUser
        } else if postCount > 50 || commentCount > 100 {
            currentUserSegment = .powerUser
        } else if loginCount > 10 && daysSinceLastActive <= 7 {
            currentUserSegment = .activeUser
        } else {
            currentUserSegment = .studentUser
        }
        
        Analytics.setUserProperty(currentUserSegment.rawValue, forName: "user_segment")
    }
    
    // MARK: - 세션 관리
    private func startSession() {
        sessionStartTime = Date()
        let sessionId = UUID().uuidString
        UserDefaults.standard.set(sessionId, forKey: "currentSessionId")
        
        logEvent(.sessionStart, parameters: [
            "session_id": sessionId,
            "device_model": UIDevice.current.model,
            "os_version": UIDevice.current.systemVersion
        ])
        
        // 세션 타이머 시작
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.collectPerformanceMetrics()
        }
    }
    
    private func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        
        logEvent(.sessionEnd, parameters: [
            "session_duration": sessionDuration,
            "screens_viewed": getScreensViewedCount(),
            "actions_performed": getActionsPerformedCount()
        ])
        
        sessionTimer?.invalidate()
        sessionStartTime = nil
    }
    
    private func startSessionTracking() {
        // 앱 상태 변화 감지
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                self.startSession()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { _ in
                self.endSession()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 성능 모니터링
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.collectPerformanceMetrics()
        }
    }
    
    private func collectPerformanceMetrics() {
        let memoryUsage = getMemoryUsage()
        let cpuUsage = getCPUUsage()
        
        sessionMetrics = PerformanceMetrics(
            screenLoadTime: getAverageScreenLoadTime(),
            networkLatency: getAverageNetworkLatency(),
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            crashFreeRate: getCrashFreeRate(),
            activeUsers: getActiveUsersCount(),
            sessionDuration: getCurrentSessionDuration()
        )
        
        // 성능 이슈 감지
        if memoryUsage > 200 || cpuUsage > 80 {
            logEvent(.performanceIssue, parameters: [
                "memory_usage": memoryUsage,
                "cpu_usage": cpuUsage,
                "issue_type": memoryUsage > 200 ? "high_memory" : "high_cpu"
            ])
        }
    }
    
    // MARK: - 오류 및 보안 이벤트
    private func logErrorToCrashlytics(_ parameters: [String: Any]) {
        if let errorMessage = parameters["error_message"] as? String {
            let error = NSError(
                domain: "unitoku.AnalyticsManager",
                code: parameters["error_code"] as? Int ?? -1,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    private func logSecurityEvent(_ parameters: [String: Any]) {
        Crashlytics.crashlytics().setCustomValue(parameters, forKey: "security_event")
        
        // 중요한 보안 이벤트는 즉시 전송
        if let severity = parameters["severity"] as? String, severity == "high" {
            Crashlytics.crashlytics().sendUnsentReports()
        }
    }
    
    private func logPerformanceIssue(_ parameters: [String: Any]) {
        Crashlytics.crashlytics().setCustomValue(parameters, forKey: "performance_issue")
    }
    
    // MARK: - 커스텀 메트릭
    func recordCustomMetric(_ metricName: String, value: Double, attributes: [String: String] = [:]) {
        logEvent(.featureUsed, parameters: [
            "metric_name": metricName,
            "metric_value": value,
            "attributes": attributes
        ])
    }
    
    func incrementCounter(_ counterName: String, by value: Int = 1) {
        let currentValue = UserDefaults.standard.integer(forKey: "counter_\(counterName)")
        let newValue = currentValue + value
        UserDefaults.standard.set(newValue, forKey: "counter_\(counterName)")
        
        logEvent(.featureUsed, parameters: [
            "counter_name": counterName,
            "counter_value": newValue,
            "increment": value
        ])
    }
    
    // MARK: - 배치 처리
    func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        // 이벤트를 서버로 전송 (실제 구현에서는 Firebase Functions 호출)
        let batchData = eventQueue.map { event in
            [
                "event": event.event.rawValue,
                "parameters": event.parameters,
                "timestamp": event.timestamp.timeIntervalSince1970
            ]
        }
        
        // Firebase Functions 호출하여 배치 처리
        sendBatchToServer(batchData)
        
        eventQueue.removeAll()
    }
    
    private func sendBatchToServer(_ batchData: [[String: Any]]) {
        // 실제 구현에서는 Firebase Functions 호출
        print("📦 Sending batch analytics data: \(batchData.count) events")
    }
    
    // MARK: - Helper Methods
    private func getSessionId() -> String {
        return UserDefaults.standard.string(forKey: "currentSessionId") ?? "unknown"
    }
    
    private func getNetworkType() -> String {
        // 네트워크 타입 감지 (WiFi, Cellular, etc.)
        return "wifi" // 실제 구현 필요
    }
    
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
        return 0
    }
    
    private func getCPUUsage() -> Double {
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
            return Double(info.virtual_size) / Double(info.resident_size) * 100
        }
        return 0
    }
    
    private func getAverageScreenLoadTime() -> TimeInterval {
        // 화면 로드 시간 계산
        return 0.5 // 실제 구현 필요
    }
    
    private func getAverageNetworkLatency() -> TimeInterval {
        // 네트워크 지연시간 계산
        return 0.2 // 실제 구현 필요
    }
    
    private func getCrashFreeRate() -> Double {
        // 크래시 없는 세션 비율 계산
        return 99.5 // 실제 구현 필요
    }
    
    private func getActiveUsersCount() -> Int {
        // 활성 사용자 수 계산
        return 1 // 실제 구현 필요
    }
    
    private func getCurrentSessionDuration() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    private func getScreensViewedCount() -> Int {
        return UserDefaults.standard.integer(forKey: "screensViewedInSession")
    }
    
    private func getActionsPerformedCount() -> Int {
        return UserDefaults.standard.integer(forKey: "actionsPerformedInSession")
    }
}

// MARK: - 이벤트 데이터 구조
private struct AnalyticsEventData {
    let event: AnalyticsEvent
    let parameters: [String: Any]
    let timestamp: Date
}

// MARK: - SwiftUI 확장
extension View {
    func trackScreenView(_ screenName: String, parameters: [String: Any] = [:]) -> some View {
        self.onAppear {
            AnalyticsManager.shared.logScreenView(screenName, parameters: parameters)
        }
    }
    
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any] = [:]) -> some View {
        self.onTapGesture {
            AnalyticsManager.shared.logEvent(event, parameters: parameters)
        }
    }
}
