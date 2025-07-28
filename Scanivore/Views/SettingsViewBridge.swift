//
//  SettingsViewBridge.swift
//  Scanivore
//
//  Bridge to new TCA-based Settings implementation
//

import SwiftUI
import ComposableArchitecture

struct SettingsViewBridge: View {
    var body: some View {
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            }
        )
    }
}

// Keep the old name for compatibility during transition
typealias OldSettingsView = SettingsViewBridge

#Preview {
    SettingsViewBridge()
}