//
//  unitokuApp.swift
//  unitoku
//
//  Created by 김준용 on 5/29/25.
//
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseCrashlytics
import FirebaseMessaging
import FirebaseRemoteConfig
import UserNotifications

@main
struct unitokuApp: App {
    let persistenceController = PersistenceController.shared
    let syncManager: SyncManager
    let remoteConfigManager = RemoteConfigManager.shared
    
    // FCM 권한 및 delegate 설정
    init() {
        // Firebase 초기화
        FirebaseApp.configure()

        // Firebase Crashlytics 초기화
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        print("🔧 Crashlytics disabled for Debug builds")
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        print("✅ Crashlytics enabled for Release builds")
        #endif

        // 반드시 Firebase 초기화 이후에 싱크 매니저 생성
        self.syncManager = SyncManager.shared

        // Firestore 연결 테스트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let db = FirebaseManager.shared.getFirestore()
            db.collection("connection_test").addDocument(data: ["timestamp": Date()]) { error in
                if let error = error {
                    print("🔥 Firestore 연결 실패: \(error.localizedDescription)")
                } else {
                    print("✅ Firestore 연결 성공!")
                    print("🔄 Real-time sync started")
                }
            }
        }
        
        // FCM 권한 요청 및 delegate 등록
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Messaging.messaging().delegate = NotificationDelegate.shared
        requestFCMPermission()
    }
    
    func requestFCMPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(syncManager)
        }
    }
}

// FCM Delegate 구현
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationDelegate()
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("[FCM] Registration token: \(fcmToken ?? "nil")")
        // Firestore에 토큰 저장
        if let token = fcmToken {
            FirebaseManager.shared.saveFCMToken(token)
        }
    }
    
    // 포그라운드 알림 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
