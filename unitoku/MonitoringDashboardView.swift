import SwiftUI
import Combine

#if swift(>=5.7) && canImport(Charts)
import Charts
#endif

// MonitoringService import가 필요하지만 같은 파일에 있으므로 생략

// MARK: - 모니터링 대시보드 뷰
struct MonitoringDashboardView: View {
    @StateObject private var monitoringService = MonitoringService.shared
    @State private var selectedTimeRange: TimeRange = .hour
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더
                    DashboardHeaderView(
                        selectedTimeRange: $selectedTimeRange,
                        onRefresh: refreshData
                    )
                    
                    // 실시간 메트릭 카드들
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        MetricCardView(
                            title: "활성 사용자",
                            value: "\(monitoringService.realTimeMetrics.activeUsers)",
                            trend: monitoringService.realTimeMetrics.userTrend,
                            icon: "person.3.fill",
                            color: .blue
                        )
                        
                        MetricCardView(
                            title: "세션 길이",
                            value: formatDuration(AnalyticsManager.shared.sessionMetrics.sessionDuration),
                            trend: .stable,
                            icon: "clock.fill",
                            color: .green
                        )
                        
                        MetricCardView(
                            title: "오류율",
                            value: String(format: "%.2f%%", monitoringService.realTimeMetrics.errorRate),
                            trend: monitoringService.realTimeMetrics.errorTrend,
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                        
                        MetricCardView(
                            title: "응답 시간",
                            value: String(format: "%.0fms", AnalyticsManager.shared.sessionMetrics.networkLatency * 1000),
                            trend: .improving,
                            icon: "speedometer",
                            color: .orange
                        )
                    }
                    
                    // 성능 차트
                    PerformanceChartsView(timeRange: selectedTimeRange)
                    
                    // 사용자 활동 차트
                    UserActivityChartView(timeRange: selectedTimeRange)
                    
                    // 오류 및 경고 섹션
                    ErrorsAndWarningsView()
                    
                    // 보안 이벤트
                    SecurityEventsView()
                    
                    // 시스템 상태
                    SystemStatusView()
                }
                .padding()
            }
            .navigationTitle("모니터링 대시보드")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupRealTimeUpdates()
            }
            .onDisappear {
                stopRealTimeUpdates()
            }
        }
        .trackScreenView("monitoring_dashboard")
    }
    
    private func refreshData() {
        monitoringService.refreshMetrics()
        AnalyticsManager.shared.flushEvents()
    }
    
    private func setupRealTimeUpdates() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            refreshData()
        }
    }
    
    private func stopRealTimeUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - 대시보드 헤더
struct DashboardHeaderView: View {
    @Binding var selectedTimeRange: TimeRange
    let onRefresh: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("실시간 모니터링")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("마지막 업데이트: \(Date(), style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Picker("시간 범위", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - 메트릭 카드
struct MetricCardView: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                TrendIndicatorView(direction: trend)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - 트렌드 표시기
struct TrendIndicatorView: View {
    let direction: TrendDirection
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction.iconName)
                .foregroundColor(direction.color)
                .font(.caption)
            
            Text(direction.displayText)
                .font(.caption2)
                .foregroundColor(direction.color)
        }
    }
}

// MARK: - 성능 차트
struct PerformanceChartsView: View {
    let timeRange: TimeRange
    @StateObject private var monitoringService = MonitoringService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("성능 메트릭")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // 응답 시간 차트
                ChartCardView(title: "응답 시간", subtitle: "평균 응답 시간 (ms)") {
                    if #available(iOS 16.0, *) {
                        #if swift(>=5.7) && canImport(Charts)
                        Chart(monitoringService.responseTimeData) { dataPoint in
                            LineMark(
                                x: .value("시간", dataPoint.timestamp),
                                y: .value("응답시간", dataPoint.value)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 150)
                        #else
                        ChartFallbackView(data: monitoringService.responseTimeData, color: .blue)
                        #endif
                    } else {
                        ChartFallbackView(data: monitoringService.responseTimeData, color: .blue)
                    }
                }
                
                // 메모리 사용량 차트
                ChartCardView(title: "메모리 사용량", subtitle: "앱 메모리 사용량 (MB)") {
                    if #available(iOS 16.0, *) {
                        #if swift(>=5.7) && canImport(Charts)
                        Chart(monitoringService.memoryUsageData) { dataPoint in
                            AreaMark(
                                x: .value("시간", dataPoint.timestamp),
                                y: .value("메모리", dataPoint.value)
                            )
                            .foregroundStyle(.green.opacity(0.3))
                            
                            LineMark(
                                x: .value("시간", dataPoint.timestamp),
                                y: .value("메모리", dataPoint.value)
                            )
                            .foregroundStyle(.green)
                        }
                        .frame(height: 150)
                        #else
                        ChartFallbackView(data: monitoringService.memoryUsageData, color: .green)
                        #endif
                    } else {
                        ChartFallbackView(data: monitoringService.memoryUsageData, color: .green)
                    }
                }
                
                // CPU 사용량 차트
                ChartCardView(title: "CPU 사용량", subtitle: "프로세서 사용률 (%)") {
                    if #available(iOS 16.0, *) {
                        #if swift(>=5.7) && canImport(Charts)
                        Chart(monitoringService.cpuUsageData) { dataPoint in
                            BarMark(
                                x: .value("시간", dataPoint.timestamp),
                                y: .value("CPU", dataPoint.value)
                            )
                            .foregroundStyle(.orange)
                        }
                        .frame(height: 150)
                        #else
                        ChartFallbackView(data: monitoringService.cpuUsageData, color: .orange)
                        #endif
                    } else {
                        ChartFallbackView(data: monitoringService.cpuUsageData, color: .orange)
                    }
                }
            }
        }
    }
}

// MARK: - 사용자 활동 차트
struct UserActivityChartView: View {
    let timeRange: TimeRange
    @StateObject private var monitoringService = MonitoringService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("사용자 활동")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // 활성 사용자 차트
                ChartCardView(title: "활성 사용자", subtitle: "실시간 활성 사용자 수") {
                    if #available(iOS 16.0, *) {
                        #if swift(>=5.7) && canImport(Charts)
                        Chart(monitoringService.activeUsersData) { dataPoint in
                            LineMark(
                                x: .value("시간", dataPoint.timestamp),
                                y: .value("사용자", dataPoint.value)
                            )
                            .foregroundStyle(.purple)
                            .symbol(Circle())
                        }
                        .frame(height: 150)
                        #else
                        ChartFallbackView(data: monitoringService.activeUsersData, color: .purple)
                        #endif
                    } else {
                        ChartFallbackView(data: monitoringService.activeUsersData, color: .purple)
                    }
                }
                
                // 이벤트 발생 빈도
                ChartCardView(title: "이벤트 발생", subtitle: "시간당 이벤트 수") {
                    if #available(iOS 16.0, *) {
                        #if swift(>=5.7) && canImport(Charts)
                        Chart(monitoringService.eventFrequencyData) { dataPoint in
                            BarMark(
                                x: .value("이벤트", dataPoint.category ?? "Unknown"),
                                y: .value("횟수", dataPoint.value)
                            )
                            .foregroundStyle(.cyan)
                        }
                        .frame(height: 150)
                        #else
                        ChartFallbackView(data: monitoringService.eventFrequencyData, color: .cyan)
                        #endif
                    } else {
                        ChartFallbackView(data: monitoringService.eventFrequencyData, color: .cyan)
                    }
                }
            }
        }
    }
}

// MARK: - 오류 및 경고
struct ErrorsAndWarningsView: View {
    @StateObject private var monitoringService = MonitoringService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("오류 및 경고")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if monitoringService.recentErrors.count > 0 {
                    Badge(count: monitoringService.recentErrors.count, color: .red)
                }
            }
            
            if monitoringService.recentErrors.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "모든 시스템 정상",
                    subtitle: "현재 오류나 경고가 없습니다",
                    color: .green
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(monitoringService.recentErrors, id: \.id) { error in
                        ErrorItemView(error: error)
                    }
                }
            }
        }
    }
}

// MARK: - 보안 이벤트
struct SecurityEventsView: View {
    @StateObject private var monitoringService = MonitoringService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("보안 이벤트")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if monitoringService.securityEvents.count > 0 {
                    Badge(count: monitoringService.securityEvents.count, color: .orange)
                }
            }
            
            if monitoringService.securityEvents.isEmpty {
                EmptyStateView(
                    icon: "shield.checkered",
                    title: "보안 상태 양호",
                    subtitle: "의심스러운 활동이 감지되지 않았습니다",
                    color: .green
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(monitoringService.securityEvents, id: \.id) { event in
                        SecurityEventItemView(event: event)
                    }
                }
            }
        }
    }
}

// MARK: - 시스템 상태
struct SystemStatusView: View {
    @StateObject private var monitoringService = MonitoringService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시스템 상태")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SystemStatusItem(
                    title: "Firebase",
                    status: monitoringService.systemStatus.firebase,
                    icon: "cloud.fill"
                )
                
                SystemStatusItem(
                    title: "Database",
                    status: monitoringService.systemStatus.database,
                    icon: "externaldrive.fill"
                )
                
                SystemStatusItem(
                    title: "Storage",
                    status: monitoringService.systemStatus.storage,
                    icon: "folder.fill"
                )
                
                SystemStatusItem(
                    title: "Analytics",
                    status: monitoringService.systemStatus.analytics,
                    icon: "chart.bar.fill"
                )
                
                SystemStatusItem(
                    title: "Crashlytics",
                    status: monitoringService.systemStatus.crashlytics,
                    icon: "exclamationmark.triangle.fill"
                )
                
                SystemStatusItem(
                    title: "Performance",
                    status: monitoringService.systemStatus.performance,
                    icon: "speedometer"
                )
            }
        }
    }
}

// MARK: - Helper Views
struct ChartCardView<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct ErrorItemView: View {
    let error: ErrorEvent
    
    var body: some View {
        HStack {
            Image(systemName: error.severity.iconName)
                .foregroundColor(error.severity.color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.message)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(error.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(error.count > 1 ? "\(error.count)회" : "")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(error.severity.color.opacity(0.1))
        )
    }
}

struct SecurityEventItemView: View {
    let event: SecurityEvent
    
    var body: some View {
        HStack {
            Image(systemName: "shield.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(event.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(event.severity.displayName)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(event.severity.color.opacity(0.2))
                )
                .foregroundColor(event.severity.color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

struct SystemStatusItem: View {
    let title: String
    let status: SystemHealth
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .font(.title2)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(status.displayName)
                .font(.caption2)
                .foregroundColor(status.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(status.color.opacity(0.1))
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.largeTitle)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

struct Badge: View {
    let count: Int
    let color: Color
    
    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
    }
}

// MARK: - 미리보기
#Preview {
    MonitoringDashboardView()
}

// MARK: - Chart Fallback View (for iOS < 16 or when Charts is unavailable)
struct ChartFallbackView: View {
    let data: [ChartDataPoint]
    let color: Color
    
    var body: some View {
        VStack {
            Text("차트를 표시하려면 iOS 16+ 필요")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                ForEach(data.prefix(10), id: \.timestamp) { point in
                    Rectangle()
                        .fill(color.opacity(0.7))
                        .frame(width: 20, height: CGFloat(point.value / 10))
                }
            }
            .frame(height: 100)
        }
        .frame(height: 150)
    }
}
