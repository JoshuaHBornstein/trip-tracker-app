//
//  ContentView.swift
//  driver_mile_tracker
//
//  Created by Josh Bornstein on 9/11/24.
//

import SwiftUI
import CoreData
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var tracking = false
    @State private var currentStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var currentDistance: Double = 0.0
    @State private var timer: Timer?
    @State private var displayTime: String = "00:00"
    @State private var tripNotificationEnabled = false
    @State private var appName = "None"
    //@State private var projectedEarnings: Double = 0.0
    @State private var earnings = 0.0
    @State private var showAppNameInputPopup: Bool = false
    @State private var showEarningsInputPopup: Bool = false
    //@State private var previousAppNames: [String] = []
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    if let location = locationManager.location {
                        MapView(coordinate: location.coordinate)
                            .frame(height: 300)
                    } else {
                        Text("Location not available")
                            .padding()
                    }
                    
                    Text("Miles Driven: \(locationManager.totalDistance, specifier: "%.2f") miles")
                        .font(.largeTitle)
                        .padding()
                    
                    Text("Elapsed Time: \(displayTime)")
                        .font(.title2)
                        .padding()
                    
                    HStack {
                        Button(action: {
                            showAppNameInputPopup = true
                        }) {
                            Text("Start")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(tracking)
                        
                        Button(action: {
                            showEarningsInputPopup = true
                        }) {
                            Text("Stop")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(!tracking)
                    }
                    .padding()
                    
                    // Navigation to Trip History View
                    NavigationLink(destination: TripHistoryView()) {
                        Text("View Trip History")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
                .navigationTitle("Mileage Tracker")
                .onAppear{
                    locationManager.requestAuthorization()
                }
            }
            if showAppNameInputPopup {
                CustomPopupDialog(
                    title: "Select Driving App",
                    content: {
                        AppNameInputPopup(
                            appName: $appName,
                            //text field here "projected earnings"
                            earnings: $earnings,
                            onSave: {
                                showAppNameInputPopup = false
                                startTracking() // Start tracking when app name is saved
                            },
                            onCancel: {
                                showAppNameInputPopup = false
                                //appName = "None"
                            }
                        )
                    }
                )
            }
            if showEarningsInputPopup {
                CustomPopupDialog(
                    title: "Update Earnings",
                    content: {
                        EarningsInputPopup(
                            earnings: $earnings,
                            onSave: {
                                showEarningsInputPopup = false
                                stopTracking()
                                saveCompletedTrip() // Save trip when earnings are saved
                            },
                            onCancel: {
                                showEarningsInputPopup = false
                                //keep tracking when canceled
                            }
                        )
                    }
                )
            }
        }
    }
    func startTracking() {
        locationManager.startTracking()
        tracking = true
        currentStartTime = Date() // Set the current start time
        elapsedTime = 0 // Reset elapsed time
        startTimer() // Start the timer to update elapsed time
    }

        // Stop tracking function
    func stopTracking() {
        locationManager.stopTracking()
        tracking = false
        stopTimer() // Stop the timer
        //showEarningsInputPopup = true
        //saveCompletedTrip() // Save the trip when tracking stops
    }

    // Function to start the timer
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard let startTime = currentStartTime else { return }
            elapsedTime = Date().timeIntervalSince(startTime)
            displayTime = formatTime(elapsedTime)
        }
    }

        // Function to stop the timer
   func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

        // Format time interval as hh:mm:ss
    func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func generateMonthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-yyyy"
        return formatter.string(from: date)
    }
    
    func saveCompletedTrip() {
        guard let startTime = currentStartTime else { return }
        let endTime = Date()
        let distance = locationManager.totalDistance
        let monthKey = generateMonthKey(for: startTime)

        TripDataManager.shared.saveTrip(startTime: startTime, endTime: endTime, distance: distance, earnings: earnings, appName: appName, monthKey: monthKey)

        // Reset start time and elapsed time for the next trip
        currentStartTime = nil
        elapsedTime = 0
        displayTime = "00:00:00"
    }
    
}


struct MapView: View {
    var coordinate: CLLocationCoordinate2D
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true)
            .onAppear {
                setRegion(coordinate)
            }
    }
    
    private func setRegion(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}

struct CustomPopupDialog<Content: View>: View {
    var title: String
    var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()
            content
        }
        .frame(maxWidth: 300)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .padding()
    }
}

// App Name Input Pop-Up
struct AppNameInputPopup: View {
    @Binding var appName: String
    @Binding var earnings: Double
    @State private var previousAppNames: [String] = []
    @State private var selectedAppName: String = "None"
    @State private var isEnteringNewAppName: Bool = true
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack {
            List {
                HStack {
                    Text("Enter New")
                    Spacer()
                    if selectedAppName == "Enter New" {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedAppName = "Enter New"
                    isEnteringNewAppName = true
                }
                HStack {
                    Text("None")
                    Spacer()
                    if selectedAppName == "None" {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedAppName = "None"
                    appName = "None"
                    isEnteringNewAppName = false
                }
                ForEach(previousAppNames, id: \.self) { app in
                    HStack {
                        Text(app)
                        Spacer()
                        if selectedAppName == app {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAppName = app
                        appName = app
                        isEnteringNewAppName = false
                    }
                }
                .onDelete(perform: deleteAppName)
            }
            .listStyle(InsetGroupedListStyle())
                
            if isEnteringNewAppName {
                TextField("App Name", text: $appName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            }
            Text("Projected Earnings:")
                .font(.headline)
            TextField("Projected Earnings", value: $earnings, format: .currency(code: "USD"))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()
            

            HStack {
                Button(action: {
                    saveAppName(appName)
                    saveLastUsedAppName(appName)
                    onSave()
                }) {
                    Text("Save")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: onCancel) {
                    Text("Cancel")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear(){
            previousAppNames = fetchStoredAppNames()
            if let lastUsedAppName = fetchLastUsedAppName() {
                selectedAppName = lastUsedAppName
                appName = lastUsedAppName
                isEnteringNewAppName = false
            }
        }
    }
    
    func saveAppName(_ newAppName: String) {
        guard newAppName != "Enter New" && newAppName != "None" else { return }
            
        var storedAppNames = fetchStoredAppNames()
        if !storedAppNames.contains(newAppName) {
            storedAppNames.append(newAppName)
            UserDefaults.standard.set(storedAppNames, forKey: "appNames")
        }
    }
    
    func saveLastUsedAppName(_ appName: String) {
        UserDefaults.standard.set(appName, forKey: "lastUsedAppName")
    }
        
    func fetchStoredAppNames() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "appNames") ?? []
    }
    
    func fetchLastUsedAppName() -> String? {
        return UserDefaults.standard.string(forKey: "lastUsedAppName")
    }
    
    func deleteAppName(at offsets: IndexSet) {
        var storedAppNames = fetchStoredAppNames()
        storedAppNames.remove(atOffsets: offsets)
        UserDefaults.standard.set(storedAppNames, forKey: "appNames")
        previousAppNames = storedAppNames // Update the local list
    }
      
}

// Earnings Input Pop-Up
struct EarningsInputPopup: View {
    @Binding var earnings: Double
    //var projectedEarnings: Double
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack {
            TextField("Earnings", value: $earnings, format: .currency(code: "USD"))
                //.onAppear(){
                //    earnings = earnings
                //}
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()

            HStack {
                Button(action: onSave) {
                    Text("Save")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: onCancel) {
                    Text("Cancel")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



    

    /*private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
*/


