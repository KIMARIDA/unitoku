//
//  Post+CoreDataProperties.swift
//  
//
//  Created by 김준용 on 6/2/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Post {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Post> {
        return NSFetchRequest<Post>(entityName: "Post")
    }

    @NSManaged public var content: String?
    @NSManaged public var dislikeCount: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var isAnonymous: Bool
    @NSManaged public var likeCount: Int32
    @NSManaged public var timestamp: Date?
    @NSManaged public var title: String?
    @NSManaged public var viewCount: Int32
    @NSManaged public var category: Category?
    @NSManaged public var comments: NSSet?

}

// MARK: Generated accessors for comments
extension Post {

    @objc(addCommentsObject:)
    @NSManaged public func addToComments(_ value: Comment)

    @objc(removeCommentsObject:)
    @NSManaged public func removeFromComments(_ value: Comment)

    @objc(addComments:)
    @NSManaged public func addToComments(_ values: NSSet)

    @objc(removeComments:)
    @NSManaged public func removeFromComments(_ values: NSSet)

}

extension Post : Identifiable {

}
