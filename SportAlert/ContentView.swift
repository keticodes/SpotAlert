//
//  ContentView.swift
//  SpotAlert
//
//  Created by Keti Mandunga on 11.11.2024.
//

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
                                locationManager.startMonitoringLocation(location)
                            }) {
                                Text("Track")
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
            }
            .navigationTitle("SpotAlert")
            .onAppear {
                locationManager.requestPermission()
                locationManager.loadLocations()
                locationManager.sendNotification(
                    title: "SpotAlert Opened",
                    body: "Welcome back! Your location tracking is active."
                )
            }
        }
    }

    func saveLocation() {
        guard !searchText.isEmpty else {
            locationManager.sendNotification(
                title: "Location Save Failed",
                body: "Please enter a valid location"
            )
            return
        }
        locationManager.searchLocation(for: searchText) { coordinate in
            guard let coordinate = coordinate else {
                locationManager.sendNotification(
                    title: "Location Not Found",
                    body: "Could not find the specified location"
                )
                return
            }
            let newLocation = AlertLocation(name: searchText, coordinate: coordinate, reminder: reminderText)
            locationManager.addLocation(newLocation)
            
            locationManager.sendNotification(
                title: "Location Saved",
                body: "'\(searchText)' has been added to SpotAlert"
            )
            
            searchText = ""
            reminderText = ""
        }
    }
}
