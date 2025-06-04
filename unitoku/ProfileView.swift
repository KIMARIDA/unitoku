import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("username") private var username: String = "匿名"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("プロフィール").foregroundColor(Color.appTheme)) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.appTheme)
                        
                        VStack(alignment: .leading) {
                            Text(username)
                                .font(.headline)
                            
                            Text("匿名ユーザー")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading)
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("統計").foregroundColor(Color.appTheme)) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color.appTheme)
                        Text("自分の投稿")
                        Spacer()
                        Text("0件")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Image(systemName: "bubble.left")
                            .foregroundColor(Color.appTheme)
                        Text("自分のコメント")
                        Spacer()
                        Text("0件")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("アプリ設定").foregroundColor(Color.appTheme)) {
                    Button(action: clearAllData) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(Color.appTheme)
                            Text("全てのデータを初期化")
                                .foregroundColor(Color.appTheme)
                        }
                    }
                    
                    NavigationLink(destination: Text("準備中です...").foregroundColor(Color.appTheme)) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(Color.appTheme)
                            Text("環境設定")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.appTheme)
                        Text("アプリバージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("プロフィール")
            .background(Color.white)
        }
    }
    
    private func clearAllData() {
        // 경고 메시지 표시를 위한 알러트 추가 필요
        let entities = ["Post", "Comment", "Category"]
        
        for entity in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try viewContext.execute(deleteRequest)
                try viewContext.save()
            } catch {
                print("Clear data error: \(error)")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
