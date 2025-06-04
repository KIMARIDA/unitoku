import SwiftUI
import CoreData
import PhotosUI

struct NewPostView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    
    let category: Category
    
    @State private var title = ""
    @State private var content = ""
    @State private var isAnonymous = true
    @State private var selectedImages: [UIImage] = []
    @State private var isShowingImagePicker = false
    @State private var showCategoryPicker = false
    @State private var selectedCategory: Category
    @State private var showingSuccessAlert = false
    @State private var hashtags = ""
    @State private var isHot = false
    @State private var characterCount = 0
    
    // 제목 글자 수 제한 상수 추가
    private let maxTitleLengthNonEnglish = 20
    private let maxTitleLengthEnglish = 30
    
    // アプリのテーマカラー使用
    private let themeColor = Color.appTheme
    
    @FetchRequest(
        entity: Category.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.order, ascending: true)
        ],
        animation: .default)
    private var allCategories: FetchedResults<Category>
    
    init(isPresented: Binding<Bool>, category: Category) {
        self._isPresented = isPresented
        self.category = category
        self._selectedCategory = State(initialValue: category)
    }
    
    // 글자 제한 계산 함수
    private var isTitleTooLong: Bool {
        // 영어 문자가 포함되어 있는지 확인
        let englishCharacterSet = CharacterSet.letters.subtracting(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ一-龠ぁ-ゔァ-ヴー々〆〤"))
        let containsEnglish = title.rangeOfCharacter(from: englishCharacterSet) != nil
        
        if containsEnglish {
            return title.count > maxTitleLengthEnglish
        } else {
            return title.count > maxTitleLengthNonEnglish
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // カテゴリー選択バー
                    HStack {
                        Text(selectedCategory.name ?? "掲示板を選択")
                            .font(.system(size: 15, weight: .medium))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        Toggle("匿名", isOn: $isAnonymous)
                            .toggleStyle(SwitchToggleStyle(tint: themeColor))
                            .fixedSize()
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showCategoryPicker = true
                    }
                    
                    Divider()
                    
                    // タイトル入力 - 글자 수 제한 추가
                    VStack(alignment: .leading, spacing: 5) {
                        TextField("タイトル", text: $title)
                            .font(.system(size: 16, weight: .medium))
                            .padding()
                            .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                            .onChange(of: title) { oldValue, newValue in
                                // 영어인 경우 30자, 그 외 20자로 제한
                                let englishCharacterSet = CharacterSet.letters.subtracting(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ一-龠ぁ-ゔァ-ヴー々〆〤"))
                                let containsEnglish = newValue.rangeOfCharacter(from: englishCharacterSet) != nil
                                
                                let maxLength = containsEnglish ? maxTitleLengthEnglish : maxTitleLengthNonEnglish
                                
                                if newValue.count > maxLength {
                                    title = String(newValue.prefix(maxLength))
                                }
                            }
                        
                        // 글자 수 표시
                        HStack {
                            Spacer()
                            Text("\(title.count)/\(title.rangeOfCharacter(from: CharacterSet.letters.subtracting(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ一-龠ぁ-ゔァ-ヴー々〆〤"))) != nil ? maxTitleLengthEnglish : maxTitleLengthNonEnglish)")
                                .font(.caption)
                                .foregroundColor(isTitleTooLong ? .red : .gray)
                                .padding(.trailing, 10)
                        }
                    }
                    
                    Divider()
                    
                    // 内容入力
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("内容を入力してください")
                                .foregroundColor(Color.gray.opacity(0.7))
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $content)
                            .padding(.horizontal, 8)
                            .frame(minHeight: 200)
                            .onChange(of: content) { oldValue, newValue in
                                characterCount = newValue.count
                            }
                            .opacity(content.isEmpty ? 0.25 : 1)
                    }
                    .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    
                    // 文字数カウンター
                    HStack {
                        Spacer()
                        Text("\(characterCount)/5000")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.trailing)
                    }
                    .padding(.vertical, 4)
                    .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    
                    Divider()
                    
                    // ハッシュタグ入力
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.gray)
                            .padding(.leading)
                        
                        TextField("ハッシュタグ (#タグ #タグ)", text: $hashtags)
                            .font(.system(size: 14))
                    }
                    .padding(.vertical, 10)
                    .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                    
                    Divider()
                    
                    // 画像添付エリア
                    if selectedImages.isEmpty {
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                Text("写真を添付")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                        }
                    } else {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("写真 \(selectedImages.count)枚")
                                    .font(.subheadline)
                                    .padding(.leading)
                                    .padding(.top, 8)
                                
                                Spacer()
                                
                                Button(action: {
                                    isShowingImagePicker = true
                                }) {
                                    Text("追加")
                                        .font(.subheadline)
                                        .foregroundColor(themeColor)
                                }
                                .padding(.trailing)
                                .padding(.top, 8)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(0..<selectedImages.count, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: selectedImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                            
                                            Button(action: {
                                                selectedImages.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                                    .font(.system(size: 18))
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // おすすめ投稿トグル
                    Toggle(isOn: $isHot) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(isHot ? themeColor : .gray)
                            
                            Text("おすすめ投稿")
                                .font(.system(size: 15))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: themeColor))
                    .padding()
                    
                    // 投稿ボタン
                    Button(action: {
                        addPost()
                        isPresented = false
                    }) {
                        Text("投稿する")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(title.isEmpty || content.isEmpty ? Color.gray : themeColor)
                            .cornerRadius(8)
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .padding()
                }
                .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGroupedBackground))
            }
            .navigationBarTitle("新規投稿", displayMode: .inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    isPresented = false
                },
                trailing: Button("投稿") {
                    addPost()
                    isPresented = false
                }
                .disabled(title.isEmpty || content.isEmpty)
            )
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImages: $selectedImages, maxImages: 5)
            }
            .actionSheet(isPresented: $showCategoryPicker) {
                ActionSheet(
                    title: Text("掲示板を選択"),
                    buttons: categoryButtons()
                )
            }
        }
    }
    
    private func categoryButtons() -> [ActionSheet.Button] {
        var buttons = allCategories.map { category in
            ActionSheet.Button.default(Text(category.name ?? "")) {
                selectedCategory = category
            }
        }
        buttons.append(.cancel(Text("キャンセル")))
        return buttons
    }
    
    private func addPost() {
        withAnimation {
            let newPost = Post(context: viewContext)
            newPost.id = UUID()
            newPost.title = title
            newPost.content = content
            
            // ハッシュタグ処理
            if !hashtags.isEmpty {
                let processedHashtags = hashtags
                    .components(separatedBy: " ")
                    .filter { $0.hasPrefix("#") }
                    .joined(separator: " ")
                
                if !processedHashtags.isEmpty {
                    newPost.content = content + "\n\n" + processedHashtags
                }
            }
            
            newPost.timestamp = Date()
            newPost.likeCount = 0
            newPost.dislikeCount = 0
            newPost.viewCount = 0
            newPost.isAnonymous = isAnonymous
            newPost.category = selectedCategory
            
            // Set the author ID for the post
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? "user_1"
            newPost.authorId = currentUserId
            
            // おすすめ投稿情報保存ロジック（実際の実装時に必要に応じて追加）
            
            // 選択した画像があれば保存
            if !selectedImages.isEmpty {
                // PostExtensionに実装したimages属性に画像を保存
                newPost.images = selectedImages
            }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error creating new post: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// 画像選択のためのPhotosUIラッパー
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxImages: Int
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = maxImages
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
    let categories = try? context.fetch(fetchRequest)
    
    return NewPostView(isPresented: .constant(true), category: categories?.first ?? Category())
        .environment(\.managedObjectContext, context)
}
