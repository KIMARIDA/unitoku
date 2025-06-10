import Foundation
import FirebaseAuth
import FirebaseFirestore

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case requestFailed(Error)
    case serverError(Int)
    case decodingError(Error)
    case unknownError
    case authError(String)
    
    var message: String {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .invalidResponse:
            return "서버 응답이 유효하지 않습니다."
        case .invalidData:
            return "데이터가 유효하지 않습니다."
        case .requestFailed(let error):
            return "요청 실패: \(error.localizedDescription)"
        case .serverError(let code):
            return "서버 오류 (코드: \(code))"
        case .decodingError(let error):
            return "데이터 디코딩 오류: \(error.localizedDescription)"
        case .authError(let message):
            return "인증 오류: \(message)"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    let studentID: String?
    let department: String?
    let grade: String?
}

// 회원가입 요청을 위한 모델 추가
struct SignUpRequest: Codable {
    let name: String
    let email: String
    let password: String
    let studentID: String
    let department: String
    let grade: String
}

class NetworkService {
    static let shared = NetworkService()
    
    private let db = Firestore.firestore()
    
    // 로그인 메서드
    func login(email: String, password: String) async -> Result<UserProfile, NetworkError> {
        do {
            // Firebase Auth로 로그인
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = authResult.user
            
            // Firestore에서 사용자 정보 가져오기
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let userData = userDoc.data() else {
                return .failure(.invalidData)
            }
            
            // UserDefaults에 사용자 ID 저장
            UserDefaults.standard.set(user.uid, forKey: "currentUserId")
            
            // 사용자 프로필 객체 생성
            let userProfile = UserProfile(
                id: user.uid,
                name: userData["name"] as? String ?? "",
                email: user.email ?? "",
                studentID: userData["studentID"] as? String,
                department: userData["department"] as? String,
                grade: userData["grade"] as? String
            )
            
            return .success(userProfile)
        } catch {
            // 에러 처리
            let errorMessage: String
            let nsError = error as NSError
            // Firebase AuthErrorCode는 .Code(rawValue:)가 아니라 rawValue로 직접 비교해야 함
            switch nsError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "비밀번호가 올바르지 않습니다."
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "해당 이메일의 사용자를 찾을 수 없습니다."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "이메일 형식이 올바르지 않습니다."
            case AuthErrorCode.userDisabled.rawValue:
                errorMessage = "이 계정은 비활성화되었습니다."
            case AuthErrorCode.tooManyRequests.rawValue:
                errorMessage = "너무 많은 요청이 발생했습니다. 나중에 다시 시도해주세요."
            default:
                errorMessage = error.localizedDescription
            }
            return .failure(.authError(errorMessage))
        }
    }
    
    // 회원가입 메서드
    func signUp(name: String, email: String, password: String, studentID: String, department: String, grade: String) async -> Result<UserProfile, NetworkError> {
        do {
            // Firebase Auth로 사용자 생성
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = authResult.user
            
            // Firestore에 사용자 추가 정보 저장
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "studentID": studentID,
                "department": department,
                "grade": grade,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(user.uid).setData(userData)
            
            // UserDefaults에 사용자 ID 저장
            UserDefaults.standard.set(user.uid, forKey: "currentUserId")
            
            // 사용자 프로필 객체 생성
            let userProfile = UserProfile(
                id: user.uid,
                name: name,
                email: email,
                studentID: studentID,
                department: department,
                grade: grade
            )
            
            return .success(userProfile)
        } catch {
            // 에러 처리
            let errorMessage: String
            let nsError = error as NSError
            switch nsError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "이미 사용 중인 이메일 주소입니다."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "이메일 형식이 올바르지 않습니다."
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "비밀번호가 너무 약합니다."
            default:
                errorMessage = error.localizedDescription
            }
            return .failure(.authError(errorMessage))
        }
    }
    
    // 로그아웃 메서드
    func logout() -> Result<Void, NetworkError> {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "currentUserId")
            return .success(())
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    
    // 현재 로그인 상태 확인
    var isLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // 현재 사용자 정보 가져오기
    func getCurrentUser() async -> Result<UserProfile, NetworkError> {
        guard let user = Auth.auth().currentUser else {
            return .failure(.authError("로그인된 사용자가 없습니다."))
        }
        
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let userData = userDoc.data() else {
                return .failure(.invalidData)
            }
            
            // 사용자 프로필 객체 생성
            let userProfile = UserProfile(
                id: user.uid,
                name: userData["name"] as? String ?? "",
                email: user.email ?? "",
                studentID: userData["studentID"] as? String,
                department: userData["department"] as? String,
                grade: userData["grade"] as? String
            )
            
            return .success(userProfile)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
}
