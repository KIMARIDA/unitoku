import Foundation
import SwiftUI
import CoreData
import FirebaseFirestore
import FirebaseCore

// Message model
struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let timestamp: Date
    let senderID: String
    let isCurrentUser: Bool
    
    init(id: UUID = UUID(), content: String, senderID: String, isCurrentUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.senderID = senderID
        self.isCurrentUser = isCurrentUser
        self.timestamp = timestamp
    }
}

// Chat room model
struct ChatRoom: Identifiable {
    let id: UUID
    let name: String
    let isGroup: Bool
    let participants: [String]
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    
    init(id: UUID = UUID(), name: String, isGroup: Bool, participants: [String], lastMessage: String = "", lastMessageTime: Date = Date(), unreadCount: Int = 0) {
        self.id = id
        self.name = name
        self.isGroup = isGroup
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
    }
}

// View model for chat functionality
class ChatViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var messages: [UUID: [ChatMessage]] = [:]
    @Published var currentUserID: String = UserDefaults.standard.string(forKey: "currentUserId") ?? UUID().uuidString
    
    private var chatRoomsListener: ListenerRegistration?
    private var messageListeners: [UUID: ListenerRegistration] = [:]
    
    init() {
        observeChatRooms()
    }
    
    deinit {
        chatRoomsListener?.remove()
        messageListeners.values.forEach { $0.remove() }
    }
    
    // Firestore 채팅방 실시간 구독
    func observeChatRooms() {
        chatRoomsListener?.remove()
        chatRoomsListener = FirebaseManager.shared.observeChatRooms(for: currentUserID) { [weak self] rooms in
            DispatchQueue.main.async {
                self?.chatRooms = rooms
            }
        }
    }
    
    // Firestore 메시지 실시간 구독
    func observeMessages(for roomId: UUID) {
        // 기존 리스너 제거
        messageListeners[roomId]?.remove()
        messageListeners[roomId] = FirebaseManager.shared.observeMessages(roomId: roomId) { [weak self] msgs in
            DispatchQueue.main.async {
                self?.messages[roomId] = msgs
            }
        }
    }
    
    // 메시지 전송
    func sendMessage(content: String, roomID: UUID) {
        FirebaseManager.shared.sendMessage(roomId: roomID, content: content)
    }
    
    // 채팅방 생성 (개인)
    func createNewPrivateChat(with name: String, completion: @escaping (UUID?) -> Void) {
        let participants = [currentUserID, name]
        FirebaseManager.shared.createChatRoom(name: name, isGroup: false, participants: participants) { roomId in
            completion(roomId)
        }
    }
    
    // 채팅방 생성 (그룹)
    func createNewGroupChat(name: String, participants: [String], completion: @escaping (UUID?) -> Void) {
        var allParticipants = participants
        allParticipants.append(currentUserID)
        FirebaseManager.shared.createChatRoom(name: name, isGroup: true, participants: allParticipants) { roomId in
            completion(roomId)
        }
    }
}