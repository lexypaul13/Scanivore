
import Foundation
import Dependencies
import ComposableArchitecture

// MARK: - Settings Models
public struct AppSettings: Codable, Equatable {
    public var enableNotifications: Bool
    public var autoSaveScans: Bool
    public var useMetricUnits: Bool
    public var scanQuality: String
    public var freshnessAlerts: Bool
    public var weeklyReports: Bool
    public var priceAlerts: Bool
    
    public init(
        enableNotifications: Bool = true,
        autoSaveScans: Bool = true,
        useMetricUnits: Bool = false,
        scanQuality: String = "high",
        freshnessAlerts: Bool = true,
        weeklyReports: Bool = false,
        priceAlerts: Bool = true
    ) {
        self.enableNotifications = enableNotifications
        self.autoSaveScans = autoSaveScans
        self.useMetricUnits = useMetricUnits
        self.scanQuality = scanQuality
        self.freshnessAlerts = freshnessAlerts
        self.weeklyReports = weeklyReports
        self.priceAlerts = priceAlerts
    }
    
    public static let `default` = AppSettings()
}

// MARK: - Settings Client
@DependencyClient
public struct SettingsClient: Sendable {
    public var load: @Sendable () async -> AppSettings = { .default }
    public var save: @Sendable (AppSettings) async -> Void
    public var reset: @Sendable () async -> Void
}

// MARK: - Dependency Key Conformance
extension SettingsClient: DependencyKey {
    public static let liveValue: Self = .init(
        load: {
            @Dependency(\.userDefaults) var userDefaults
            
            return AppSettings(
                enableNotifications: await userDefaults.getBool("enableNotifications"),
                autoSaveScans: await userDefaults.getBool("autoSaveScans"),
                useMetricUnits: await userDefaults.getBool("useMetricUnits"),
                scanQuality: await userDefaults.getString("scanQuality") ?? "high",
                freshnessAlerts: await userDefaults.getBool("freshnessAlerts"),
                weeklyReports: await userDefaults.getBool("weeklyReports"),
                priceAlerts: await userDefaults.getBool("priceAlerts")
            )
        },
        save: { settings in
            @Dependency(\.userDefaults) var userDefaults
            
            await userDefaults.setBool("enableNotifications", settings.enableNotifications)
            await userDefaults.setBool("autoSaveScans", settings.autoSaveScans)
            await userDefaults.setBool("useMetricUnits", settings.useMetricUnits)
            await userDefaults.setString("scanQuality", settings.scanQuality)
            await userDefaults.setBool("freshnessAlerts", settings.freshnessAlerts)
            await userDefaults.setBool("weeklyReports", settings.weeklyReports)
            await userDefaults.setBool("priceAlerts", settings.priceAlerts)
        },
        reset: {
            @Dependency(\.userDefaults) var userDefaults
            
            await userDefaults.remove("enableNotifications")
            await userDefaults.remove("autoSaveScans")
            await userDefaults.remove("useMetricUnits")
            await userDefaults.remove("scanQuality")
            await userDefaults.remove("freshnessAlerts")
            await userDefaults.remove("weeklyReports")
            await userDefaults.remove("priceAlerts")
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue = Self()
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var settings: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue }
    }
}
