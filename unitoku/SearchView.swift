import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchResults: [Post] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 검색창
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.appTheme)
                    
                    TextField("投稿を検索", text: $searchText)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.appTheme)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 3)
                .padding()
                
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(Color.appTheme)
                } else if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                VStack(alignment: .leading) {
                                    Text(post.title ?? "タイトルなし")
                                        .font(.headline)
                                    
                                    Text(post.content ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                    
                                    HStack {
                                        Text(post.category?.name ?? "")
                                            .font(.caption)
                                            .foregroundColor(Color.appTheme)
                                        
                                        Spacer()
                                        
                                        Text(post.timestamp ?? Date(), formatter: itemFormatter)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } else if !searchText.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(Color.appTheme)
                            .padding()
                        
                        Text("検索結果がありません")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(Color.appTheme)
                        
                        Text("検索語を入力してください")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("検索")
            .background(Color.white)
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
        
        // 제목이나 내용에 검색어가 포함된 게시글 검색
        fetchRequest.predicate = NSPredicate(
            format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@",
            searchText, searchText
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Post.timestamp, ascending: false)]
        
        do {
            searchResults = try viewContext.fetch(fetchRequest)
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
        
        isSearching = false
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    SearchView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
