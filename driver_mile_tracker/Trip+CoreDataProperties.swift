//
//  Trip+CoreDataProperties.swift
//  
//
//  Created by Josh Bornstein on 9/14/24.
//
//

import Foundation
import CoreData


extension Trip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var distance: Double
    @NSManaged public var endTime: Date?
    @NSManaged public var startTime: Date?
    @NSManaged public var earnings: Double
    @NSManaged public var appName: String?
    @NSManaged public var monthlyData: MonthlyData?

}
