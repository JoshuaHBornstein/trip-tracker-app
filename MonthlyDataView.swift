//
//  MonthlyDataView.swift
//  driver_mile_tracker
//
//  Created by Josh Bornstein on 9/14/24.
//

import SwiftUI
import CoreData

struct MonthlyDataView: View {
    @ObservedObject var monthlyData: MonthlyData
    
    var body: some View {
        Form {
            Section(header: Text("Car Mileage")) {
                TextField("Miles per gallon", value: $monthlyData.carMileage, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
            }
            Section(header: Text("Average Gas Price")) {
                TextField("Gas Price", value: $monthlyData.averageGasPrice, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle("Monthly Data")
        .onDisappear {
            // Save changes when user exits the screen
            try? monthlyData.managedObjectContext?.save()
        }
    }
}
