import SwiftUI

// MARK: - Sync Status View
struct SyncStatusView: View {
    @EnvironmentObject var syncManager: SyncManager
    
    var body: some View {
        HStack(spacing: 8) {
            Group {
                switch syncManager.syncStatus {
                case .idle:
                    Image(systemName: "cloud")
                        .foregroundColor(.gray)
                case .syncing:
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(syncManager.isOnline ? 0 : 180))
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: syncManager.isOnline)
                case .success:
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.green)
                case .error(_):
                    Image(systemName: "cloud.bolt")
                        .foregroundColor(.red)
                }
            }
            .font(.caption)
            
            if !syncManager.isOnline {
                Text("オフライン")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Sync Button
struct SyncButton: View {
    @EnvironmentObject var syncManager: SyncManager
    @State private var showingSyncAlert = false
    
    var body: some View {
        Button(action: {
            Task {
                await syncManager.syncAllLocalDataToFirebase()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise.icloud")
                Text("同期")
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .disabled(syncManager.syncStatus == .syncing)
        .alert("同期状況", isPresented: $showingSyncAlert) {
            Button("OK") { }
        } message: {
            switch syncManager.syncStatus {
            case .idle:
                Text("同期待機中")
            case .syncing:
                Text("同期中...")
            case .success:
                Text("同期完了")
            case .error(let message):
                Text("同期エラー: \(message)")
            }
        }
        .onChange(of: syncManager.syncStatus) { status in
            if case .success = status {
                showingSyncAlert = true
            } else if case .error(_) = status {
                showingSyncAlert = true
            }
        }
    }
}

// MARK: - Real-time Chat Integration
struct ChatRoomView: View {
    let roomId: String
    let roomName: String
    
    @EnvironmentObject var syncManager: SyncManager
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    
    var body: some View {
        VStack {
            // Messages list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal)
            }
            
            // Message input
            HStack {
                TextField("メッセージを入力", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("送信") {
                    sendMessage()
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(roomName)
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        syncManager.listenToMessages(roomId: roomId) { messages in
            self.messages = messages
        }
    }
    
    private func sendMessage() {
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        Task {
            do {
                try await syncManager.sendMessage(roomId: roomId, content: messageText)
                newMessage = ""
            } catch {
                print("Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - Course Evaluation Sync View
struct CourseEvaluationSyncView: View {
    let courseId: UUID
    
    @EnvironmentObject var syncManager: SyncManager
    @State private var evaluations: [CourseEvaluation] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("評価を読み込み中...")
            } else {
                List(evaluations) { evaluation in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(evaluation.authorName)
                                .font(.headline)
                            Spacer()
                            Text(evaluation.semester)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= evaluation.overallScore.rawValue ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                            Text("いいね: \(evaluation.likes)")
                                .font(.caption)
                        }
                        
                        Text(evaluation.comment)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            loadEvaluations()
        }
        .refreshable {
            loadEvaluations()
        }
    }
    
    private func loadEvaluations() {
        isLoading = true
        Task {
            do {
                let fetchedEvaluations = try await syncManager.getCourseEvaluations(courseId: courseId)
                await MainActor.run {
                    self.evaluations = fetchedEvaluations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("Failed to load evaluations: \(error)")
            }
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    VStack {
        SyncStatusView()
        SyncButton()
    }
    .environmentObject(SyncManager.shared)
}

// MARK: - Sync Settings View
struct SyncSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var syncManager: SyncManager
    @State private var autoSync = UserDefaults.standard.bool(forKey: "autoSync")
    @State private var wifiOnlySync = UserDefaults.standard.bool(forKey: "wifiOnlySync")
    @State private var syncFrequency = UserDefaults.standard.integer(forKey: "syncFrequency")
    @State private var lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    @State private var showingResetAlert = false
    
    private let frequencies = [
        (0, "手動"),
        (15, "15分毎"),
        (30, "30分毎"),
        (60, "1時間毎"),
        (360, "6時間毎")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("同期設定")) {
                    Toggle("自動同期", isOn: $autoSync)
                        .onChange(of: autoSync) { value in
                            UserDefaults.standard.set(value, forKey: "autoSync")
                        }
                    
                    Toggle("Wi-Fi接続時のみ同期", isOn: $wifiOnlySync)
                        .onChange(of: wifiOnlySync) { value in
                            UserDefaults.standard.set(value, forKey: "wifiOnlySync")
                        }
                    
                    Picker("同期頻度", selection: $syncFrequency) {
                        ForEach(frequencies, id: \.0) { frequency in
                            Text(frequency.1).tag(frequency.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: syncFrequency) { value in
                        UserDefaults.standard.set(value, forKey: "syncFrequency")
                    }
                }
                
                Section(header: Text("同期状況")) {
                    HStack {
                        Text("ステータス")
                        Spacer()
                        SyncStatusView()
                    }
                    
                    HStack {
                        Text("接続状況")
                        Spacer()
                        Text(syncManager.isOnline ? "オンライン" : "オフライン")
                            .foregroundColor(syncManager.isOnline ? .green : .red)
                    }
                    
                    if let lastSync = lastSyncDate {
                        HStack {
                            Text("最後の同期")
                            Spacer()
                            Text(DateFormatter.syncDateFormatter.string(from: lastSync))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("データ管理")) {
                    Button(action: {
                        Task {
                            await syncManager.syncAllLocalDataToFirebase()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.icloud")
                                .foregroundColor(.blue)
                            Text("今すぐ同期")
                        }
                    }
                    .disabled(syncManager.syncStatus == .syncing)
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.red)
                            Text("同期データをリセット")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(footer: Text("同期設定を変更すると、次回の自動同期から適用されます。")) {
                    EmptyView()
                }
            }
            .navigationTitle("データ同期")
            .navigationBarItems(
                leading: Button("戻る") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("データリセット", isPresented: $showingResetAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("リセット", role: .destructive) {
                    resetSyncData()
                }
            } message: {
                Text("同期データをすべてリセットしますか？この操作は取り消せません。")
            }
        }
    }
    
    private func resetSyncData() {
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        UserDefaults.standard.removeObject(forKey: "syncData")
        // Add any additional reset logic here
        print("Sync data reset")
    }
}

extension DateFormatter {
    static let syncDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
