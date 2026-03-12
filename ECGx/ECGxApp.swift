//
//  ECGxApp.swift
//  ECGx
//
//  Created by Qusai Asaad on 12/03/2026.
//

import SwiftUI
import CoreData

@main
struct ECGxApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
