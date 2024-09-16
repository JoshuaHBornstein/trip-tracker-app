//
//  TripHistoryView.swift
//  driver_mile_tracker
//
//  Created by Josh Bornstein on 9/11/24.
//

import SwiftUI
import CoreData

/*struct Trip: Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date
    var distance: Double // miles
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}*/

struct TripGroupByDate: Identifiable {
    var id = UUID()
    var date: Date
    var trips: [Trip]
    var distance: Double
}

extension Array where Element == Trip {
    func groupedByYearMonthDay() -> [Int: [Int: [Date: [Trip]]]] {
        var groupedTrips = [Int: [Int: [Date: [Trip]]]]()

        let calendar = Calendar.current

        for trip in self {
            let year = calendar.component(.year, from: trip.startTime!)
            let month = calendar.component(.month, from: trip.startTime!)
            let day = calendar.startOfDay(for: trip.startTime!)

            if groupedTrips[year] == nil {
                groupedTrips[year] = [:]
            }

            if groupedTrips[year]?[month] == nil {
                groupedTrips[year]?[month] = [:]
            }

            if groupedTrips[year]?[month]?[day] == nil {
                groupedTrips[year]?[month]?[day] = []
            }

            groupedTrips[year]?[month]?[day]?.append(trip)
        }

        return groupedTrips
    }
}

struct TripHistoryView: View {
    @FetchRequest(
        entity: Trip.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startTime, ascending: true)]
    ) var trips: FetchedResults<Trip>
    //@State private var trips: [Trip] = []
    @State private var showingStats = false
    
    //@State private var groupedTrips = [Int: [Int: [Date: [Trip]]]]()

    var body: some View {
        let groupedTrips = Array(trips).groupedByYearMonthDay()
        
        let years = groupedTrips.keys.sorted()
        NavigationView {
            List(years, id: \.self) { year in
                NavigationLink(destination: MonthView(year: year, tripsByMonth: groupedTrips[year]!)) {
                    Text("\(year)")
                }
            }
            .navigationTitle("Trip History")
        }
        /*.onAppear {
            trips = TripDataManager.shared.fetchTrips()
        }*/
    }
}

struct MonthView: View {
    var year: Int
    var tripsByMonth: [Int: [Date: [Trip]]]

    var body: some View {
        let months = tripsByMonth.keys.sorted()

        List(months, id: \.self) { month in
            NavigationLink(destination: DayView(year: year, month: month, tripsByDay: tripsByMonth[month]!)) {
                Text("\(monthName(from: month))")
            }
        }
        .navigationTitle("\(year)")
    }

    func monthName(from month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.monthSymbols[month - 1]
    }
}

struct DayView: View {
    var year: Int
    var month: Int
    var tripsByDay: [Date: [Trip]]
    let defaultCarMileage: String = "25.0" // mpg
    let defaultGasPrice: String = "3.50"  // $/gal
    @State private var carMileage: String = "25" //default (mpg)
    @State private var gasPrice: String = "3.50" //default (usd/gal)
    @State private var isEditingMileage = false
    @State private var isEditingGasPrice = false
    @State private var showingStats = false

    var body: some View {
        let days = tripsByDay.keys.sorted()
        
        ZStack{
            VStack {
                HStack {
                    Text("MPG: ")
                    if isEditingMileage {
                        TextField("", text: $carMileage, onCommit: { isEditingMileage = false
                            storeCarMileage()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 50)
                    } else {
                        Text("\(carMileage)")
                            .onTapGesture {
                                isEditingMileage = true
                            }
                    }
                    
                    Text(", $/Gal: ")
                    if isEditingGasPrice {
                        TextField("", text: $gasPrice, onCommit: { isEditingGasPrice = false
                            storeGasPrice()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 50)
                    } else {
                        Text("\(gasPrice)")
                            .onTapGesture {
                                isEditingGasPrice = true
                            }
                    }
                }
                .font(.title2)
                .padding()
                
                List(days, id: \.self) { day in
                    NavigationLink(destination: TripDetailView(trips: tripsByDay[day]!, carMileage: mileageValue(), gasPrice: gasPriceValue())) {
                        Text(formattedDate(day))
                    }
                }
                .navigationTitle("\(monthName(from: month)) \(year)")
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingStats.toggle()
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                    .sheet(isPresented: $showingStats) {
                        StatsView(tripsByDay: tripsByDay, carMileage: mileageValue(), gasPrice: gasPriceValue())
                    }
                }
            }
        }
        .onAppear(){
            loadStoredValues()
        }
    }
    func storeCarMileage() {
        let key = carMileageKey(for: month, year: year)
        UserDefaults.standard.set(carMileage, forKey: key)
    }

    func storeGasPrice() {
        let key = gasPriceKey(for: month, year: year)
        UserDefaults.standard.set(gasPrice, forKey: key)
    }
    func carMileageKey(for month: Int, year: Int) -> String {
        return "carMileage_\(year)_\(month)"
    }
    
    func gasPriceKey(for month: Int, year: Int) -> String {
        return "gasPrice_\(year)_\(month)"
    }
    
    func mileageValue() -> Double {
        return Double(carMileage) ?? Double(defaultCarMileage) ?? 25.0
    }

    func gasPriceValue() -> Double {
        return Double(gasPrice) ?? Double(defaultGasPrice) ?? 3.50
    }
    
    func loadStoredValues() {
        let mileageKey = carMileageKey(for: month, year: year)
        let priceKey = gasPriceKey(for: month, year: year)

        carMileage = UserDefaults.standard.string(forKey: mileageKey) ?? defaultCarMileage
        gasPrice = UserDefaults.standard.string(forKey: priceKey) ?? defaultGasPrice
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func monthName(from month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.monthSymbols[month - 1]
    }
}

struct TripDetailView: View {
    //var trips: [Trip]
    //@State private var trips: FetchedResults<Trip>
    var carMileage: Double
    var gasPrice: Double
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTrip: Trip?
    //@State private var showingEditPopup = false
    @State private var isAddingTrip = false
    @State private var showingStats = false
    @State private var localTrips: [Trip] // State variable to track local trip changes
    @State private var pendingDeletions: [Trip] = []

    init(trips: [Trip], carMileage: Double, gasPrice: Double) {
        //self.trips = trips
        self.carMileage = carMileage
        self.gasPrice = gasPrice
        self._localTrips = State(initialValue: trips) // Initialize localTrips with passed trips
    }

    var body: some View {
        List {
            ForEach(localTrips) { trip in
                VStack(alignment: .leading) {
                    let duration: TimeInterval = trip.endTime!.timeIntervalSince(trip.startTime!)
                    let formattedDuration: String = String(format: "%02d:%02d", Int(duration) / 3600, (Int(duration) % 3600) / 60)
                    
                    let gasCost = calculateGasCost(for: trip)
                    let netEarnings = trip.earnings - gasCost
                    
                    Text("App Name: \(trip.appName ?? "Unknown")") // Show app name
                    Text("Start: \(formattedTime(trip.startTime!))")
                    Text("End: \(formattedTime(trip.endTime!))")
                    Text("Duration: \(formattedDuration)")
                    Text("Distance: \(trip.distance, specifier: "%.2f") miles")
                    Text("Earnings: $\(trip.earnings, specifier: "%.2f")")
                    Text("Estimated Gas Cost: $\(gasCost, specifier: "%.2f")")
                    Text("Net Earnings: $\(netEarnings, specifier: "%.2f")")
                }
                .swipeActions {
                    Button("Edit") {
                        selectedTrip = trip
                        //print(selectedTrip)
                        //selectedTrip = nil
                    }
                    .tint(.blue)
                    
                    Button("Delete") {
                        deleteTrip(trip: trip)
                    }
                    .tint(.red)
                }
            }
        }
        /*.sheet(isPresented: $showingEditPopup) {
            if let tripToEdit = selectedTrip {
                EditTripPopup(trip: tripToEdit) { updatedTrip in
                    try? viewContext.save() // Save changes to Core Data
                    showingEditPopup = false // Dismiss the popup after saving
                }
            } else {
                Text("No Trip Selected")
            }
        }*/
        .sheet(item: $selectedTrip) { tripToEdit in
            EditTripPopup(trip: tripToEdit) { updatedTrip in
                try? viewContext.save()
                selectedTrip = nil
                if let index = localTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
                    localTrips[index] = updatedTrip
                }
                //showingEditPopup = false
            } onCancel: {
                selectedTrip = nil
            }
        }
        .navigationTitle("Trip Details")
        .onDisappear {
            savePendingDeletions() // Save changes when the user leaves the page
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            savePendingDeletions() // Save changes when the app is backgrounded or closed
        }
    }
    
    func deleteTrip(trip: Trip) {
        if let index = localTrips.firstIndex(of: trip) {
            localTrips.remove(at: index)
        }
        pendingDeletions.append(trip)
    }
    
    func savePendingDeletions() {
        for trip in pendingDeletions {
            viewContext.delete(trip) // Delete from Core Data
        }
        try? viewContext.save() // Save the changes to Core Data
        pendingDeletions.removeAll() // Clear the pending deletions list
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func calculateGasCost(for trip: Trip) -> Double {
        return (trip.distance / carMileage) * gasPrice
    }
}

import SwiftUI

struct EditTripPopup: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Intermediate state variables
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var distance: Double
    @State private var earnings: Double
    
    var trip: Trip
    var onSave: (Trip) -> Void
    var onCancel: () -> Void

    init(trip: Trip, onSave: @escaping (Trip) -> Void, onCancel: @escaping () -> Void) {
        self.trip = trip
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize the state variables with existing trip values
        _startTime = State(initialValue: trip.startTime ?? Date())
        _endTime = State(initialValue: trip.endTime ?? Date())
        _distance = State(initialValue: trip.distance)
        _earnings = State(initialValue: trip.earnings)
    }

    var body: some View {
        NavigationView {
            Form {
                // Use the intermediate state variables for binding
                DatePicker("Start Time", selection: $startTime)
                DatePicker("End Time", selection: $endTime)
                
                TextField("Miles Driven", value: $distance, format: .number)
                    .keyboardType(.decimalPad)
                
                TextField("Earnings", value: $earnings, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Edit Trip")
            .navigationBarItems(
                leading: Button("Cancel") {
                    onCancel()
                },
                trailing: Button("Save") {
                    // Update the trip object with the edited values
                    trip.startTime = startTime
                    trip.endTime = endTime
                    trip.distance = distance
                    trip.earnings = earnings

                    // Save the changes
                    onSave(trip)
                    try? viewContext.save()
                }
            )
        }
    }
}

struct TestPopup: View {
    @State private var testStartDate: Date = Date()
    @State private var testEndDate: Date = Date()
    @State private var milesDriven: Double = 0.0
    @State private var earnings: Double = 0.0

    var body: some View {
        NavigationView {
            Form {
                // Test DatePicker for Start Time
                DatePicker("Start Time", selection: $testStartDate)
                
                // Test DatePicker for End Time
                DatePicker("End Time", selection: $testEndDate)
                
                // Test TextField for Miles Driven
                TextField("Miles Driven", value: $milesDriven, format: .number)
                    .keyboardType(.decimalPad)
                
                // Test TextField for Earnings
                TextField("Earnings", value: $earnings, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Test Popup")
            .navigationBarItems(
                leading: Button("Cancel") {
                    // Dismiss logic if needed
                },
                trailing: Button("Save") {
                    // Print test data to ensure inputs work
                    print("Start Time: \(testStartDate)")
                    print("End Time: \(testEndDate)")
                    print("Miles Driven: \(milesDriven)")
                    print("Earnings: \(earnings)")
                }
            )
        }
    }
}



struct StatsView: View {
    var tripsByDay: [Date: [Trip]]
    var carMileage: Double
    var gasPrice: Double

    var body: some View {
        VStack(alignment: .leading) {
            let stats = calculateStats()

            Text("Total Trips: \(stats.totalTrips)")
            Text("Total Time: \(formattedTime(stats.totalTime))")
            Text("Total Distance: \(stats.totalDistance, specifier: "%.2f") miles")
            Text("Total Earnings: $\(stats.totalEarnings, specifier: "%.2f")")
            Text("Total Earnings - Gas: $\(stats.netEarnings, specifier: "%.2f")")
            Text("Hourly Earnings (minus gas): $\(stats.hourlyEarnings, specifier: "%.2f")")

            Spacer()
        }
        .padding()
        .navigationTitle("Trip Stats")
    }

    // Function to calculate all statistics
    func calculateStats() -> (totalTrips: Int, totalTime: TimeInterval, totalDistance: Double, totalEarnings: Double, netEarnings: Double, hourlyEarnings: Double) {
        var totalTrips = 0
        var totalTime: TimeInterval = 0
        var totalDistance: Double = 0
        var totalEarnings: Double = 0
        var totalGasCost: Double = 0

        for (_, trips) in tripsByDay {
            for trip in trips {
                totalTrips += 1
                totalTime += trip.endTime!.timeIntervalSince(trip.startTime!)
                totalDistance += trip.distance
                totalEarnings += trip.earnings
                totalGasCost += calculateGasCost(for: trip)
            }
        }

        let netEarnings = totalEarnings - totalGasCost
        let hourlyEarnings = totalTime > 0 ? netEarnings / (totalTime / 3600) : 0

        return (totalTrips, totalTime, totalDistance, totalEarnings, netEarnings, hourlyEarnings)
    }

    // Gas cost calculation based on distance, car mileage, and gas price
    func calculateGasCost(for trip: Trip) -> Double {
        return (trip.distance / carMileage) * gasPrice
    }

    // Format time in hours and minutes
    func formattedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}


struct TripHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        TripHistoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        
    }
}

