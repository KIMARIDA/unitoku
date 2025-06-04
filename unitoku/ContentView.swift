//
//  ContentView.swift
//  unitoku
//
//  Created by 김준용 on 5/29/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newPostContent: String = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Post.timestamp, ascending: false)],
        animation: .default)
    private var posts: FetchedResults<Post>

    var body: some View {
        NavigationView {
            VStack {
                // 投稿エリア
                VStack(alignment: .leading) {
                    Text("匿名で投稿")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    HStack {
                        TextField("何を考えていますか？", text: $newPostContent)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Button(action: addPost) {
                            Text("投稿")
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.appTheme)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .disabled(newPostContent.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                
                // 投稿リスト
                List {
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.content ?? "")
                                .font(.body)
                                .padding(.top, 4)
                            
                            HStack {
                                Text(post.timestamp ?? Date(), formatter: postTimeFormatter)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(Color.appTheme)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deletePosts)
                }
            }
            .navigationTitle("ユニトク")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .accentColor(Color.appTheme)
                }
            }
        }
        .accentColor(Color.appTheme)
    }

    private func addPost() {
        withAnimation {
            let newPost = Post(context: viewContext)
            newPost.timestamp = Date()
            newPost.content = newPostContent

            do {
                try viewContext.save()
                newPostContent = "" // 投稿後に入力フィールドを初期化
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deletePosts(offsets: IndexSet) {
        withAnimation {
            offsets.map { posts[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let postTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
