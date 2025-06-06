import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingNewChatSheet = false
    @State private var chatType: ChatType = .private
    
    enum ChatType {
        case `private`, group
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.chatRooms) { room in
                    NavigationLink(destination: ChatDetailView(room: room, viewModel: viewModel)) {
                        HStack {
                            // Chat icon (group or individual)
                            Image(systemName: room.isGroup ? "person.3.fill" : "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(8)
                                .background(Color.appTheme.opacity(0.2))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(room.name)
                                    .font(.headline)
                                
                                Text(room.lastMessage.isEmpty ? "新しい会話" : room.lastMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatDate(room.lastMessageTime))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if room.unreadCount > 0 {
                                    Text("\(room.unreadCount)")
                                        .font(.caption)
                                        .padding(5)
                                        .background(Color.appTheme)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("匿名チャット")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            self.chatType = .private
                            self.showingNewChatSheet = true
                        }) {
                            Label("個人チャット", systemImage: "person")
                        }
                        
                        Button(action: {
                            self.chatType = .group
                            self.showingNewChatSheet = true
                        }) {
                            Label("グループチャット", systemImage: "person.3")
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewChatSheet) {
                if chatType == .private {
                    NewPrivateChatView(viewModel: viewModel, isPresented: $showingNewChatSheet)
                } else {
                    NewGroupChatView(viewModel: viewModel, isPresented: $showingNewChatSheet)
                }
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

struct ChatDetailView: View {
    let room: ChatRoom
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.messages[room.id] ?? []) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .onChange(of: viewModel.messages[room.id]?.count ?? 0) { _ in
                        if let messages = viewModel.messages[room.id], let lastMessage = messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let messages = viewModel.messages[room.id], let lastMessage = messages.last {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input area
            HStack {
                TextField("メッセージを入力...", text: $messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .padding(.leading)
                    .focused($isTextFieldFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(messageText.isEmpty ? Color.gray : Color.appTheme)
                        .clipShape(Circle())
                }
                .disabled(messageText.isEmpty)
                .padding(.trailing)
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 5, y: -5)
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if room.isGroup {
                    Menu {
                        ForEach(room.participants.filter { $0 != viewModel.currentUserID }, id: \.self) { participant in
                            Text(participant)
                        }
                    } label: {
                        Image(systemName: "person.3")
                    }
                }
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendMessage(content: messageText, roomID: room.id)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 2) {
                if !message.isCurrentUser {
                    Text(message.senderID)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
                
                Text(message.content)
                    .padding(10)
                    .background(message.isCurrentUser ? Color.appTheme : Color(.systemGray5))
                    .foregroundColor(message.isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatMessageTime(message.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isCurrentUser {
                Spacer()
            }
        }
        .id(message.id)
    }
    
    func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct NewPrivateChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool
    @State private var recipientName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新しい匿名チャット")) {
                    TextField("相手の名前", text: $recipientName)
                }
                
                Section {
                    Button("チャットを始める") {
                        if !recipientName.isEmpty {
                            let roomID = viewModel.createNewPrivateChat(with: recipientName)
                            isPresented = false
                        }
                    }
                    .disabled(recipientName.isEmpty)
                }
            }
            .navigationTitle("新しいチャット")
            .navigationBarItems(trailing: Button("キャンセル") {
                isPresented = false
            })
        }
    }
}

struct NewGroupChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool
    @State private var groupName = ""
    @State private var newMember = ""
    @State private var members = [String]()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("グループ情報")) {
                    TextField("グループ名", text: $groupName)
                }
                
                Section(header: Text("メンバー")) {
                    ForEach(members, id: \.self) { member in
                        Text(member)
                    }
                    .onDelete(perform: deleteMember)
                    
                    HStack {
                        TextField("メンバーを追加", text: $newMember)
                        
                        Button(action: addMember) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newMember.isEmpty)
                    }
                }
                
                Section {
                    Button("グループ作成") {
                        if !groupName.isEmpty && !members.isEmpty {
                            let roomID = viewModel.createNewGroupChat(name: groupName, participants: members)
                            isPresented = false
                        }
                    }
                    .disabled(groupName.isEmpty || members.isEmpty)
                }
            }
            .navigationTitle("新しいグループ")
            .navigationBarItems(trailing: Button("キャンセル") {
                isPresented = false
            })
        }
    }
    
    func addMember() {
        if !newMember.isEmpty && !members.contains(newMember) {
            members.append(newMember)
            newMember = ""
        }
    }
    
    func deleteMember(at offsets: IndexSet) {
        members.remove(atOffsets: offsets)
    }
}

#Preview {
    ChatView()
}
