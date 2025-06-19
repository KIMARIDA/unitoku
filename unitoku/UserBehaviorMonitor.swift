import Foundation
import Combine

// MARK: - 사용자 행동 모니터링 클래스
class UserBehaviorMonitor: ObservableObject {
    static let shared = UserBehaviorMonitor()
    
    // MARK: - 모니터링 데이터
    @Published var riskLevel: RiskLevel = .low
    @Published var trustScore: Double = 1.0 // 0.0 ~ 1.0
    @Published var isUnderReview = false
    
    private var behaviorHistory: [BehaviorEvent] = []
    private var violationHistory: [ViolationRecord] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String {
        return UserDefaults.standard.string(forKey: "currentUserId") ?? "anonymous"
    }
    
    // MARK: - 설정
    struct MonitoringSettings {
        static let maxViolationsPerDay = 5
        static let maxPostsPerHour = 10
        static let maxCommentsPerHour = 20
        static let suspiciousPostInterval: TimeInterval = 60 // 1분 이내 연속 게시 제한
        static let temporaryBanDuration: TimeInterval = 24 * 60 * 60 // 24시간
        static let reviewThreshold: Double = 0.3 // 신뢰도 0.3 이하 시 검토
    }
    
    private init() {
        loadUserHistory()
        setupPeriodicCleanup()
    }
    
    // MARK: - 행동 기록
    func recordBehavior(_ behavior: BehaviorType, metadata: [String: Any] = [:]) {
        // Any 타입을 String으로 변환
        let stringMetadata = metadata.compactMapValues { value -> String? in
            if let stringValue = value as? String {
                return stringValue
            } else {
                return String(describing: value)
            }
        }
        
        let event = BehaviorEvent(
            id: UUID(),
            userId: currentUserId,
            type: behavior,
            timestamp: Date(),
            metadata: stringMetadata
        )
        
        behaviorHistory.append(event)
        
        // 실시간 분석
        analyzeRecentBehavior()
        
        // 이상 행동 감지
        if let violation = detectAnomalousActivity(event) {
            recordViolation(violation)
        }
        
        // 신뢰도 업데이트
        updateTrustScore()
        
        // 로컬 저장
        saveUserHistory()
    }
    
    // MARK: - 위반 기록
    func recordViolation(_ violation: ViolationRecord) {
        violationHistory.append(violation)
        
        // 위험도 계산
        calculateRiskLevel()
        
        // 자동 조치 결정
        if shouldTakeAutomaticAction(violation) {
            executeAutomaticAction(violation)
        }
        
        // 관리자 알림
        if violation.severity >= .high {
            notifyModerators(violation)
        }
        
        saveUserHistory()
    }
    
    // MARK: - 게시 전 검증
    func canUserPost() -> PostPermissionResult {
        let recentPosts = getRecentBehaviors(.postCreate, within: .hour)
        _ = getRecentBehaviors(.commentCreate, within: .hour) // 사용하지 않는 변수
        let recentViolations = getRecentViolations(within: .day)
        
        // 시간당 게시 제한 확인
        if recentPosts.count >= MonitoringSettings.maxPostsPerHour {
            return .denied("시간당 게시 한도를 초과했습니다. 잠시 후 다시 시도해주세요.")
        }
        
        // 연속 게시 간격 확인
        if let lastPost = recentPosts.first,
           Date().timeIntervalSince(lastPost.timestamp) < MonitoringSettings.suspiciousPostInterval {
            return .warning("너무 빠른 게시입니다. 잠시 후 다시 시도해주세요.")
        }
        
        // 일일 위반 한도 확인
        if recentViolations.count >= MonitoringSettings.maxViolationsPerDay {
            return .denied("일일 위반 한도를 초과했습니다. 내일 다시 시도해주세요.")
        }
        
        // 신뢰도 기반 제한
        if trustScore < 0.2 {
            return .restricted("계정 검토 중입니다. 고객센터에 문의해주세요.")
        } else if trustScore < 0.5 {
            return .warning("주의: 부적절한 활동이 감지되었습니다.")
        }
        
        return .allowed
    }
    
    // MARK: - 댓글 작성 권한 확인
    func canUserComment() -> PostPermissionResult {
        let recentComments = getRecentBehaviors(.commentCreate, within: .hour)
        let recentViolations = getRecentViolations(within: .day)
        
        if recentComments.count >= MonitoringSettings.maxCommentsPerHour {
            return .denied("시간당 댓글 한도를 초과했습니다.")
        }
        
        if recentViolations.count >= MonitoringSettings.maxViolationsPerDay {
            return .denied("일일 위반 한도를 초과했습니다.")
        }
        
        if trustScore < 0.3 {
            return .restricted("계정 검토 중입니다.")
        }
        
        return .allowed
    }
    
    // MARK: - 사용자 상태 정보
    func getUserStatus() -> UserStatus {
        let recentViolations = getRecentViolations(within: .week)
        let totalPosts = behaviorHistory.filter { $0.type == .postCreate }.count
        let totalComments = behaviorHistory.filter { $0.type == .commentCreate }.count
        
        return UserStatus(
            trustScore: trustScore,
            riskLevel: riskLevel,
            recentViolations: recentViolations.count,
            totalPosts: totalPosts,
            totalComments: totalComments,
            accountAge: getAccountAge(),
            lastActivity: behaviorHistory.last?.timestamp ?? Date(),
            isUnderReview: isUnderReview
        )
    }
    
    // MARK: - 이상 행동 감지
    private func detectAnomalousActivity(_ event: BehaviorEvent) -> ViolationRecord? {
        // 스팸 행동 패턴 감지
        if detectSpamPattern(event) {
            return ViolationRecord(
                id: UUID(),
                userId: currentUserId,
                type: .spamBehavior,
                severity: .medium,
                description: "스팸 행동 패턴 감지",
                timestamp: Date(),
                relatedEventId: event.id
            )
        }
        
        // 비정상적 활동 시간 감지
        if detectAbnormalActivityTime(event) {
            return ViolationRecord(
                id: UUID(),
                userId: currentUserId,
                type: .abnormalActivity,
                severity: .low,
                description: "비정상적 활동 시간 감지",
                timestamp: Date(),
                relatedEventId: event.id
            )
        }
        
        // 중복 콘텐츠 감지
        if detectDuplicateContent(event) {
            return ViolationRecord(
                id: UUID(),
                userId: currentUserId,
                type: .duplicateContent,
                severity: .medium,
                description: "중복 콘텐츠 감지",
                timestamp: Date(),
                relatedEventId: event.id
            )
        }
        
        return nil
    }
    
    // MARK: - 스팸 패턴 감지
    private func detectSpamPattern(_ event: BehaviorEvent) -> Bool {
        let recentEvents = getRecentBehaviors(event.type, within: .minute(10))
        
        // 10분 내 동일한 행동 반복
        if recentEvents.count >= 5 {
            return true
        }
        
        // 비슷한 내용의 반복 게시
        if event.type == .postCreate || event.type == .commentCreate {
            let recentContent = recentEvents.compactMap { $0.metadata["content"] }
            if let currentContent = event.metadata["content"] {
                let similarCount = recentContent.filter { content in
                    calculateSimilarity(currentContent, content) > 0.8
                }.count
                
                return similarCount >= 2
            }
        }
        
        return false
    }
    
    // MARK: - 비정상적 활동 시간 감지
    private func detectAbnormalActivityTime(_ event: BehaviorEvent) -> Bool {
        let hour = Calendar.current.component(.hour, from: event.timestamp)
        
        // 새벽 2시~6시 사이의 과도한 활동
        if (2...6).contains(hour) {
            let recentNightActivity = behaviorHistory.filter { behavior in
                let behaviorHour = Calendar.current.component(.hour, from: behavior.timestamp)
                return (2...6).contains(behaviorHour) &&
                       behavior.timestamp.timeIntervalSince(Date()) > -3600 // 1시간 내
            }
            
            return recentNightActivity.count >= 10
        }
        
        return false
    }
    
    // MARK: - 중복 콘텐츠 감지
    private func detectDuplicateContent(_ event: BehaviorEvent) -> Bool {
        guard let content = event.metadata["content"],
              !content.isEmpty else { return false }
        
        let recentPosts = getRecentBehaviors(.postCreate, within: .day)
        let duplicateCount = recentPosts.filter { behavior in
            guard let otherContent = behavior.metadata["content"] else { return false }
            return calculateSimilarity(content, otherContent) > 0.9
        }.count
        
        return duplicateCount >= 2
    }
    
    // MARK: - 신뢰도 계산
    private func updateTrustScore() {
        let recentViolations = getRecentViolations(within: .week)
        let totalActivity = behaviorHistory.filter { $0.timestamp.timeIntervalSince(Date()) > -7*24*3600 }.count
        
        var score = 1.0
        
        // 위반 기록에 따른 감점
        for violation in recentViolations {
            switch violation.severity {
            case .low:
                score -= 0.05
            case .medium:
                score -= 0.15
            case .high:
                score -= 0.3
            case .critical:
                score -= 0.5
            }
        }
        
        // 활동량에 따른 보정
        if totalActivity < 5 {
            score *= 0.8 // 비활성 사용자 페널티
        } else if totalActivity > 100 {
            score *= 0.9 // 과도한 활성 사용자 페널티
        }
        
        // 계정 연령에 따른 보정
        let accountAge = getAccountAge()
        if accountAge < 7 { // 7일 미만 신규 계정
            score *= 0.7
        }
        
        trustScore = max(0.0, min(1.0, score))
    }
    
    // MARK: - 위험도 계산
    private func calculateRiskLevel() {
        let recentViolations = getRecentViolations(within: .week)
        let criticalViolations = recentViolations.filter { $0.severity == .critical }.count
        let highViolations = recentViolations.filter { $0.severity == .high }.count
        
        if criticalViolations > 0 || trustScore < 0.2 {
            riskLevel = .critical
        } else if highViolations >= 2 || trustScore < 0.4 {
            riskLevel = .high
        } else if recentViolations.count >= 3 || trustScore < 0.6 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }
    }
    
    // MARK: - 자동 조치 실행
    private func shouldTakeAutomaticAction(_ violation: ViolationRecord) -> Bool {
        return violation.severity >= .high || 
               getRecentViolations(within: .day).count >= MonitoringSettings.maxViolationsPerDay
    }
    
    private func executeAutomaticAction(_ violation: ViolationRecord) {
        switch violation.severity {
        case .critical:
            // 즉시 계정 정지
            temporarilyBanUser(duration: MonitoringSettings.temporaryBanDuration * 7) // 7일
            
        case .high:
            // 24시간 제한
            temporarilyBanUser(duration: MonitoringSettings.temporaryBanDuration)
            
        case .medium:
            // 검토 대상으로 표시
            isUnderReview = true
            
        case .low:
            // 경고만 표시
            break
        }
    }
    
    // MARK: - 유틸리티 메서드
    private func getRecentBehaviors(_ type: BehaviorType, within timeFrame: TimeFrame) -> [BehaviorEvent] {
        let cutoffDate = timeFrame.cutoffDate
        return behaviorHistory.filter { 
            $0.type == type && $0.timestamp >= cutoffDate 
        }
    }
    
    private func getRecentViolations(within timeFrame: TimeFrame) -> [ViolationRecord] {
        let cutoffDate = timeFrame.cutoffDate
        return violationHistory.filter { $0.timestamp >= cutoffDate }
    }
    
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func getAccountAge() -> Int {
        // 실제로는 Firebase Auth에서 계정 생성일을 가져와야 함
        let accountCreationDate = UserDefaults.standard.object(forKey: "accountCreationDate") as? Date ?? Date()
        return Calendar.current.dateComponents([.day], from: accountCreationDate, to: Date()).day ?? 0
    }
    
    private func temporarilyBanUser(duration: TimeInterval) {
        let banEndDate = Date().addingTimeInterval(duration)
        UserDefaults.standard.set(banEndDate, forKey: "banEndDate")
        
        // Firebase에도 저장
        // FirebaseManager.shared.setBanStatus(userId: currentUserId, banEndDate: banEndDate)
    }
    
    private func notifyModerators(_ violation: ViolationRecord) {
        // 관리자에게 알림 전송
        print("🚨 High-severity violation detected: \(violation.description)")
        // FirebaseManager.shared.sendModeratorNotification(violation)
    }
    
    private func analyzeRecentBehavior() {
        // 최근 행동 패턴 분석 로직
        let recentEvents = behaviorHistory.filter { 
            $0.timestamp.timeIntervalSince(Date()) > -3600 // 1시간 내
        }
        
        // 패턴 분석 결과에 따른 추가 처리
        if recentEvents.count > 50 {
            print("⚠️ High activity detected for user: \(currentUserId)")
        }
    }
    
    // MARK: - 데이터 저장/로드
    private func saveUserHistory() {
        // 로컬 저장 (Core Data 또는 UserDefaults)
        if let encoded = try? JSONEncoder().encode(behaviorHistory.suffix(1000)) {
            UserDefaults.standard.set(encoded, forKey: "behaviorHistory_\(currentUserId)")
        }
        
        if let violationEncoded = try? JSONEncoder().encode(violationHistory.suffix(100)) {
            UserDefaults.standard.set(violationEncoded, forKey: "violationHistory_\(currentUserId)")
        }
    }
    
    private func loadUserHistory() {
        // 로컬에서 로드
        if let data = UserDefaults.standard.data(forKey: "behaviorHistory_\(currentUserId)"),
           let decoded = try? JSONDecoder().decode([BehaviorEvent].self, from: data) {
            behaviorHistory = decoded
        }
        
        if let violationData = UserDefaults.standard.data(forKey: "violationHistory_\(currentUserId)"),
           let decodedViolations = try? JSONDecoder().decode([ViolationRecord].self, from: violationData) {
            violationHistory = decodedViolations
        }
    }
    
    private func setupPeriodicCleanup() {
        // 24시간마다 오래된 데이터 정리
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            self.cleanupOldData()
        }
    }
    
    private func cleanupOldData() {
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30일 전
        
        behaviorHistory.removeAll { $0.timestamp < cutoffDate }
        violationHistory.removeAll { $0.timestamp < cutoffDate }
        
        saveUserHistory()
    }
}

// MARK: - 데이터 모델들
struct BehaviorEvent: Codable {
    let id: UUID
    let userId: String
    let type: BehaviorType
    let timestamp: Date
    let metadata: [String: String] // Codable을 위해 Any 대신 String 사용
}

struct ViolationRecord: Codable {
    let id: UUID
    let userId: String
    let type: ViolationType
    let severity: ViolationSeverity
    let description: String
    let timestamp: Date
    let relatedEventId: UUID?
}

struct UserStatus {
    let trustScore: Double
    let riskLevel: RiskLevel
    let recentViolations: Int
    let totalPosts: Int
    let totalComments: Int
    let accountAge: Int
    let lastActivity: Date
    let isUnderReview: Bool
}

// MARK: - 열거형들
enum BehaviorType: String, Codable {
    case login
    case logout
    case postCreate
    case postUpdate
    case postDelete
    case commentCreate
    case commentUpdate
    case commentDelete
    case like
    case share
    case report
    case search
    case profileView
    case evaluationCreate
    case chatMessage
}

enum ViolationType: String, Codable {
    case spamBehavior
    case inappropriateContent
    case harassment
    case duplicateContent
    case abnormalActivity
    case securityViolation
}

enum ViolationSeverity: String, Codable, Comparable {
    case low
    case medium
    case high
    case critical
    
    static func < (lhs: ViolationSeverity, rhs: ViolationSeverity) -> Bool {
        let order: [ViolationSeverity] = [.low, .medium, .high, .critical]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

enum RiskLevel: String, Codable {
    case low
    case medium
    case high
    case critical
}

enum PostPermissionResult {
    case allowed
    case warning(String)
    case denied(String)
    case restricted(String)
    
    var isAllowed: Bool {
        switch self {
        case .allowed, .warning:
            return true
        case .denied, .restricted:
            return false
        }
    }
    
    var message: String? {
        switch self {
        case .allowed:
            return nil
        case .warning(let msg), .denied(let msg), .restricted(let msg):
            return msg
        }
    }
}

enum TimeFrame {
    case minute(Int)
    case hour
    case day
    case week
    case month
    
    var cutoffDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .minute(let minutes):
            return calendar.date(byAdding: .minute, value: -minutes, to: now) ?? now
        case .hour:
            return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }
    }
}
