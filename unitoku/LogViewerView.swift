import SwiftUI

// MARK: - 로그 뷰어 메인 화면
struct LogViewerView: View {
    @StateObject private var logManager = LogManager.shared
    @State private var showingFilters = false
    @State private var showingAnalytics = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 검색 및 필터 바
                SearchAndFilterBar(
                    searchText: $searchText,
                    showingFilters: $showingFilters,
                    showingAnalytics: $showingAnalytics,
                    onSearch: performSearch
                )
                
                // 로그 목록
                LogListView(logs: logManager.filteredLogs)
            }
            .navigationTitle("로그 뷰어")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("분석 보기") {
                            showingAnalytics = true
                        }
                        
                        Button("필터 설정") {
                            showingFilters = true
                        }
                        
                        Divider()
                        
                        Button("로그 내보내기") {
                            exportLogs()
                        }
                        
                        Button("로그 지우기", role: .destructive) {
                            clearLogs()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                LogFilterView(filter: $logManager.currentFilter)
            }
            .sheet(isPresented: $showingAnalytics) {
                LogAnalyticsView(analytics: logManager.analytics)
            }
        }
    }
    
    private func performSearch() {
        var filter = logManager.currentFilter
        filter.searchText = searchText
        logManager.updateFilter(filter)
    }
    
    private func exportLogs() {
        guard let data = logManager.exportLogs() else { return }
        // 파일 공유 로직 (실제 구현에서는 UIDocumentInteractionController 등 사용)
        print("로그 내보내기: \(data.count) bytes")
    }
    
    private func clearLogs() {
        logManager.clearLogs()
    }
}

// MARK: - 검색 및 필터 바
struct SearchAndFilterBar: View {
    @Binding var searchText: String
    @Binding var showingFilters: Bool
    @Binding var showingAnalytics: Bool
    let onSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("로그 검색...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onSearch()
                    }
                
                Button("필터") {
                    showingFilters = true
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
                
                Button("분석") {
                    showingAnalytics = true
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - 로그 목록 뷰
struct LogListView: View {
    let logs: [LogEntry]
    
    var body: some View {
        if logs.isEmpty {
            EmptyLogView()
        } else {
            List {
                ForEach(logs) { log in
                    LogRowView(log: log)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - 빈 로그 뷰
struct EmptyLogView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("로그가 없습니다")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("필터 조건을 변경하거나 새로운 활동을 기다려주세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - 로그 행 뷰
struct LogRowView: View {
    let log: LogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 기본 정보
            HStack {
                // 레벨 표시
                Circle()
                    .fill(log.level.color)
                    .frame(width: 8, height: 8)
                
                // 시간
                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 카테고리
                Text(log.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(log.level.color.opacity(0.2))
                    .foregroundColor(log.level.color)
                    .cornerRadius(4)
                
                Spacer()
                
                // 레벨 텍스트
                Text(log.level.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(log.level.color)
            }
            
            // 메시지
            Text(log.message)
                .font(.body)
                .lineLimit(isExpanded ? nil : 2)
            
            // 확장된 정보
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !log.details.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("상세 정보:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(log.details.keys), id: \.self) { key in
                                HStack {
                                    Text("\(key):")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Text(log.details[key] ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    if let userId = log.userId {
                        Text("사용자: \(userId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let sessionId = log.sessionId {
                        Text("세션: \(sessionId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorCode = log.errorCode {
                        Text("오류 코드: \(errorCode)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if let stackTrace = log.stackTrace {
                        VStack(alignment: .leading) {
                            Text("스택 트레이스:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text(stackTrace)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - 로그 필터 뷰
struct LogFilterView: View {
    @Binding var filter: LogFilter
    @Environment(\.presentationMode) var presentationMode
    @State private var tempFilter: LogFilter
    
    init(filter: Binding<LogFilter>) {
        self._filter = filter
        self._tempFilter = State(initialValue: filter.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 로그 레벨 섹션
                Section("로그 레벨") {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Toggle(level.rawValue, isOn: Binding(
                            get: { tempFilter.levels.contains(level) },
                            set: { isOn in
                                if isOn {
                                    tempFilter.levels.insert(level)
                                } else {
                                    tempFilter.levels.remove(level)
                                }
                            }
                        ))
                        .tint(level.color)
                    }
                }
                
                // 카테고리 섹션
                Section("카테고리") {
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        Toggle(category.displayName, isOn: Binding(
                            get: { tempFilter.categories.contains(category) },
                            set: { isOn in
                                if isOn {
                                    tempFilter.categories.insert(category)
                                } else {
                                    tempFilter.categories.remove(category)
                                }
                            }
                        ))
                    }
                }
                
                // 사용자 및 세션 필터
                Section("사용자 정보") {
                    TextField("사용자 ID", text: Binding(
                        get: { tempFilter.userId ?? "" },
                        set: { tempFilter.userId = $0.isEmpty ? nil : $0 }
                    ))
                    
                    TextField("세션 ID", text: Binding(
                        get: { tempFilter.sessionId ?? "" },
                        set: { tempFilter.sessionId = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                // 리셋 섹션
                Section {
                    Button("모든 필터 리셋") {
                        tempFilter = LogFilter()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("로그 필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("적용") {
                        filter = tempFilter
                        LogManager.shared.updateFilter(tempFilter)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 로그 분석 뷰
struct LogAnalyticsView: View {
    let analytics: LogAnalytics
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 전체 통계
                    OverallStatsView(analytics: analytics)
                    
                    // 레벨별 분포
                    LogLevelDistributionView(analytics: analytics)
                    
                    // 카테고리별 분포
                    CategoryDistributionView(analytics: analytics)
                    
                    // 시간대별 분포
                    HourlyDistributionView(analytics: analytics)
                    
                    // 상위 오류
                    TopErrorsView(analytics: analytics)
                }
                .padding()
            }
            .navigationTitle("로그 분석")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 전체 통계 뷰
struct OverallStatsView: View {
    let analytics: LogAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("전체 통계")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(title: "총 로그 수", value: "\(analytics.totalCount)")
                StatCard(title: "고유 사용자", value: "\(analytics.uniqueUsers.count)")
                StatCard(title: "고유 세션", value: "\(analytics.uniqueSessions.count)")
                StatCard(title: "세션당 평균 로그", value: String(format: "%.1f", analytics.averageLogsPerSession))
                StatCard(title: "오류율", value: String(format: "%.1f%%", analytics.errorRate))
                StatCard(title: "심각한 오류율", value: String(format: "%.2f%%", analytics.criticalErrorRate))
            }
        }
    }
}

// MARK: - 통계 카드
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - 레벨별 분포 뷰
struct LogLevelDistributionView: View {
    let analytics: LogAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("레벨별 분포")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    let count = analytics.levelCounts[level] ?? 0
                    let percentage = analytics.totalCount > 0 ? Double(count) / Double(analytics.totalCount) * 100 : 0
                    
                    HStack {
                        Circle()
                            .fill(level.color)
                            .frame(width: 12, height: 12)
                        
                        Text(level.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("(\(String(format: "%.1f", percentage))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 진행 바
                    ProgressView(value: percentage, total: 100)
                        .tint(level.color)
                }
            }
        }
    }
}

// MARK: - 카테고리별 분포 뷰
struct CategoryDistributionView: View {
    let analytics: LogAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("카테고리별 분포")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(LogCategory.allCases, id: \.self) { category in
                    let count = analytics.categoryCounts[category] ?? 0
                    let percentage = analytics.totalCount > 0 ? Double(count) / Double(analytics.totalCount) * 100 : 0
                    
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(.blue)
                            .frame(width: 16)
                        
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("(\(String(format: "%.1f", percentage))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - 시간대별 분포 뷰
struct HourlyDistributionView: View {
    let analytics: LogAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시간대별 분포")
                .font(.headline)
                .fontWeight(.semibold)
            
            // 간단한 막대 그래프
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    let count = analytics.hourlyDistribution[hour] ?? 0
                    let maxCount = analytics.hourlyDistribution.values.max() ?? 1
                    let height = CGFloat(count) / CGFloat(maxCount) * 80
                    
                    VStack {
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(height: max(height, 2))
                        
                        Text("\(hour)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
    }
}

// MARK: - 상위 오류 뷰
struct TopErrorsView: View {
    let analytics: LogAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("상위 오류 메시지")
                .font(.headline)
                .fontWeight(.semibold)
            
            if analytics.topErrors.isEmpty {
                Text("오류가 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(analytics.topErrors.sorted { $0.value > $1.value }.prefix(5)), id: \.key) { error in
                        HStack {
                            Text(error.key)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(error.value)회")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - 미리보기
#Preview {
    LogViewerView()
}
