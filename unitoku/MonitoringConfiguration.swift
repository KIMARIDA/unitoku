//
//  MonitoringConfiguration.swift
//  unitoku
//
//  Created by AI Assistant on 2025/06/18.
//

import Foundation
import SwiftUI

/// Configuration settings for the monitoring and analytics system
struct MonitoringConfiguration: Codable {
    
    // MARK: - Analytics Configuration
    struct AnalyticsConfig: Codable {
        var enabledInDebug: Bool = true
        var enabledInRelease: Bool = true
        var batchSize: Int = 10
        var batchInterval: TimeInterval = 30.0
        var enableSessionTracking: Bool = true
        var enableUserSegmentation: Bool = true
        var enablePerformanceTracking: Bool = true
        var customEventPrefix: String = "unitoku_"
    }
    
    // MARK: - Monitoring Configuration
    struct MonitoringConfig: Codable {
        var enableRealTimeMonitoring: Bool = true
        var updateInterval: TimeInterval = 1.0
        var retentionDays: Int = 30
        var enableSystemMetrics: Bool = true
        var enableNetworkMonitoring: Bool = true
        var enableCrashReporting: Bool = true
        var maxErrorsToStore: Int = 1000
        var enableSecurityMonitoring: Bool = true
    }
    
    // MARK: - Logging Configuration
    struct LoggingConfig: Codable {
        var enableFileLogging: Bool = true
        var logLevel: LogLevel = .info
        var maxLogEntries: Int = 10000
        var enableLogRotation: Bool = true
        var logRotationSizeMB: Int = 10
        var enableRemoteLogging: Bool = false
        var compressLogs: Bool = true
        
        enum LogLevel: String, Codable, CaseIterable {
            case debug = "debug"
            case info = "info"
            case warning = "warning"
            case error = "error"
            case critical = "critical"
        }
    }
    
    // MARK: - Dashboard Configuration
    struct DashboardConfig: Codable {
        var autoRefresh: Bool = true
        var refreshInterval: TimeInterval = 5.0
        var showSystemMetrics: Bool = true
        var showNetworkMetrics: Bool = true
        var showErrorMetrics: Bool = true
        var showSecurityMetrics: Bool = true
        var chartAnimationDuration: Double = 0.3
        var maxDataPoints: Int = 100
        var enableExport: Bool = true
    }
    
    // MARK: - Alerting Configuration
    struct AlertingConfig: Codable {
        var enableAlerts: Bool = true
        var errorThreshold: Int = 10
        var performanceThreshold: Double = 5.0
        var memoryThreshold: Double = 80.0
        var cpuThreshold: Double = 80.0
        var enablePushNotifications: Bool = false
        var enableEmailNotifications: Bool = false
    }
    
    // MARK: - Privacy Configuration
    struct PrivacyConfig: Codable {
        var enableDataCollection: Bool = true
        var anonymizeUserData: Bool = true
        var enableOptOut: Bool = true
        var dataRetentionDays: Int = 90
        var enableGDPRCompliance: Bool = true
        var enableCCPACompliance: Bool = true
    }
    
    // MARK: - Configuration Properties
    var analytics: AnalyticsConfig = AnalyticsConfig()
    var monitoring: MonitoringConfig = MonitoringConfig()
    var logging: LoggingConfig = LoggingConfig()
    var dashboard: DashboardConfig = DashboardConfig()
    var alerting: AlertingConfig = AlertingConfig()
    var privacy: PrivacyConfig = PrivacyConfig()
    
    // MARK: - Singleton
    static let shared: MonitoringConfiguration = {
        if let loaded = MonitoringConfiguration.load() {
            return loaded
        }
        return MonitoringConfiguration()
    }()
    
    // MARK: - Persistence
    private static let configFileName = "monitoring_config.json"
    
    private static var configFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(configFileName)
    }
    
    /// Load configuration from file
    static func load() -> MonitoringConfiguration? {
        guard let data = try? Data(contentsOf: configFileURL),
              let config = try? JSONDecoder().decode(MonitoringConfiguration.self, from: data) else {
            return nil
        }
        return config
    }
    
    /// Save configuration to file
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: Self.configFileURL)
        } catch {
            print("Failed to save monitoring configuration: \(error)")
        }
    }
    
    /// Reset to default configuration
    mutating func resetToDefaults() {
        self = MonitoringConfiguration()
        save()
    }
    
    /// Validate configuration settings
    func validate() -> [String] {
        var issues: [String] = []
        
        if analytics.batchSize <= 0 {
            issues.append("Analytics batch size must be greater than 0")
        }
        
        if analytics.batchInterval <= 0 {
            issues.append("Analytics batch interval must be greater than 0")
        }
        
        if monitoring.updateInterval < 0.1 {
            issues.append("Monitoring update interval must be at least 0.1 seconds")
        }
        
        if monitoring.retentionDays <= 0 {
            issues.append("Monitoring retention days must be greater than 0")
        }
        
        if logging.maxLogEntries <= 0 {
            issues.append("Max log entries must be greater than 0")
        }
        
        if logging.logRotationSizeMB <= 0 {
            issues.append("Log rotation size must be greater than 0")
        }
        
        if dashboard.refreshInterval < 1.0 {
            issues.append("Dashboard refresh interval must be at least 1 second")
        }
        
        if dashboard.maxDataPoints <= 0 {
            issues.append("Max data points must be greater than 0")
        }
        
        if privacy.dataRetentionDays <= 0 {
            issues.append("Data retention days must be greater than 0")
        }
        
        return issues
    }
    
    /// Get configuration summary
    var summary: String {
        return """
        Monitoring Configuration Summary:
        - Analytics: \(analytics.enabledInRelease ? "Enabled" : "Disabled")
        - Real-time Monitoring: \(monitoring.enableRealTimeMonitoring ? "Enabled" : "Disabled")
        - File Logging: \(logging.enableFileLogging ? "Enabled" : "Disabled")
        - Dashboard Auto-refresh: \(dashboard.autoRefresh ? "Enabled" : "Disabled")
        - Alerts: \(alerting.enableAlerts ? "Enabled" : "Disabled")
        - Data Collection: \(privacy.enableDataCollection ? "Enabled" : "Disabled")
        """
    }
}

/// SwiftUI view for configuring monitoring settings
struct MonitoringConfigurationView: View {
    @State private var config = MonitoringConfiguration.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Analytics Section
                Section("Analytics") {
                    Toggle("Enable in Debug", isOn: $config.analytics.enabledInDebug)
                    Toggle("Enable in Release", isOn: $config.analytics.enabledInRelease)
                    Toggle("Session Tracking", isOn: $config.analytics.enableSessionTracking)
                    Toggle("Performance Tracking", isOn: $config.analytics.enablePerformanceTracking)
                    
                    VStack(alignment: .leading) {
                        Text("Batch Size: \(config.analytics.batchSize)")
                        Slider(value: Binding(
                            get: { Double(config.analytics.batchSize) },
                            set: { config.analytics.batchSize = Int($0) }
                        ), in: 1...100, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Batch Interval: \(String(format: "%.1f", config.analytics.batchInterval))s")
                        Slider(value: $config.analytics.batchInterval, in: 1...300, step: 5)
                    }
                }
                
                // Monitoring Section
                Section("Monitoring") {
                    Toggle("Real-time Monitoring", isOn: $config.monitoring.enableRealTimeMonitoring)
                    Toggle("System Metrics", isOn: $config.monitoring.enableSystemMetrics)
                    Toggle("Network Monitoring", isOn: $config.monitoring.enableNetworkMonitoring)
                    Toggle("Crash Reporting", isOn: $config.monitoring.enableCrashReporting)
                    
                    VStack(alignment: .leading) {
                        Text("Update Interval: \(String(format: "%.1f", config.monitoring.updateInterval))s")
                        Slider(value: $config.monitoring.updateInterval, in: 0.1...10, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Retention: \(config.monitoring.retentionDays) days")
                        Slider(value: Binding(
                            get: { Double(config.monitoring.retentionDays) },
                            set: { config.monitoring.retentionDays = Int($0) }
                        ), in: 1...365, step: 1)
                    }
                }
                
                // Logging Section
                Section("Logging") {
                    Toggle("File Logging", isOn: $config.logging.enableFileLogging)
                    Toggle("Log Rotation", isOn: $config.logging.enableLogRotation)
                    Toggle("Compress Logs", isOn: $config.logging.compressLogs)
                    
                    Picker("Log Level", selection: $config.logging.logLevel) {
                        ForEach(MonitoringConfiguration.LoggingConfig.LogLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Log Entries: \(config.logging.maxLogEntries)")
                        Slider(value: Binding(
                            get: { Double(config.logging.maxLogEntries) },
                            set: { config.logging.maxLogEntries = Int($0) }
                        ), in: 100...50000, step: 100)
                    }
                }
                
                // Dashboard Section
                Section("Dashboard") {
                    Toggle("Auto Refresh", isOn: $config.dashboard.autoRefresh)
                    Toggle("Show System Metrics", isOn: $config.dashboard.showSystemMetrics)
                    Toggle("Show Network Metrics", isOn: $config.dashboard.showNetworkMetrics)
                    Toggle("Enable Export", isOn: $config.dashboard.enableExport)
                    
                    VStack(alignment: .leading) {
                        Text("Refresh Interval: \(String(format: "%.0f", config.dashboard.refreshInterval))s")
                        Slider(value: $config.dashboard.refreshInterval, in: 1...60, step: 1)
                    }
                }
                
                // Privacy Section
                Section("Privacy") {
                    Toggle("Data Collection", isOn: $config.privacy.enableDataCollection)
                    Toggle("Anonymize User Data", isOn: $config.privacy.anonymizeUserData)
                    Toggle("Enable Opt-out", isOn: $config.privacy.enableOptOut)
                    Toggle("GDPR Compliance", isOn: $config.privacy.enableGDPRCompliance)
                    
                    VStack(alignment: .leading) {
                        Text("Data Retention: \(config.privacy.dataRetentionDays) days")
                        Slider(value: Binding(
                            get: { Double(config.privacy.dataRetentionDays) },
                            set: { config.privacy.dataRetentionDays = Int($0) }
                        ), in: 1...365, step: 1)
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button("Save Configuration") {
                        saveConfiguration()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to Defaults") {
                        resetConfiguration()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Validate Settings") {
                        validateConfiguration()
                    }
                    .foregroundColor(.green)
                }
            }
            .navigationTitle("Monitoring Config")
            .alert("Configuration", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveConfiguration() {
        config.save()
        alertMessage = "Configuration saved successfully!"
        showingAlert = true
    }
    
    private func resetConfiguration() {
        config.resetToDefaults()
        alertMessage = "Configuration reset to defaults!"
        showingAlert = true
    }
    
    private func validateConfiguration() {
        let issues = config.validate()
        if issues.isEmpty {
            alertMessage = "Configuration is valid!"
        } else {
            alertMessage = "Configuration issues found:\n" + issues.joined(separator: "\n")
        }
        showingAlert = true
    }
}

#Preview {
    MonitoringConfigurationView()
}
