import Foundation
import SwiftUI
import CoreData

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
    @Published var currentUserID = UUID().uuidString
    
    init() {
        loadSampleData()
    }
    
    func loadSampleData() {
        // Create some sample anonymous users
        let anonymousUser1 = "匿名ユーザー1"
        let anonymousUser2 = "匿名ユーザー2"
        let anonymousUser3 = "匿名ユーザー3"
        
        // Create sample chat rooms
        let room1 = ChatRoom(
            name: "匿名チャット1",
            isGroup: false,
            participants: [currentUserID, anonymousUser1],
            lastMessage: "こんにちは！",
            lastMessageTime: Date().addingTimeInterval(-3600),
            unreadCount: 1
        )
        
        let room2 = ChatRoom(
            name: "授業グループチャット",
            isGroup: true,
            participants: [currentUserID, anonymousUser1, anonymousUser2, anonymousUser3],
            lastMessage: "課題について質問があります",
            lastMessageTime: Date().addingTimeInterval(-7200),
            unreadCount: 3
        )
        
        chatRooms = [room1, room2]
        
        // Add sample messages
        messages[room1.id] = [
            ChatMessage(content: "こんにちは！", senderID: anonymousUser1, isCurrentUser: false, timestamp: Date().addingTimeInterval(-3600)),
            ChatMessage(content: "初めまして！", senderID: currentUserID, isCurrentUser: true, timestamp: Date().addingTimeInterval(-3500))
        ]
        
        messages[room2.id] = [
            ChatMessage(content: "みなさん、こんにちは", senderID: anonymousUser1, isCurrentUser: false, timestamp: Date().addingTimeInterval(-8000)),
            ChatMessage(content: "今日の授業について話しましょう", senderID: anonymousUser2, isCurrentUser: false, timestamp: Date().addingTimeInterval(-7800)),
            ChatMessage(content: "了解です！", senderID: currentUserID, isCurrentUser: true, timestamp: Date().addingTimeInterval(-7600)),
            ChatMessage(content: "課題について質問があります", senderID: anonymousUser3, isCurrentUser: false, timestamp: Date().addingTimeInterval(-7200))
        ]
    }
    
    func sendMessage(content: String, roomID: UUID) {
        let newMessage = ChatMessage(content: content, senderID: currentUserID, isCurrentUser: true)
        
        if messages[roomID] != nil {
            messages[roomID]?.append(newMessage)
        } else {
            messages[roomID] = [newMessage]
        }
        
        // Update last message in chat room
        if let index = chatRooms.firstIndex(where: { $0.id == roomID }) {
            var updatedRoom = chatRooms[index]
            updatedRoom.lastMessage = content
            updatedRoom.lastMessageTime = Date()
            chatRooms[index] = updatedRoom
        }
    }
    
    func createNewPrivateChat(with name: String) -> UUID {
        let roomID = UUID()
        let newRoom = ChatRoom(
            id: roomID,
            name: name,
            isGroup: false,
            participants: [currentUserID, name]
        )
        
        chatRooms.append(newRoom)
        messages[roomID] = []
        return roomID
    }
    
    func createNewGroupChat(name: String, participants: [String]) -> UUID {
        var allParticipants = participants
        allParticipants.append(currentUserID)
        
        let roomID = UUID()
        let newRoom = ChatRoom(
            id: roomID,
            name: name,
            isGroup: true,
            participants: allParticipants
        )
        
        chatRooms.append(newRoom)
        messages[roomID] = []
        return roomID
    }
}