import Foundation
import FirebaseMessaging
import FirebaseAuth

// Firebase 클라우드 메시징 서비스 클래스
class FCMService {
    static let shared = FCMService()
    
    // 서버 키는 Firebase Remote Config에서 가져옴
    private var fcmServerKey: String = ""
    
    private init() {}
    
    // Remote Config에서 서버 키 업데이트
    func updateServerKey(_ key: String) {
        self.fcmServerKey = key
        print("[FCM] 서버 키가 설정되었습니다.")
    }
    
    // FCM HTTP v1 API를 사용하여 푸시 알림 전송
    func sendPushNotification(to token: String, title: String, body: String, data: [String: String]? = nil) {
        // 서버 키가 없거나 비어있으면 전송 안함
        guard !fcmServerKey.isEmpty else {
            print("[FCM] 서버 키가 설정되지 않아 메시지를 보낼 수 없습니다.")
            return
        }
        
        // 원격 설정에서 FCM 비활성화 설정 시 전송 안함
        if let remoteConfigManager = try? RemoteConfigManager.shared, !remoteConfigManager.isFCMEnabled() {
            print("[FCM] Remote Config에서 FCM이 비활성화되어 있습니다.")
            return
        }
        
        // FCM API 엔드포인트
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(fcmServerKey)", forHTTPHeaderField: "Authorization")
        
        // FCM 메시지 페이로드 구성
        var notification: [String: Any] = [
            "to": token,
            "notification": [
                "title": title,
                "body": body,
                "sound": "default"
            ],
        ]
        
        // 추가 데이터가 있는 경우
        if let data = data {
            notification["data"] = data
        }
        
        // JSON으로 직렬화
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notification)
            request.httpBody = jsonData
            
            // 요청 전송
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("[FCM] 전송 오류: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("[FCM] 알림 전송 성공")
                    } else {
                        print("[FCM] 알림 전송 실패: \(httpResponse.statusCode)")
                        if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                            print("[FCM] 응답: \(responseStr)")
                        }
                    }
                }
            }.resume()
        } catch {
            print("[FCM] JSON 직렬화 오류: \(error.localizedDescription)")
        }
    }
    
    // 특정 사용자의 FCM 토큰 조회 후 푸시 알림 전송
    func sendNotificationToUser(userId: String, title: String, message: String, data: [String: String]? = nil) {
        // 서버 키가 비어있으면 먼저 설정 가져오기 시도
        if fcmServerKey.isEmpty {
            if let remoteConfig = try? RemoteConfigManager.shared {
                remoteConfig.fetchConfig()
            }
        }
        
        // Firestore에서 해당 사용자의 FCM 토큰 조회
        let db = FirebaseManager.shared.getFirestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("[FCM] 토큰 조회 오류: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let fcmToken = data["fcmToken"] as? String else {
                print("[FCM] 토큰을 찾을 수 없음")
                return
            }
            
            // 토큰으로 푸시 알림 전송
            self.sendPushNotification(to: fcmToken, title: title, body: message, data: nil)
        }
    }
}
