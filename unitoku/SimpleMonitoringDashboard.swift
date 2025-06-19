import SwiftUI
import Combine

// MARK: - 간단한 모니터링 대시보드
struct SimpleMonitoringDashboardView: View {
    @State private var selectedTimeRange = "1시간"
    @State private var refreshTimer: Timer?
    @State private var activeUsers = 45
    @State private var errorRate = 1.2
    @State private var responseTime = 250.0
    @State private var memoryUsage = 128.5
    
    let timeRanges = ["1시간", "24시간", "7일", "30일"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더
                    HeaderView(
                        selectedTimeRange: $selectedTimeRange,
                        timeRanges: timeRanges,
                        onRefresh: refreshData
                    )
                    
                    // 실시간 메트릭 카드들
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        MetricCard(
                            title: "활성 사용자",
                            value: "\(activeUsers)",
                            trend: "↗️",
                            color: .blue
                        )
                        
                        MetricCard(
                            title: "오류율",
                            value: String(format: "%.1f%%", errorRate),
                            trend: "↘️",
                            color: .red
                        )
                        
                        MetricCard(
                            title: "응답 시간",
                            value: String(format: "%.0fms", responseTime),
                            trend: "→",
                            color: .orange
                        )
                        
                        MetricCard(
                            title: "메모리 사용량",
                            value: String(format: "%.1fMB", memoryUsage),
                            trend: "↗️",
                            color: .green
                        )
                    }
                    
                    // 차트 섹션
                    ChartSection()
                    
                    // 최근 이벤트
                    RecentEventsSection()
                    
                    // 시스템 상태
                    SystemStatusSection()
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
    }
    
    private func refreshData() {
        // 데이터 새로고침 로직
        activeUsers = Int.random(in: 20...80)
        errorRate = Double.random(in: 0...5)
        responseTime = Double.random(in: 100...500)
        memoryUsage = Double.random(in: 80...200)
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
}

// MARK: - 헤더 뷰
struct HeaderView: View {
    @Binding var selectedTimeRange: String
    let timeRanges: [String]
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
                Menu {
                    ForEach(timeRanges, id: \.self) { range in
                        Button(range) {
                            selectedTimeRange = range
                        }
                    }
                } label: {
                    Text(selectedTimeRange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - 메트릭 카드
struct MetricCard: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trend)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - 차트 섹션
struct ChartSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("성능 트렌드")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                ChartCard(title: "응답 시간", subtitle: "지난 1시간") {
                    SimpleLineChart()
                }
                
                ChartCard(title: "사용자 활동", subtitle: "실시간") {
                    SimpleBarChart()
                }
            }
        }
    }
}

// MARK: - 차트 카드
struct ChartCard<Content: View>: View {
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
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - 간단한 라인 차트
struct SimpleLineChart: View {
    let dataPoints = Array(0..<20).map { _ in Double.random(in: 100...400) }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(dataPoints.count - 1)
                let maxY = dataPoints.max() ?? 400
                let minY = dataPoints.min() ?? 100
                let range = maxY - minY
                
                path.move(to: CGPoint(x: 0, y: height - CGFloat((dataPoints[0] - minY) / range) * height))
                
                for i in 1..<dataPoints.count {
                    let x = CGFloat(i) * stepX
                    let y = height - CGFloat((dataPoints[i] - minY) / range) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
        .frame(height: 100)
    }
}

// MARK: - 간단한 바 차트
struct SimpleBarChart: View {
    let dataPoints = Array(0..<10).map { _ in Double.random(in: 10...50) }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<dataPoints.count, id: \.self) { index in
                Rectangle()
                    .fill(Color.green)
                    .frame(height: CGFloat(dataPoints[index]) * 2)
                    .cornerRadius(2)
            }
        }
        .frame(height: 100)
    }
}

// MARK: - 최근 이벤트 섹션
struct RecentEventsSection: View {
    let sampleEvents = [
        ("새 사용자 등록", "2분 전", "👤"),
        ("게시글 작성", "5분 전", "📝"),
        ("댓글 작성", "8분 전", "💬"),
        ("로그인 성공", "12분 전", "🔐")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("최근 이벤트")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(sampleEvents, id: \.1) { event in
                    EventRow(icon: event.2, title: event.0, time: event.1)
                }
            }
        }
    }
}

// MARK: - 이벤트 행
struct EventRow: View {
    let icon: String
    let title: String
    let time: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - 시스템 상태 섹션
struct SystemStatusSection: View {
    let systemServices = [
        ("Firebase", "정상", Color.green),
        ("Database", "정상", Color.green),
        ("Storage", "주의", Color.orange),
        ("Analytics", "정상", Color.green),
        ("Crashlytics", "정상", Color.green),
        ("Performance", "정상", Color.green)
    ]
    
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
                ForEach(systemServices, id: \.0) { service in
                    ServiceStatus(
                        name: service.0,
                        status: service.1,
                        color: service.2
                    )
                }
            }
        }
    }
}

// MARK: - 서비스 상태
struct ServiceStatus: View {
    let name: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(status)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - 미리보기
#Preview {
    SimpleMonitoringDashboardView()
}
