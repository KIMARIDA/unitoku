//
//  unitokuApp.swift
//  unitoku
//
//  Created by 김준용 on 5/29/25.
//
import SwiftUI
import FirebaseCore

@main
struct unitokuApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Firebase 초기화
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
