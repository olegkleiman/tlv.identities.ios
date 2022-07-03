//
//  tlv_identities_iosApp.swift
//  Tlv.Identities.watch WatchKit Extension
//
//  Created by Oleg Kleiman on 02/07/2022.
//

import SwiftUI

@main
struct tlv_identities_iosApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
