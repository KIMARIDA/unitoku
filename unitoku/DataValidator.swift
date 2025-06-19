import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - 데이터 검증 유틸리티
class DataValidator {
    static let shared = DataValidator()
    
    private init() {}
    
    // MARK: - 기본 검증 규칙
    struct ValidationRules {
        static let minPasswordLength = 8
        static let maxPasswordLength = 50
        static let minNameLength = 2
        static let maxNameLength = 50
        static let maxPostTitleLength = 200
        static let maxPostContentLength = 10000
        static let maxCommentLength = 1000
        static let maxCourseEvaluationCommentLength = 1000
        static let minEvaluationScore = 1
        static let maxEvaluationScore = 5
        static let maxImageSizeMB = 10
        static let allowedImageTypes = ["jpg", "jpeg", "png", "gif"]
        static let maxImagesPerPost = 5
    }
    
    // MARK: - 이메일 검증
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            return .failure("이메일을 입력해주세요.")
        }
        
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return .failure("올바른 이메일 형식이 아닙니다.")
        }
        
        // 대학 이메일 도메인 검증 (선택사항)
        let allowedDomains = ["ac.kr", "edu", "university.ac.kr"]
        let isUniversityEmail = allowedDomains.contains { domain in
            trimmedEmail.lowercased().contains(domain)
        }
        
        if !isUniversityEmail {
            return .warning("대학 이메일 사용을 권장합니다.")
        }
        
        return .success
    }
    
    // MARK: - 비밀번호 검증
    func validatePassword(_ password: String) -> ValidationResult {
        if password.isEmpty {
            return .failure("비밀번호를 입력해주세요.")
        }
        
        if password.count < ValidationRules.minPasswordLength {
            return .failure("비밀번호는 최소 \(ValidationRules.minPasswordLength)자 이상이어야 합니다.")
        }
        
        if password.count > ValidationRules.maxPasswordLength {
            return .failure("비밀번호는 최대 \(ValidationRules.maxPasswordLength)자까지 가능합니다.")
        }
        
        // 복잡성 검증
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChars = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        
        var score = 0
        if hasUppercase { score += 1 }
        if hasLowercase { score += 1 }
        if hasNumbers { score += 1 }
        if hasSpecialChars { score += 1 }
        
        if score < 3 {
            return .failure("비밀번호는 대문자, 소문자, 숫자, 특수문자 중 3가지 이상을 포함해야 합니다.")
        }
        
        return .success
    }
    
    // MARK: - 사용자 이름 검증
    func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .failure("이름을 입력해주세요.")
        }
        
        if trimmedName.count < ValidationRules.minNameLength {
            return .failure("이름은 최소 \(ValidationRules.minNameLength)자 이상이어야 합니다.")
        }
        
        if trimmedName.count > ValidationRules.maxNameLength {
            return .failure("이름은 최대 \(ValidationRules.maxNameLength)자까지 가능합니다.")
        }
        
        // 특수문자 검증
        let allowedCharacterSet = CharacterSet.letters.union(.decimalDigits).union(.whitespaces)
        if trimmedName.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
            return .failure("이름에는 문자, 숫자, 공백만 사용할 수 있습니다.")
        }
        
        // 부적절한 단어 검증
        if containsInappropriateContent(trimmedName) {
            return .failure("부적절한 내용이 포함되어 있습니다.")
        }
        
        return .success
    }
    
    // MARK: - 게시글 제목 검증
    func validatePostTitle(_ title: String) -> ValidationResult {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            return .failure("제목을 입력해주세요.")
        }
        
        if trimmedTitle.count > ValidationRules.maxPostTitleLength {
            return .failure("제목은 최대 \(ValidationRules.maxPostTitleLength)자까지 가능합니다.")
        }
        
        // 부적절한 내용 검증
        if containsInappropriateContent(trimmedTitle) {
            return .failure("제목에 부적절한 내용이 포함되어 있습니다.")
        }
        
        // 스팸 패턴 검증
        if isSpamContent(trimmedTitle) {
            return .failure("스팸으로 의심되는 내용입니다.")
        }
        
        return .success
    }
    
    // MARK: - 게시글 내용 검증
    func validatePostContent(_ content: String) -> ValidationResult {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedContent.isEmpty {
            return .failure("내용을 입력해주세요.")
        }
        
        if trimmedContent.count > ValidationRules.maxPostContentLength {
            return .failure("내용은 최대 \(ValidationRules.maxPostContentLength)자까지 가능합니다.")
        }
        
        // 부적절한 내용 검증
        if containsInappropriateContent(trimmedContent) {
            return .failure("내용에 부적절한 내용이 포함되어 있습니다.")
        }
        
        // 스팸 패턴 검증
        if isSpamContent(trimmedContent) {
            return .failure("스팸으로 의심되는 내용입니다.")
        }
        
        // 광고성 내용 검증
        if containsAdvertisement(trimmedContent) {
            return .warning("광고성 내용이 포함되어 있을 수 있습니다.")
        }
        
        return .success
    }
    
    // MARK: - 댓글 검증
    func validateComment(_ comment: String) -> ValidationResult {
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedComment.isEmpty {
            return .failure("댓글을 입력해주세요.")
        }
        
        if trimmedComment.count > ValidationRules.maxCommentLength {
            return .failure("댓글은 최대 \(ValidationRules.maxCommentLength)자까지 가능합니다.")
        }
        
        // 부적절한 내용 검증
        if containsInappropriateContent(trimmedComment) {
            return .failure("댓글에 부적절한 내용이 포함되어 있습니다.")
        }
        
        return .success
    }
    
    // MARK: - 강의평가 점수 검증
    func validateEvaluationScore(_ score: Int) -> ValidationResult {
        if score < ValidationRules.minEvaluationScore || score > ValidationRules.maxEvaluationScore {
            return .failure("평점은 \(ValidationRules.minEvaluationScore)점부터 \(ValidationRules.maxEvaluationScore)점까지 가능합니다.")
        }
        
        return .success
    }
    
    // MARK: - 강의평가 댓글 검증
    func validateEvaluationComment(_ comment: String) -> ValidationResult {
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedComment.count > ValidationRules.maxCourseEvaluationCommentLength {
            return .failure("강의평가 댓글은 최대 \(ValidationRules.maxCourseEvaluationCommentLength)자까지 가능합니다.")
        }
        
        // 부적절한 내용 검증
        if containsInappropriateContent(trimmedComment) {
            return .failure("강의평가에 부적절한 내용이 포함되어 있습니다.")
        }
        
        // 개인정보 포함 여부 검증
        if containsPersonalInfo(trimmedComment) {
            return .failure("개인정보가 포함되어 있습니다. 익명성을 위해 제거해주세요.")
        }
        
        return .success
    }
    
    // MARK: - 이미지 검증
    func validateImage(_ imageData: Data, fileName: String) -> ValidationResult {
        // 파일 크기 검증
        let sizeInMB = Double(imageData.count) / (1024 * 1024)
        if sizeInMB > Double(ValidationRules.maxImageSizeMB) {
            return .failure("이미지 크기는 최대 \(ValidationRules.maxImageSizeMB)MB까지 가능합니다.")
        }
        
        // 파일 확장자 검증
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        if !ValidationRules.allowedImageTypes.contains(fileExtension) {
            return .failure("지원하지 않는 이미지 형식입니다. (\(ValidationRules.allowedImageTypes.joined(separator: ", "))만 가능)")
        }
        
        // 이미지 유효성 검증
        #if canImport(UIKit)
        guard UIImage(data: imageData) != nil else {
            return .failure("유효하지 않은 이미지 파일입니다.")
        }
        #endif
        
        return .success
    }
    
    // MARK: - 개인정보 검증
    private func containsPersonalInfo(_ text: String) -> Bool {
        let patterns = [
            "\\d{3}-\\d{4}-\\d{4}",     // 전화번호 패턴
            "\\d{6}-\\d{7}",           // 주민등록번호 패턴
            "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", // 이메일 패턴
            "\\d{4}-\\d{4}-\\d{4}-\\d{4}" // 카드번호 패턴
        ]
        
        return patterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }
    
    // MARK: - 부적절한 내용 검증
    private func containsInappropriateContent(_ text: String) -> Bool {
        let inappropriateWords = [
            // 욕설 및 비속어
            "바보", "멍청", "씨발", "개새끼", "좆", "병신",
            // 차별적 표현
            "김치녀", "한남", "급식충",
            // 기타 부적절한 표현
            "죽어", "꺼져", "닥쳐"
        ]
        
        let lowercaseText = text.lowercased()
        return inappropriateWords.contains { word in
            lowercaseText.contains(word.lowercased())
        }
    }
    
    // MARK: - 스팸 패턴 검증
    private func isSpamContent(_ text: String) -> Bool {
        let spamPatterns = [
            "돈벌기", "부업", "알바", "쉬운돈", "무료", "공짜",
            "클릭", "링크", "www.", "http", "bit.ly",
            "카톡", "텔레그램", "라인", "연락처"
        ]
        
        let lowercaseText = text.lowercased()
        let spamCount = spamPatterns.filter { pattern in
            lowercaseText.contains(pattern.lowercased())
        }.count
        
        // 2개 이상의 스팸 키워드가 있으면 스팸으로 판단
        return spamCount >= 2
    }
    
    // MARK: - 광고성 내용 검증
    private func containsAdvertisement(_ text: String) -> Bool {
        let adKeywords = [
            "판매", "구매", "가격", "할인", "이벤트", "상품",
            "쇼핑", "마케팅", "광고", "홍보", "업체"
        ]
        
        let lowercaseText = text.lowercased()
        let adCount = adKeywords.filter { keyword in
            lowercaseText.contains(keyword.lowercased())
        }.count
        
        return adCount >= 2
    }
}

// MARK: - 검증 결과 열거형
enum ValidationResult: Equatable {
    case success
    case warning(String)
    case failure(String)
    
    var isValid: Bool {
        switch self {
        case .success, .warning:
            return true
        case .failure:
            return false
        }
    }
    
    var message: String? {
        switch self {
        case .success:
            return nil
        case .warning(let message), .failure(let message):
            return message
        }
    }
}

// MARK: - 실시간 검증을 위한 SwiftUI 확장
extension View {
    func validateOnChange<T: Equatable>(
        _ value: T,
        validator: @escaping (T) -> ValidationResult,
        onValidation: @escaping (ValidationResult) -> Void
    ) -> some View {
        self.onChange(of: value) { _, newValue in
            let result = validator(newValue)
            onValidation(result)
        }
    }
}
