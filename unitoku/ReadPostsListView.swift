import SwiftUI
import CoreData

struct ReadPostsListView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var refreshID = UUID()
    @State private var readPosts: [ReadPost] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(readPosts) { readPost in
                    Button(action: {
                        navigateToPost(id: readPost.id)
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(readPost.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            HStack {
                                Text("閲覧日時: \(formatDate(readPost.readAt))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("投稿日時: \(formatDate(readPost.postTimestamp))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if readPosts.isEmpty {
                    Text("閲覧履歴がありません")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .navigationTitle("既読リスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("閉じる")
                            .foregroundColor(Color.appTheme)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        clearReadHistory()
                    }) {
                        Text("履歴削除")
                            .foregroundColor(Color.appTheme)
                    }
                }
            }
            .onAppear {
                loadReadPosts()
            }
            .id(refreshID)
        }
    }
    
    private func loadReadPosts() {
        readPosts = ReadPostsManager.shared.getReadPosts()
    }
    
    private func clearReadHistory() {
        ReadPostsManager.shared.clearAllReadPosts()
        readPosts = []
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
        return formatter.string(from: date)
    }
}

#Preview {
    ReadPostsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}