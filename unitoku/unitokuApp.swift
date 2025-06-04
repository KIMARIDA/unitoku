//
//  unitokuApp.swift
//  unitoku
//
//  Created by 김준용 on 5/29/25.
//

import SwiftUI

@main
struct unitokuApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
