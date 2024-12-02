import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var reminderText = ""

    // State for managing the edit mode
    @State private var isEditingReminder = false
    @State private var currentEditingLocation: AlertLocation? = nil
    @State private var newReminderText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if let alert = locationManager.currentLocationAlert {
                    Text(alert)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.bottom)
                }
                
                VStack(alignment: .leading) {
                    TextField("Search Address", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    TextField("Add a Reminder", text: $reminderText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                Button(action: saveLocation) {
                    Text("Save Location")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.bottom)
                
                Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: locationManager.savedLocations) { location in
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
                .frame(height: 300)
                
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
                            Button(action: {
                                currentEditingLocation = location
                                newReminderText = location.reminder
                                isEditingReminder = true
                            }) {
                                Text("Edit")
                                    .foregroundColor(.blue)
                            }
                            Button(action: {
                                locationManager.removeLocation(location)
                            }) {
                                Text("Remove")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                .sheet(isPresented: $isEditingReminder) {
                    if let location = currentEditingLocation {
                        VStack(spacing: 16) {
                            Text("Edit Reminder for \(location.name)")
                                .font(.headline)
                            TextField("Enter new reminder", text: $newReminderText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            Button("Save") {
                                // Save the updated reminder
                                locationManager.updateReminder(for: location, with: newReminderText)
                                isEditingReminder = false
                                currentEditingLocation = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }

            }
            .navigationTitle("SpotAlert")
            .onAppear {
                locationManager.requestPermission()
                locationManager.loadLocations()
            }
        }
    }

    func saveLocation() {
        guard !searchText.isEmpty else { return }
        locationManager.searchLocation(for: searchText) { coordinate in
            guard let coordinate = coordinate else {
                print("Location not found")
                return
            }
            let newLocation = AlertLocation(name: searchText, coordinate: coordinate, reminder: reminderText)
            locationManager.addLocation(newLocation)
            searchText = ""
            reminderText = ""
        }
    }
}
