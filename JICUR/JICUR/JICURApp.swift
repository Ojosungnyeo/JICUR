//
//  JICURApp.swift
//  JICUR
//
//  Created by sun on 10/15/26.
//

import ComposableArchitecture
import SwiftUI

@main
struct JICURApp: App {
    private let store = Store(initialState: MapFeature.State()) { MapFeature() }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
