import SwiftUI
import Combine

#if os(iOS)
import UIKit
typealias PlatformTextContentType = UITextContentType
typealias PlatformKeyboardType = UIKeyboardType
#elseif os(macOS)
import AppKit
typealias PlatformTextContentType = Int // macOS에서는 없음
typealias PlatformKeyboardType = Int // macOS에서는 없음
#endif

// MARK: - 검증된 텍스트 필드 컴포넌트
struct ValidatedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let validator: (String) -> ValidationResult
    let contentType: PlatformTextContentType?
    let keyboardType: PlatformKeyboardType
    let isSecure: Bool
    
    @State private var validationResult: ValidationResult = .success
    @State private var showValidation = false
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        validator: @escaping (String) -> ValidationResult,
        contentType: PlatformTextContentType? = nil,
        keyboardType: PlatformKeyboardType = {
            #if os(iOS)
            return .default
            #else
            return 0
            #endif
        }(),
        isSecure: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.validator = validator
        self.contentType = contentType
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // 입력 필드
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(contentType)
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(contentType)
                        .keyboardType(keyboardType)
                }
            }
            .focused($isFocused)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: validationResult)
            
            // 검증 메시지
            if showValidation, let message = validationResult.message {
                HStack {
                    Image(systemName: validationIcon)
                        .foregroundColor(validationColor)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(validationColor)
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // 실시간 문자 수 표시 (필요한 경우)
            if shouldShowCharacterCount {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxCharacterCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: text) { _, newValue in
            validateInput(newValue)
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                showValidation = true
            }
        }
    }
    
    // MARK: - 계산된 속성
    private var borderColor: Color {
        if !showValidation { return .gray.opacity(0.3) }
        
        switch validationResult {
        case .success:
            return .green
        case .warning:
            return .orange
        case .failure:
            return .red
        }
    }
    
    private var validationColor: Color {
        switch validationResult {
        case .success:
            return .green
        case .warning:
            return .orange
        case .failure:
            return .red
        }
    }
    
    private var validationIcon: String {
        switch validationResult {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failure:
            return "xmark.circle.fill"
        }
    }
    
    private var shouldShowCharacterCount: Bool {
        return maxCharacterCount > 0 && text.count > maxCharacterCount * 3 / 4
    }
    
    private var maxCharacterCount: Int {
        // 컨텍스트에 따른 최대 문자 수 반환
        if title.contains("제목") {
            return DataValidator.ValidationRules.maxPostTitleLength
        } else if title.contains("내용") {
            return DataValidator.ValidationRules.maxPostContentLength
        } else if title.contains("댓글") {
            return DataValidator.ValidationRules.maxCommentLength
        }
        return 0
    }
    
    // MARK: - 메서드
    private func validateInput(_ input: String) {
        validationResult = validator(input)
        
        // 입력 중일 때는 에러만 표시, 포커스가 벗어났을 때 모든 메시지 표시
        if isFocused {
            showValidation = !validationResult.isValid
        } else {
            showValidation = true
        }
    }
}

// MARK: - 검증된 텍스트 에디터 컴포넌트
struct ValidatedTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let validator: (String) -> ValidationResult
    let maxHeight: CGFloat
    let minHeight: CGFloat
    
    @State private var validationResult: ValidationResult = .success
    @State private var showValidation = false
    @State private var contentSize: CGSize = .zero
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        validator: @escaping (String) -> ValidationResult,
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 300
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.validator = validator
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목과 글자 수
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(text.count)")
                    .font(.caption)
                    .foregroundColor(characterCountColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(characterCountColor.opacity(0.1))
                    )
            }
            
            // 텍스트 에디터
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(
                        minHeight: minHeight,
                        maxHeight: min(maxHeight, max(minHeight, contentSize.height + 20))
                    )
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                            )
                    )
                
                // 플레이스홀더
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            
            // 검증 메시지
            if showValidation, let message = validationResult.message {
                HStack {
                    Image(systemName: validationIcon)
                        .foregroundColor(validationColor)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(validationColor)
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // 콘텐츠 필터링 결과
            if let filterResult = getFilterResult() {
                ContentFilterResultView(result: filterResult)
            }
        }
        .onChange(of: text) { _, newValue in
            validateInput(newValue)
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                showValidation = true
            }
        }
    }
    
    // MARK: - 계산된 속성
    private var borderColor: Color {
        if !showValidation { return .gray.opacity(0.3) }
        
        switch validationResult {
        case .success:
            return .green
        case .warning:
            return .orange
        case .failure:
            return .red
        }
    }
    
    private var validationColor: Color {
        switch validationResult {
        case .success:
            return .green
        case .warning:
            return .orange
        case .failure:
            return .red
        }
    }
    
    private var validationIcon: String {
        switch validationResult {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failure:
            return "xmark.circle.fill"
        }
    }
    
    private var characterCountColor: Color {
        let maxCount = getMaxCharacterCount()
        let ratio = Double(text.count) / Double(maxCount)
        
        if ratio >= 1.0 {
            return .red
        } else if ratio >= 0.8 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    // MARK: - 메서드
    private func validateInput(_ input: String) {
        validationResult = validator(input)
        
        if isFocused {
            showValidation = !validationResult.isValid
        } else {
            showValidation = true
        }
    }
    
    private func getMaxCharacterCount() -> Int {
        if title.contains("내용") {
            return DataValidator.ValidationRules.maxPostContentLength
        } else if title.contains("댓글") {
            return DataValidator.ValidationRules.maxCommentLength
        }
        return 1000
    }
    
    private func getFilterResult() -> ContentFilter.FilterResult? {
        guard !text.isEmpty else { return nil }
        
        let result = ContentFilter.shared.filterContent(text, context: .general)
        return result.isClean ? nil : result
    }
}

// MARK: - 콘텐츠 필터 결과 뷰
struct ContentFilterResultView: View {
    let result: ContentFilter.FilterResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.orange)
                
                Text("콘텐츠 검토")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("\(Int(result.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            
            if !result.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(result.suggestions, id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - 미리보기
#Preview {
    VStack(spacing: 20) {
        ValidatedTextField(
            title: "이메일",
            placeholder: "이메일을 입력하세요",
            text: Binding.constant(""),
            validator: DataValidator.shared.validateEmail,
            contentType: nil,
            keyboardType: {
                #if os(iOS)
                return .emailAddress
                #else
                return 0
                #endif
            }()
        )
        
        ValidatedTextField(
            title: "비밀번호",
            placeholder: "비밀번호를 입력하세요",
            text: Binding.constant(""),
            validator: DataValidator.shared.validatePassword,
            contentType: nil,
            keyboardType: {
                #if os(iOS)
                return .default
                #else
                return 0
                #endif
            }(),
            isSecure: true
        )
        
        ValidatedTextEditor(
            title: "게시글 내용",
            placeholder: "내용을 입력하세요",
            text: Binding.constant(""),
            validator: DataValidator.shared.validatePostContent
        )
    }
    .padding()
}
