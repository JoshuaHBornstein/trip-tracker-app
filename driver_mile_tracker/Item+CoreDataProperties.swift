//
//  Item+CoreDataProperties.swift
//  
//
//  Created by Josh Bornstein on 9/14/24.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var name: String?
    @NSManaged public var timeStamp: Date?

}
