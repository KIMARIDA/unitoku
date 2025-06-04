import SwiftUI
import CoreData

struct CategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let category: Category
    @State private var showingNewPostSheet = false
    @State private var newPostTitle = ""
    @State private var newPostContent = ""
    
    var fetchRequest: FetchRequest<Post>
    var posts: FetchedResults<Post> { fetchRequest.wrappedValue }
    
    init(category: Category) {
        self.category = category
        self.fetchRequest = FetchRequest<Post>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Post.timestamp, ascending: false)],
            predicate: NSPredicate(format: "category == %@", category),
            animation: .default
        )
    }
    
    var body: some View {
        List {
            ForEach(posts) { post in
                NavigationLink(destination: PostDetailView(post: post)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.title ?? "タイトルなし")
                            .font(.headline)
                            .lineLimit(1)
                        
                        // 게시판 정보 제거
                        
                        Text(post.content ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack {
                            // 좋아요 - 엄지 척 아이콘 유지
                            Image(systemName: "hand.thumbsup.fill")
                                .foregroundColor(Color.appTheme)
                                .imageScale(.small)
                            Text("\(post.likeCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            // 댓글 수
                            Image(systemName: "bubble.left")
                                .foregroundColor(Color.appTheme)
                                .imageScale(.small)
                                .padding(.leading, 8)
                            Text("\(post.comments?.count ?? 0)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // 날짜
                            Text(post.timestamp ?? Date(), formatter: itemFormatter)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .onDelete(perform: deletePosts)
        }
        .navigationTitle(category.name ?? "掲示板")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewPostSheet.toggle() }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(Color.appTheme)
                }
            }
        }
        .sheet(isPresented: $showingNewPostSheet) {
            NewPostView(isPresented: $showingNewPostSheet, category: category)
        }
        .background(Color.white)
    }
    
    private func deletePosts(offsets: IndexSet) {
        withAnimation {
            offsets.map { posts[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting post: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
    let categories = try? context.fetch(fetchRequest)
    
    return CategoryView(category: categories?.first ?? Category())
        .environment(\.managedObjectContext, context)
}
