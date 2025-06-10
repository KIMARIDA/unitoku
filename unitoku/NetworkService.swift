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
            return "無効なURLです。"
        case .invalidResponse:
            return "サーバーの応答が無効です。"
        case .invalidData:
            return "データが無効です。"
        case .requestFailed(let error):
            return "リクエスト失敗: \(error.localizedDescription)"
        case .serverError(let code):
            return "サーバーエラー (コード: \(code))"
        case .decodingError(let error):
            return "データのデコードエラー: \(error.localizedDescription)"
        case .authError(let message):
            return message
        case .unknownError:
            return "不明なエラーが発生しました。"
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

// 会員登録リクエストのためのモデル追加
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
    
    // ログインメソッド
    func login(email: String, password: String) async -> Result<UserProfile, NetworkError> {
        do {
            // Firebase Authでログイン
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = authResult.user
            
            // Firestoreからユーザー情報を取得
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let userData = userDoc.data() else {
                return .failure(.invalidData)
            }
            
            // UserDefaultsにユーザーIDを保存
            UserDefaults.standard.set(user.uid, forKey: "currentUserId")
            
            // ユーザープロフィールオブジェクトを作成
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
            // エラー処理
            let errorMessage: String
            let nsError = error as NSError
            // Firebase AuthErrorCodeは.Code(rawValue:)ではなくrawValueで直接比較する必要がある
            switch nsError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "パスワードが正しくありません。"
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "該当するメールアドレスのユーザーが見つかりません。"
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "メールアドレスの形式が正しくありません。"
            case AuthErrorCode.userDisabled.rawValue:
                errorMessage = "このアカウントは無効化されています。"
            case AuthErrorCode.tooManyRequests.rawValue:
                errorMessage = "リクエストが多すぎます。しばらくしてから再度お試しください。"
            default:
                errorMessage = error.localizedDescription
            }
            return .failure(.authError(errorMessage))
        }
    }
    
    // 会員登録メソッド
    func signUp(name: String, email: String, password: String, studentID: String, department: String, grade: String) async -> Result<UserProfile, NetworkError> {
        do {
            // Firebase Authでユーザー作成
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = authResult.user
            // メールアドレス認証メール送信
            try await user.sendEmailVerification()
            // Firestoreにユーザー追加情報保存
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "studentID": studentID,
                "department": department,
                "grade": grade,
                "createdAt": FieldValue.serverTimestamp()
            ]
            try await db.collection("users").document(user.uid).setData(userData)
            // UserDefaultsにユーザーIDを保存
            UserDefaults.standard.set(user.uid, forKey: "currentUserId")
            // ユーザープロフィールオブジェクトを作成
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
            // エラー処理
            let errorMessage: String
            let nsError = error as NSError
            switch nsError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "すでに使用されているメールアドレスです。"
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "メールアドレスの形式が正しくありません。"
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "パスワードが弱すぎます。"
            default:
                errorMessage = error.localizedDescription
            }
            return .failure(.authError(errorMessage))
        }
    }
    
    // ログアウトメソッド
    func logout() -> Result<Void, NetworkError> {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "currentUserId")
            return .success(())
        } catch {
            return .failure(.requestFailed(error))
        }
    }
    
    // 現在のログイン状態を確認
    var isLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // 現在のユーザー情報を取得
    func getCurrentUser() async -> Result<UserProfile, NetworkError> {
        guard let user = Auth.auth().currentUser else {
            return .failure(.authError("ログインされたユーザーがいません。"))
        }
        
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard let userData = userDoc.data() else {
                return .failure(.invalidData)
            }
            
            // ユーザープロフィールオブジェクトを作成
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
