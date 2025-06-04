//
//  Category+CoreDataProperties.swift
//  
//
//  Created by 김준용 on 6/2/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var icon: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var order: Int16
    @NSManaged public var posts: NSSet?

}

// MARK: Generated accessors for posts
extension Category {

    @objc(addPostsObject:)
    @NSManaged public func addToPosts(_ value: Post)

    @objc(removePostsObject:)
    @NSManaged public func removeFromPosts(_ value: Post)

    @objc(addPosts:)
    @NSManaged public func addToPosts(_ values: NSSet)

    @objc(removePosts:)
    @NSManaged public func removeFromPosts(_ values: NSSet)

}

extension Category : Identifiable {

}
