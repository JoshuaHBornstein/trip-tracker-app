//
//  MonthlyData+CoreDataProperties.swift
//  
//
//  Created by Josh Bornstein on 9/14/24.
//
//

import Foundation
import CoreData


extension MonthlyData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MonthlyData> {
        return NSFetchRequest<MonthlyData>(entityName: "MonthlyData")
    }

    @NSManaged public var month: String?
    @NSManaged public var carMileage: Double
    @NSManaged public var averageGasPrice: Double
    @NSManaged public var trips: NSSet?

}

// MARK: Generated accessors for trips
extension MonthlyData {

    @objc(addTripsObject:)
    @NSManaged public func addToTrips(_ value: Trip)

    @objc(removeTripsObject:)
    @NSManaged public func removeFromTrips(_ value: Trip)

    @objc(addTrips:)
    @NSManaged public func addToTrips(_ values: NSSet)

    @objc(removeTrips:)
    @NSManaged public func removeFromTrips(_ values: NSSet)

}
