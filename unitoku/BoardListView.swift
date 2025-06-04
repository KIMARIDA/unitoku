import SwiftUI
import CoreData

struct BoardListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingNewPostSheet = false
    @State private var selectedCategory: Category? = nil
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.order, ascending: true)
        ],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    NavigationLink(destination: CategoryView(category: category)) {
                        HStack {
                            Image(systemName: category.icon ?? "list.bullet")
                                .foregroundColor(Color.appTheme)
                                .imageScale(.large)
                            
                            Text(category.name ?? "掲示板")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(category.posts?.count ?? 0)件の投稿")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    .contextMenu {
                        Button(action: {
                            selectedCategory = category
                            showingNewPostSheet = true
                        }) {
                            Label("この掲示板に投稿", systemImage: "square.and.pencil")
                        }
                    }
                }
            }
            .navigationTitle("掲示板")
            .listStyle(InsetGroupedListStyle())
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if let firstCategory = categories.first {
                            selectedCategory = firstCategory
                        }
                        showingNewPostSheet = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color.appTheme)
                    }
                }
            }
            .sheet(isPresented: $showingNewPostSheet) {
                if let category = selectedCategory {
                    NewPostView(isPresented: $showingNewPostSheet, category: category)
                }
            }
        }
    }
}

struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.order, ascending: true)
        ],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    var body: some View {
        VStack {
            ForEach(categories) { category in
                NavigationLink(destination: CategoryView(category: category)) {
                    HStack {
                        Image(systemName: category.icon ?? "list.bullet")
                            .foregroundColor(Color.appTheme)
                        
                        Text(category.name ?? "")
                            .font(.body)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.appTheme.opacity(0.7))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 3)
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    BoardListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
