import SwiftUI
import CoreData

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
                                .background(notification.isRead ? Color.clear : Color(hex: "e6f7ff").opacity(0.4))
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
        .listRowBackground(notification.isRead ? Color.clear : Color(hex: "e6f7ff").opacity(0.3))
    }
    
    var notificationIcon: some View {
        Group {
            switch notification.type {
            case .like:
                Image(systemName: "heart.fill")
            case .comment:
                Image(systemName: "bubble.left.fill")
            case .system:
                Image(systemName: "bell.fill")
            case .mention:
                Image(systemName: "at")
            }
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .like:
            return Color(hex: "FF3B30")
        case .comment:
            return Color(hex: "007AFF")
        case .system:
            return Color(hex: "FF9500")
        case .mention:
            return Color(hex: "5856D6")
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
