//
//  DataManager.swift
//  driver_mile_tracker
//
//  Created by Josh Bornstein on 9/11/24.
//

import Foundation
import CoreData
import SwiftUI

class TripDataManager {
    static let shared = TripDataManager()

    // Get the current Core Data context
    private var context: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    func testFunc() -> Trip {
        return Trip(context: context)
    }
    
    func getOrCreateMonthlyData(for monthKey: String) -> MonthlyData {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<MonthlyData> = MonthlyData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "month == %@", monthKey)

        if let result = try? context.fetch(fetchRequest), let existingMonthlyData = result.first {
            return existingMonthlyData
        }

        // Create new monthly data if it doesn't exist
        let newMonthlyData = MonthlyData(context: context)
        newMonthlyData.month = monthKey
        newMonthlyData.carMileage = 0.0 // Default value
        newMonthlyData.averageGasPrice = 0.0 // Default value
        return newMonthlyData
    }

    // Save a trip to Core Data
    func saveTrip(startTime: Date, endTime: Date, distance: Double, earnings: Double?, appName: String?, monthKey: String) {
        let monthlyData = getOrCreateMonthlyData(for: monthKey)
        let newTrip = Trip(context: context)
        newTrip.startTime = startTime
        newTrip.endTime = endTime
        newTrip.distance = distance
        newTrip.earnings = earnings ?? 0.0
        newTrip.appName = appName
        newTrip.monthlyData = monthlyData
        
        monthlyData.addToTrips(newTrip)
        

        do {
            try context.save()
            print("Trip saved successfully")
        } catch {
            print("Failed to save trip: \(error.localizedDescription)")
        }
    }

    // Fetch all trips from Core Data
    func fetchTrips() -> [Trip] {
        let fetchRequest: NSFetchRequest<Trip> = Trip.fetchRequest()

        do {
            let trips = try context.fetch(fetchRequest)
            return trips
        } catch {
            print("Failed to fetch trips: \(error.localizedDescription)")
            return []
        }
    }

    // Delete a trip from Core Data
    func deleteTrip(_ trip: Trip) {
        context.delete(trip)

        do {
            try context.save()
            print("Trip deleted successfully")
        } catch {
            print("Failed to delete trip: \(error.localizedDescription)")
        }
    }
}
