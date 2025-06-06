import SwiftUI
import CoreData

struct ReadPostsListView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var refreshID = UUID()
    @State private var readPosts: [ReadPost] = []
    @State private var showingDeleteAlert = false
    @State private var selectedPostToDelete: ReadPost?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if readPosts.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(readPosts) { readPost in
                                ReadPostCard(
                                    readPost: readPost,
                                    onTap: { navigateToPost(id: readPost.id) },
                                    onDelete: { deletePost(readPost) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("既読リスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("閉じる")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color.appTheme)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                            Text("全削除")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.red)
                    }
                    .disabled(readPosts.isEmpty)
                }
            }
            .onAppear {
                loadReadPosts()
            }
            .alert("履歴を削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    clearReadHistory()
                }
            } message: {
                Text("すべての既読履歴を削除しますか？この操作は取り消せません。")
            }
            .id(refreshID)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "book.closed")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    Text("既読履歴がありません")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("読んだ投稿がここに表示されます")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func loadReadPosts() {
        readPosts = ReadPostsManager.shared.getReadPosts()
    }
    
    private func clearReadHistory() {
        ReadPostsManager.shared.clearAllReadPosts()
        readPosts = []
        refreshID = UUID()
    }
    
    private func deletePost(_ post: ReadPost) {
        ReadPostsManager.shared.deleteReadPost(postID: post.id)
        readPosts.removeAll { $0.id == post.id }
        refreshID = UUID()
    }
    
    private func navigateToPost(id: UUID) {
        NotificationCenter.default.post(
            name: Notification.Name("navigateToPost"),
            object: nil,
            userInfo: ["postId": id]
        )
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func relativeTimeString(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)日前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)時間前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分前"
        } else {
            return "今"
        }
    }
}

// MARK: - ReadPostCard Component
struct ReadPostCard: View {
    let readPost: ReadPost
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left content
                VStack(alignment: .leading, spacing: 8) {
                    Text(readPost.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 16) {
                        Label {
                            Text(formatReadDate(readPost.readAt))
                                .font(.system(size: 12, weight: .medium))
                        } icon: {
                            Image(systemName: "eye")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        
                        Label {
                            Text(formatPostDate(readPost.postTimestamp))
                                .font(.system(size: 12, weight: .medium))
                        } icon: {
                            Image(systemName: "clock")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Right side - Delete button and chevron
                HStack(spacing: 8) {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatReadDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: now) {
            formatter.timeStyle = .short
            return "今日 \(formatter.string(from: date))"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            formatter.timeStyle = .short
            return "昨日 \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func formatPostDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ReadPostsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}