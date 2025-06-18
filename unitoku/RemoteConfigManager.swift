import Foundation
import FirebaseRemoteConfig
import FirebaseMessaging

// Firebase Remote Config 래퍼 클래스
class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    
    private let remoteConfig: RemoteConfig
    private let defaults: [String: Any] = [
        "fcm_server_key": "",  // 기본값은 비어있음
        "fcm_enabled": true    // 알림 기능 활성화 여부 
    ]
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        // 개발 중에는 빠른 업데이트를 위해 캐시 시간을 짧게 설정
        #if DEBUG
        settings.minimumFetchInterval = 0 // 매번 새로 가져오기
        #else
        settings.minimumFetchInterval = 3600 // 프로덕션에서는 1시간 캐싱
        #endif
        
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(defaults as? [String: NSObject])
        
        // 앱 시작 시 설정 가져오기
        fetchConfig()
    }
    
    func fetchConfig() {
        remoteConfig.fetchAndActivate { [weak self] status, error in
            guard error == nil else {
                print("[RemoteConfig] 설정 가져오기 오류: \(error!.localizedDescription)")
                return
            }
            
            if status == .successFetchedFromRemote {
                print("[RemoteConfig] 원격 설정 가져오기 성공")
            } else {
                print("[RemoteConfig] 캐시된 설정 사용")
            }
            
            // FCMService에 서버 키 설정
            if let fcmServerKey = self?.getFCMServerKey(), !fcmServerKey.isEmpty {
                FCMService.shared.updateServerKey(fcmServerKey)
            }
        }
    }
    
    // FCM 서버 키 가져오기
    func getFCMServerKey() -> String {
        return remoteConfig.configValue(forKey: "fcm_server_key").stringValue ?? ""
    }
    
    // FCM 활성화 여부 확인
    func isFCMEnabled() -> Bool {
        return remoteConfig.configValue(forKey: "fcm_enabled").boolValue
    }
}
