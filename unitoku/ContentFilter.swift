import Foundation

// MARK: - 고급 콘텐츠 필터링 클래스
class ContentFilter {
    static let shared = ContentFilter()
    
    private init() {
        loadFilteringData()
    }
    
    // MARK: - 필터링 데이터
    private var bannedWords: Set<String> = []
    private var spamPatterns: [String] = []
    private var allowedDomains: Set<String> = []
    private var suspiciousPatterns: [NSRegularExpression] = []
    
    // MARK: - 필터링 설정
    struct FilterSettings {
        static let strictMode = true
        static let autoModerate = true
        static let logViolations = true
        static let maxViolationsPerUser = 3
        static let temporaryBanDuration: TimeInterval = 24 * 60 * 60 // 24시간
    }
    
    // MARK: - 필터링 결과
    struct FilterResult {
        let isClean: Bool
        let violationType: ViolationType?
        let filteredContent: String
        let confidence: Double // 0.0 ~ 1.0
        let suggestions: [String]
        
        enum ViolationType {
            case profanity
            case spam
            case personalInfo
            case advertisement
            case harassment
            case inappropriateContent
            case maliciousLink
        }
    }
    
    // MARK: - 메인 필터링 함수
    func filterContent(_ content: String, context: ContentContext = .general) -> FilterResult {
        let originalContent = content
        var filteredContent = content
        var violations: [FilterResult.ViolationType] = []
        var confidence: Double = 0.0
        var suggestions: [String] = []
        
        // 1. 욕설 및 비속어 필터링
        let profanityResult = filterProfanity(filteredContent)
        if !profanityResult.isClean {
            violations.append(.profanity)
            filteredContent = profanityResult.filteredContent
            confidence = max(confidence, profanityResult.confidence)
            suggestions.append(contentsOf: profanityResult.suggestions)
        }
        
        // 2. 스팸 패턴 검증
        let spamResult = detectSpam(content, context: context)
        if !spamResult.isClean {
            violations.append(.spam)
            confidence = max(confidence, spamResult.confidence)
            suggestions.append(contentsOf: spamResult.suggestions)
        }
        
        // 3. 개인정보 검증
        let personalInfoResult = detectPersonalInfo(content)
        if !personalInfoResult.isClean {
            violations.append(.personalInfo)
            filteredContent = personalInfoResult.filteredContent
            confidence = max(confidence, personalInfoResult.confidence)
            suggestions.append(contentsOf: personalInfoResult.suggestions)
        }
        
        // 4. 광고성 내용 검증
        let adResult = detectAdvertisement(content, context: context)
        if !adResult.isClean {
            violations.append(.advertisement)
            confidence = max(confidence, adResult.confidence)
            suggestions.append(contentsOf: adResult.suggestions)
        }
        
        // 5. 괴롭힘 및 혐오 표현 검증
        let harassmentResult = detectHarassment(content)
        if !harassmentResult.isClean {
            violations.append(.harassment)
            confidence = max(confidence, harassmentResult.confidence)
            suggestions.append(contentsOf: harassmentResult.suggestions)
        }
        
        // 6. 악성 링크 검증
        let linkResult = detectMaliciousLinks(content)
        if !linkResult.isClean {
            violations.append(.maliciousLink)
            filteredContent = linkResult.filteredContent
            confidence = max(confidence, linkResult.confidence)
            suggestions.append(contentsOf: linkResult.suggestions)
        }
        
        let primaryViolation = violations.first
        let isClean = violations.isEmpty
        
        // 로깅
        if FilterSettings.logViolations && !isClean {
            logViolation(originalContent: originalContent, violations: violations, confidence: confidence)
        }
        
        return FilterResult(
            isClean: isClean,
            violationType: primaryViolation,
            filteredContent: filteredContent,
            confidence: confidence,
            suggestions: Array(Set(suggestions)) // 중복 제거
        )
    }
    
    // MARK: - 욕설 필터링
    private func filterProfanity(_ content: String) -> (isClean: Bool, filteredContent: String, confidence: Double, suggestions: [String]) {
        var filteredContent = content
        var violations = 0
        let totalWords = content.components(separatedBy: .whitespacesAndNewlines).count
        
        for bannedWord in bannedWords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: bannedWord))\\b"
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(content.startIndex..., in: content)
            
            if let matches = regex?.numberOfMatches(in: content, options: [], range: range), matches > 0 {
                violations += matches
                let replacement = String(repeating: "*", count: bannedWord.count)
                filteredContent = regex?.stringByReplacingMatches(
                    in: filteredContent,
                    options: [],
                    range: NSRange(filteredContent.startIndex..., in: filteredContent),
                    withTemplate: replacement
                ) ?? filteredContent
            }
        }
        
        let confidence = min(1.0, Double(violations) / Double(max(1, totalWords)) * 10)
        let suggestions = violations > 0 ? ["더 정중한 표현을 사용해주세요.", "건전한 언어 사용을 권장합니다."] : []
        
        return (isClean: violations == 0, filteredContent: filteredContent, confidence: confidence, suggestions: suggestions)
    }
    
    // MARK: - 스팸 검증
    private func detectSpam(_ content: String, context: ContentContext) -> (isClean: Bool, confidence: Double, suggestions: [String]) {
        var spamScore = 0.0
        var detectedPatterns: [String] = []
        
        // 연속된 같은 문자 검사
        let repeatedCharPattern = try? NSRegularExpression(pattern: "(.)\\1{4,}", options: [])
        if let matches = repeatedCharPattern?.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)), matches > 0 {
            spamScore += 0.3
            detectedPatterns.append("연속된 문자 반복")
        }
        
        // 과도한 이모지 사용
        let emojiPattern = try? NSRegularExpression(pattern: "[\\u{1F600}-\\u{1F64F}\\u{1F300}-\\u{1F5FF}\\u{1F680}-\\u{1F6FF}\\u{1F1E0}-\\u{1F1FF}]", options: [])
        if let emojiMatches = emojiPattern?.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)) {
            let emojiRatio = Double(emojiMatches) / Double(content.count)
            if emojiRatio > 0.2 {
                spamScore += 0.2
                detectedPatterns.append("과도한 이모지 사용")
            }
        }
        
        // 외부 링크 검사
        let urlPattern = try? NSRegularExpression(pattern: "https?://[^\\s]+", options: [])
        if let urlMatches = urlPattern?.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)), urlMatches > 2 {
            spamScore += 0.4
            detectedPatterns.append("과도한 링크 포함")
        }
        
        // 스팸 키워드 검사
        let spamKeywords = ["무료", "공짜", "돈벌기", "클릭", "광고", "홍보", "마케팅"]
        let lowercaseContent = content.lowercased()
        let spamKeywordCount = spamKeywords.filter { lowercaseContent.contains($0) }.count
        
        if spamKeywordCount >= 2 {
            spamScore += 0.3
            detectedPatterns.append("스팸 키워드 다수 포함")
        }
        
        let confidence = min(1.0, spamScore)
        let isClean = confidence < 0.5
        
        let suggestions = !isClean ? [
            "스팸으로 의심되는 내용을 제거해주세요.",
            "더 자연스러운 표현을 사용해주세요.",
            "과도한 링크나 반복 표현을 피해주세요."
        ] : []
        
        return (isClean: isClean, confidence: confidence, suggestions: suggestions)
    }
    
    // MARK: - 개인정보 검증
    private func detectPersonalInfo(_ content: String) -> (isClean: Bool, filteredContent: String, confidence: Double, suggestions: [String]) {
        var filteredContent = content
        var violations = 0
        var detectedTypes: [String] = []
        
        // 전화번호 패턴
        let phonePatterns = [
            "\\d{3}-\\d{4}-\\d{4}",  // 010-1234-5678
            "\\d{3}\\d{4}\\d{4}",    // 01012345678
            "\\d{2,3}-\\d{3,4}-\\d{4}" // 02-123-4567
        ]
        
        for pattern in phonePatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            if let matches = regex?.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)), matches > 0 {
                violations += matches
                detectedTypes.append("전화번호")
                filteredContent = regex?.stringByReplacingMatches(
                    in: filteredContent,
                    options: [],
                    range: NSRange(filteredContent.startIndex..., in: filteredContent),
                    withTemplate: "[전화번호]"
                ) ?? filteredContent
            }
        }
        
        // 이메일 패턴
        let emailPattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
        let emailRegex = try? NSRegularExpression(pattern: emailPattern, options: [])
        if let emailMatches = emailRegex?.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)), emailMatches > 0 {
            violations += emailMatches
            detectedTypes.append("이메일")
            filteredContent = emailRegex?.stringByReplacingMatches(
                in: filteredContent,
                options: [],
                range: NSRange(filteredContent.startIndex..., in: filteredContent),
                withTemplate: "[이메일]"
            ) ?? filteredContent
        }
        
        // 주민등록번호 패턴
        let ssnPattern = "\\d{6}-[1-4]\\d{6}"
        let ssnRegex = try? NSRegularExpression(pattern: ssnPattern, options: [])
        if let ssnMatches = ssnRegex?.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)), ssnMatches > 0 {
            violations += ssnMatches * 3 // 주민등록번호는 더 심각
            detectedTypes.append("주민등록번호")
            filteredContent = ssnRegex?.stringByReplacingMatches(
                in: filteredContent,
                options: [],
                range: NSRange(filteredContent.startIndex..., in: filteredContent),
                withTemplate: "[개인식별정보]"
            ) ?? filteredContent
        }
        
        let confidence = violations > 0 ? 1.0 : 0.0
        let isClean = violations == 0
        
        let suggestions = !isClean ? [
            "개인정보가 포함되어 있습니다. 개인정보 보호를 위해 제거해주세요.",
            "익명성 보장을 위해 개인 연락처는 포함하지 마세요.",
            "안전한 소통을 위해 개인정보를 공유하지 마세요."
        ] : []
        
        return (isClean: isClean, filteredContent: filteredContent, confidence: confidence, suggestions: suggestions)
    }
    
    // MARK: - 광고 검증
    private func detectAdvertisement(_ content: String, context: ContentContext) -> (isClean: Bool, confidence: Double, suggestions: [String]) {
        let adKeywords = [
            "판매", "구매", "할인", "이벤트", "프로모션", "쿠폰",
            "마케팅", "광고", "홍보", "업체", "상품", "서비스",
            "가격", "구입", "주문", "배송", "결제"
        ]
        
        let commercialPhrases = [
            "지금 주문하면", "특가 할인", "무료 배송", "한정 특가",
            "최저가", "할인가", "이벤트 가격", "특별가"
        ]
        
        let lowercaseContent = content.lowercased()
        
        let keywordCount = adKeywords.filter { lowercaseContent.contains($0) }.count
        let phraseCount = commercialPhrases.filter { phrase in
            lowercaseContent.contains(phrase.lowercased())
        }.count
        
        // 연락처 정보와 함께 나타나는 경우 광고 가능성 증가
        let hasContactInfo = lowercaseContent.contains("연락") || 
                           lowercaseContent.contains("문의") ||
                           lowercaseContent.contains("카톡") ||
                           lowercaseContent.contains("텔레그램")
        
        var adScore = 0.0
        
        if keywordCount >= 2 {
            adScore += 0.3
        }
        
        if phraseCount >= 1 {
            adScore += 0.4
        }
        
        if hasContactInfo && keywordCount >= 1 {
            adScore += 0.5
        }
        
        // 컨텍스트별 조정
        switch context {
        case .courseEvaluation:
            adScore *= 0.5 // 강의평가에서는 덜 엄격
        case .chat:
            adScore *= 1.2 // 채팅에서는 더 엄격
        case .general, .profile:
            break
        }
        
        let confidence = min(1.0, adScore)
        let isClean = confidence < 0.6
        
        let suggestions = !isClean ? [
            "광고성 내용으로 의심됩니다.",
            "학술적이고 건전한 내용으로 작성해주세요.",
            "상업적 목적의 게시글은 제한됩니다."
        ] : []
        
        return (isClean: isClean, confidence: confidence, suggestions: suggestions)
    }
    
    // MARK: - 괴롭힘 검증
    private func detectHarassment(_ content: String) -> (isClean: Bool, confidence: Double, suggestions: [String]) {
        let harassmentWords = [
            "죽어", "꺼져", "닥쳐", "때려", "죽일", "싫어",
            "혐오", "차별", "왕따", "괴롭", "무시"
        ]
        
        let threateningPhrases = [
            "죽여버리", "때려주", "혼내주", "가만안둬", "복수"
        ]
        
        let lowercaseContent = content.lowercased()
        
        let harassmentCount = harassmentWords.filter { lowercaseContent.contains($0) }.count
        let threatCount = threateningPhrases.filter { phrase in
            lowercaseContent.contains(phrase.lowercased())
        }.count
        
        var harassmentScore = 0.0
        
        if harassmentCount >= 1 {
            harassmentScore += 0.4
        }
        
        if threatCount >= 1 {
            harassmentScore += 0.6
        }
        
        // 반복되는 부정적 표현
        let negativePattern = try? NSRegularExpression(pattern: "(싫|혐|죽|때)", options: .caseInsensitive)
        if let negativeMatches = negativePattern?.numberOfMatches(in: content, options: [], range: NSRange(content.startIndex..., in: content)), negativeMatches >= 3 {
            harassmentScore += 0.3
        }
        
        let confidence = min(1.0, harassmentScore)
        let isClean = confidence < 0.5
        
        let suggestions = !isClean ? [
            "괴롭힘이나 위협적인 내용이 포함되어 있습니다.",
            "존중하는 언어를 사용해주세요.",
            "건전한 토론 문화를 위해 협조해주세요."
        ] : []
        
        return (isClean: isClean, confidence: confidence, suggestions: suggestions)
    }
    
    // MARK: - 악성 링크 검증
    private func detectMaliciousLinks(_ content: String) -> (isClean: Bool, filteredContent: String, confidence: Double, suggestions: [String]) {
        var filteredContent = content
        var suspiciousCount = 0
        
        // 의심스러운 도메인 패턴
        let suspiciousDomains = [
            "bit\\.ly", "tinyurl", "t\\.co", "goo\\.gl", // 단축 URL
            "\\.tk", "\\.ml", "\\.ga", "\\.cf", // 무료 도메인
            "\\d+\\.\\d+\\.\\d+\\.\\d+" // IP 주소
        ]
        
        let urlPattern = "(https?://[^\\s]+)"
        let urlRegex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive)
        
        if let urlRegex = urlRegex {
            let matches = urlRegex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
            
            for match in matches {
                if let urlRange = Range(match.range, in: content) {
                    let url = String(content[urlRange])
                    
                    // 허용된 도메인 체크
                    let isAllowed = allowedDomains.contains { domain in
                        url.lowercased().contains(domain.lowercased())
                    }
                    
                    if !isAllowed {
                        // 의심스러운 도메인 체크
                        let isSuspicious = suspiciousDomains.contains { pattern in
                            url.range(of: pattern, options: .regularExpression) != nil
                        }
                        
                        if isSuspicious {
                            suspiciousCount += 1
                            filteredContent = filteredContent.replacingOccurrences(of: url, with: "[의심스러운 링크]")
                        }
                    }
                }
            }
        }
        
        let confidence = suspiciousCount > 0 ? 0.8 : 0.0
        let isClean = suspiciousCount == 0
        
        let suggestions = !isClean ? [
            "의심스러운 링크가 포함되어 있습니다.",
            "신뢰할 수 있는 링크만 공유해주세요.",
            "안전한 사이트 링크를 사용해주세요."
        ] : []
        
        return (isClean: isClean, filteredContent: filteredContent, confidence: confidence, suggestions: suggestions)
    }
    
    // MARK: - 데이터 로딩
    private func loadFilteringData() {
        // 금지 단어 목록 로드
        bannedWords = [
            // 욕설
            "씨발", "개새끼", "좆", "병신", "미친", "또라이",
            "바보", "멍청", "개놈", "년", "썅", "시발",
            
            // 차별적 표현
            "김치녀", "한남", "급식충", "틀딱", "개저씨",
            
            // 혐오 표현
            "죽어", "꺼져", "닥쳐", "때려", "혐오"
        ]
        
        // 허용된 도메인 목록
        allowedDomains = [
            "naver.com", "google.com", "youtube.com", "github.com",
            "stackoverflow.com", "wikipedia.org", "ac.kr", "edu"
        ]
        
        // 의심스러운 패턴 생성
        suspiciousPatterns = [
            try? NSRegularExpression(pattern: "(.{1,3})\\1{5,}", options: []), // 짧은 패턴 반복
            try? NSRegularExpression(pattern: "[A-Z]{10,}", options: []),      // 연속 대문자
            try? NSRegularExpression(pattern: "\\d{10,}", options: [])         // 연속 숫자
        ].compactMap { $0 }
    }
    
    // MARK: - 로깅
    private func logViolation(originalContent: String, violations: [FilterResult.ViolationType], confidence: Double) {
        let timestamp = Date()
        let violationTypes = violations.map { "\($0)" }.joined(separator: ", ")
        
        print("🚨 [ContentFilter] Violation detected at \(timestamp)")
        print("   Types: \(violationTypes)")
        print("   Confidence: \(String(format: "%.2f", confidence))")
        print("   Content length: \(originalContent.count)")
        
        // 실제 운영에서는 Firebase Analytics나 로깅 서비스로 전송
        // Analytics.logEvent("content_violation", parameters: [...])
    }
}

// MARK: - 컨텍스트 열거형
enum ContentContext {
    case general
    case courseEvaluation
    case chat
    case profile
}
