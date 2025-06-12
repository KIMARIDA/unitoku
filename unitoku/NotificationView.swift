import SwiftUI
import CoreData
import Foundation
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

struct NotificationItem: Identifiable {
    var id = UUID()
    var title: String
    var message: String
    var timestamp: Date
    var isRead: Bool
    var type: NotificationType
    var relatedPostId: UUID?
    
    enum NotificationType {
        case like
        case comment
        case system
        case mention
    }
}

struct NotificationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [NotificationItem] = []
    @State private var isLoading = true
    @State private var hasUnreadNotifications = false
    @State private var firestoreListener: ListenerRegistration?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                } else if notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("通知はありません")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .background(notification.isRead ? Color.clear : Color.blue.opacity(0.1))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    markAsRead(notification: notification)
                                    handleNotificationTap(notification)
                                }
                        }
                        .onDelete(perform: deleteNotifications)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await loadNotifications()
                    }
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("すべて既読") {
                        markAllAsRead()
                    }
                    .disabled(notifications.filter { !$0.isRead }.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await loadNotifications()
                }
                listenToFirestoreNotifications()
            }
            .onDisappear {
                firestoreListener?.remove()
            }
        }
    }
    
    private func loadNotifications() async {
        // Simulate network fetch or database query
        isLoading = true
        
        // Artificial delay to simulate network request
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Sample data - In a real app, you would fetch from CoreData or an API
        notifications = [
            NotificationItem(
                title: "いいね",
                message: "あなたの投稿に「いいね」が付きました",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false,
                type: .like,
                relatedPostId: UUID()
            ),
            NotificationItem(
                title: "コメント",
                message: "あなたの投稿にコメントがあります",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: false,
                type: .comment,
                relatedPostId: UUID()
            ),
            NotificationItem(
                title: "システム",
                message: "アプリのアップデートがあります",
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true,
                type: .system
            )
        ]
        
        hasUnreadNotifications = notifications.contains(where: { !$0.isRead })
        
        // Save unread status to UserDefaults to ensure HomeView can access it
        UserDefaults.standard.setValue(hasUnreadNotifications, forKey: "hasUnreadNotifications")
        
        isLoading = false
    }
    
    private func markAsRead(notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
        
        // Update unread status
        hasUnreadNotifications = notifications.contains(where: { !$0.isRead })
        
        // Save unread status to UserDefaults
        UserDefaults.standard.setValue(hasUnreadNotifications, forKey: "hasUnreadNotifications")
    }
    
    private func markAllAsRead() {
        notifications = notifications.map { notification in
            var updated = notification
            updated.isRead = true
            return updated
        }
        hasUnreadNotifications = false
        
        // Save unread status to UserDefaults
        UserDefaults.standard.setValue(false, forKey: "hasUnreadNotifications")
    }
    
    private func deleteNotifications(at offsets: IndexSet) {
        notifications.remove(atOffsets: offsets)
        // Update unread status
        hasUnreadNotifications = notifications.contains(where: { !$0.isRead })
        
        // Save unread status to UserDefaults
        UserDefaults.standard.setValue(hasUnreadNotifications, forKey: "hasUnreadNotifications")
    }
    
    private func handleNotificationTap(_ notification: NotificationItem) {
        // Navigate to related content if applicable
        if let postId = notification.relatedPostId {
            // Navigate to post
            NotificationCenter.default.post(
                name: Foundation.Notification.Name("navigateToPost"),
                object: nil,
                userInfo: ["postId": postId]
            )
            dismiss()
        }
    }
    
    private func listenToFirestoreNotifications() {
        // Firebase Auth가 제대로 로드되지 않는 문제가 있어, UserDefaults에서 현재 사용자 ID를 가져옵니다
        // 실제 환경에서는 아래 주석 처리된 코드를 사용해야 합니다
        //guard let userId = Auth.auth().currentUser?.uid else { return }
        let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "user_1"
        
        let db = Firestore.firestore()
        firestoreListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let items: [NotificationItem] = documents.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let message = data["message"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                          let isRead = data["isRead"] as? Bool,
                          let typeString = data["type"] as? String else { return nil }
                    let type: NotificationItem.NotificationType
                    switch typeString {
                    case "like": type = .like
                    case "comment": type = .comment
                    case "mention": type = .mention
                    default: type = .system
                    }
                    let relatedPostId = (data["relatedPostId"] as? String).flatMap { UUID(uuidString: $0) }
                    return NotificationItem(title: title, message: message, timestamp: timestamp, isRead: isRead, type: type, relatedPostId: relatedPostId)
                }
                notifications = items
                hasUnreadNotifications = items.contains { !$0.isRead }
                isLoading = false
            }
    }
}

struct NotificationRow: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            notificationIcon
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.2))
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(notification.isRead ? .primary : .black)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.timestamp.relativeTimeInJapanese())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
        .listRowBackground(notification.isRead ? Color.clear : Color.blue.opacity(0.1))
    }
    
    var notificationIcon: some View {
        Group {
            switch notification.type {
            case .like:
                Image(systemName: "heart.fill")
            case .comment:
                Image(systemName: "bubble.left.fill")
            case .system:
                Image(systemName: "arrow.clockwise")
            case .mention:
                Image(systemName: "at")
            }
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .like:
            return .red
        case .comment:
            return .blue
        case .system:
            return .gray
        case .mention:
            return .purple
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
