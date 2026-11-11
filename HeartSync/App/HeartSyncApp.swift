//
//  HeartSyncApp.swift
//  HeartSync
//
//  Created by Amartya Karmakar on 2024-06-21.
//

import SwiftUI

@main
struct HeartSyncApp: App {
    @StateObject private var store = HeartSyncStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
