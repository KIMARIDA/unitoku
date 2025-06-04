//
//  Comment+CoreDataProperties.swift
//  
//
//  Created by 김준용 on 6/2/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Comment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comment> {
        return NSFetchRequest<Comment>(entityName: "Comment")
    }

    @NSManaged public var content: String?
    @NSManaged public var dislikeCount: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var likeCount: Int32
    @NSManaged public var timestamp: Date?
    @NSManaged public var post: Post?

}

extension Comment : Identifiable {

}
