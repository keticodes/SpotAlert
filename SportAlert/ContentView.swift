import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var reminderText = ""
    @State private var isEditingReminder = false
    @State private var currentEditingLocation: AlertLocation? = nil
    @State private var newReminderText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Map View
                Map(coordinateRegion: $locationManager.region,
                    showsUserLocation: true,
                    annotationItems: locationManager.savedLocations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text(location.name)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.top)
                .frame(height: 420)
                
                // Search and Reminder Input
                VStack(alignment: .leading) {
                    TextField("Search Address", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    TextField("Add a Reminder", text: $reminderText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                // Save Location Button
                Button(action: saveLocation) {
                    Text("Save Location")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.bottom)
                
                // Locations List
                List {
                    ForEach(locationManager.savedLocations) { location in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .font(.headline)
                                if !location.reminder.isEmpty {
                                    Text("Reminder: \(location.reminder)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            // HStack for Edit and Remove buttons
                                      HStack(spacing: 16) {
                                          // Edit Reminder Button
                                          Button(action: {
                                              currentEditingLocation = location
                                              newReminderText = location.reminder
                                              isEditingReminder = true
                                          }) {
                                              Image(systemName: "pencil.circle.fill")
                                                  .foregroundColor(.blue)
                                          }
                                          
                                       
                                        
                                
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .sheet(isPresented: $isEditingReminder) {
                // Reminder Editing Sheet
                VStack {
                    TextField("Edit Reminder", text: $newReminderText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Save Reminder") {
                        if let location = currentEditingLocation {
                            locationManager.updateLocation(location, newReminder: newReminderText)
                        }
                        isEditingReminder = false
                    }
                    .padding()
                }
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.loadLocations()
                locationManager.sendNotification(
                    title: "🚀 SpotAlert Opened",
                    body: "📍 Welcome to SpotAlert! Your location tracking is active."
                )
            }
        }
    }

    func saveLocation() {
        guard !searchText.isEmpty else {
            locationManager.sendNotification(
                title: "❌ Location Save Failed",
                body: "📍 Please enter a valid location"
            )
            return
        }
        locationManager.searchLocation(for: searchText) { coordinate in
            guard let coordinate = coordinate else {
                locationManager.sendNotification(
                    title: "🔍 Location Not Found",
                    body: "📍 Could not find the specified location"
                )
                return
            }
            let newLocation = AlertLocation(name: searchText, coordinate: coordinate, reminder: reminderText)
            locationManager.addLocation(newLocation)
            
            // Focus the map on the newly saved location
            locationManager.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            locationManager.sendNotification(
                title: "✅ Location Saved",
                body: "📍 '\(searchText)' has been added to SpotAlert"
            )
            
            searchText = ""
            reminderText = ""
        }
    }
}

