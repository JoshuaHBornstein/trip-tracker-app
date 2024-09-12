//
//  driver_mile_trackerApp.swift
//  driver_mile_tracker
//
//  Created by Josh Bornstein on 9/11/24.
//

import SwiftUI

@main
struct driver_mile_trackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
