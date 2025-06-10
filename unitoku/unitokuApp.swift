//
//  unitokuApp.swift
//  unitoku
//
//  Created by 김준용 on 5/29/25.
//
import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct unitokuApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Firebase 초기화
        FirebaseApp.configure()
        // Firebase 연결 테스트
        let db = Firestore.firestore()
        db.collection("connection_test").addDocument(data: ["timestamp": Date()]) { error in
            if let error = error {
                print("🔥 Firestore 연결 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 연결 성공!")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
