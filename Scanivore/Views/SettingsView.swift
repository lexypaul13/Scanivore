//
//  SettingsView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("autoSaveScans") private var autoSaveScans = true
    @AppStorage("useMetricUnits") private var useMetricUnits = false
    @AppStorage("scanQuality") private var scanQuality = "high"
    @State private var showingAbout = false
    @State private var showingPrivacy = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        ProfileHeaderView()
                    }
                    .listRowBackground(DesignSystem.Colors.background)
                    
                    Section("Scanning Preferences") {
                        Toggle("Auto-save Scans", isOn: $autoSaveScans)
                            .tint(DesignSystem.Colors.primaryRed)
                        
                        Picker("Scan Quality", selection: $scanQuality) {
                            Text("High").tag("high")
                            Text("Medium").tag("medium")
                            Text("Low").tag("low")
                        }
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Toggle("Use Metric Units", isOn: $useMetricUnits)
                            .tint(DesignSystem.Colors.primaryRed)
                    }
                    .listRowBackground(DesignSystem.Colors.background)
                    
                    Section("Notifications") {
                        Toggle("Enable Notifications", isOn: $enableNotifications)
                            .tint(DesignSystem.Colors.primaryRed)
                        
                        if enableNotifications {
                            NavigationLink(destination: NotificationSettingsView()) {
                                Label("Notification Settings", systemImage: "bell")
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                    .listRowBackground(DesignSystem.Colors.background)
                    
                    Section("Data & Privacy") {
                        NavigationLink(destination: DataManagementView()) {
                            Label("Manage Scan Data", systemImage: "folder")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        Button(action: { showingPrivacy = true }) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                    .listRowBackground(DesignSystem.Colors.background)
                    
                    Section("Support") {
                        NavigationLink(destination: HelpView()) {
                            Label("Help & FAQ", systemImage: "questionmark.circle")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        Link(destination: URL(string: "mailto:support@scanivore.app")!) {
                            Label("Contact Support", systemImage: "envelope")
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                        }
                    }
                    .listRowBackground(DesignSystem.Colors.background)
                    
                    Section {
                        Button(action: { showingAbout = true }) {
                            Label("About Scanivore", systemImage: "info.circle")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        HStack {
                            Text("Version")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .listRowBackground(DesignSystem.Colors.background)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingPrivacy) {
                PrivacyPolicyView()
            }
        }
    }
}

struct ProfileHeaderView: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.base) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Guest User")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Button("Sign in to sync data") {
                    // Sign in action
                }
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.primaryRed)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

struct NotificationSettingsView: View {
    @AppStorage("freshnessAlerts") private var freshnessAlerts = true
    @AppStorage("weeklyReports") private var weeklyReports = false
    @AppStorage("priceAlerts") private var priceAlerts = true
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundSecondary
                .ignoresSafeArea()
            
            Form {
                Section("Alert Types") {
                    Toggle("Freshness Alerts", isOn: $freshnessAlerts)
                        .tint(DesignSystem.Colors.primaryRed)
                    Toggle("Weekly Reports", isOn: $weeklyReports)
                        .tint(DesignSystem.Colors.primaryRed)
                    Toggle("Price Drop Alerts", isOn: $priceAlerts)
                        .tint(DesignSystem.Colors.primaryRed)
                }
                .listRowBackground(DesignSystem.Colors.background)
                
                Section("Alert Timing") {
                    DatePicker("Daily Summary Time", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .listRowBackground(DesignSystem.Colors.background)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct DataManagementView: View {
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundSecondary
                .ignoresSafeArea()
            
            Form {
                Section("Storage") {
                    HStack {
                        Text("Total Scans")
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Text("142")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    HStack {
                        Text("Storage Used")
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Text("24.3 MB")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .listRowBackground(DesignSystem.Colors.background)
                
                Section("Export") {
                    Button(action: {}) {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
                .listRowBackground(DesignSystem.Colors.background)
                
                Section {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
                .listRowBackground(DesignSystem.Colors.background)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
        } message: {
            Text("This action cannot be undone. All your scan history will be permanently deleted.")
        }
    }
}

struct HelpView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundSecondary
                .ignoresSafeArea()
            
            List {
                Section("Getting Started") {
                    NavigationLink("How to scan meat") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    NavigationLink("Understanding quality scores") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    NavigationLink("Freshness indicators") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .listRowBackground(DesignSystem.Colors.background)
                
                Section("Features") {
                    NavigationLink("Nutrition information") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    NavigationLink("Storage recommendations") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    NavigationLink("Sharing results") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .listRowBackground(DesignSystem.Colors.background)
                
                Section("Troubleshooting") {
                    NavigationLink("Camera not working") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    NavigationLink("Inaccurate results") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    NavigationLink("App crashes") {}
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .listRowBackground(DesignSystem.Colors.background)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xxxl) {
                    Spacer()
                    
                    Image(systemName: "camera.metering.center.weighted")
                        .font(.system(size: 80))
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    
                    Text("Scanivore")
                        .font(DesignSystem.Typography.hero)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("AI-Powered Meat Analysis")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    VStack(spacing: DesignSystem.Spacing.base) {
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("© 2025 Scanivore Inc.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Link("Terms of Service", destination: URL(string: "https://scanivore.app/terms")!)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        Link("Privacy Policy", destination: URL(string: "https://scanivore.app/privacy")!)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        Link("Acknowledgments", destination: URL(string: "https://scanivore.app/credits")!)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                    .font(.subheadline)
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        Text("Privacy Policy")
                            .font(DesignSystem.Typography.hero)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Last updated: June 28, 2025")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
                            Text("Data Collection")
                                .font(DesignSystem.Typography.heading2)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("Scanivore collects minimal data necessary to provide meat analysis services. This includes images of meat products and associated metadata.")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Data Usage")
                                .font(DesignSystem.Typography.heading2)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("Your data is used solely for analysis purposes and improving our AI models. We never sell or share your personal information.")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Data Storage")
                                .font(DesignSystem.Typography.heading2)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("All data is stored locally on your device. Cloud sync is optional and requires explicit consent.")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Your Rights")
                                .font(DesignSystem.Typography.heading2)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("You can delete all your data at any time through the Settings menu. You have the right to export your data in a portable format.")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .font(.subheadline)
                    }
                    .padding(DesignSystem.Spacing.screenPadding)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}