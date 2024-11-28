//
//  ContentView.swift
//  SportAlert
//
//  Created by Keti Mandunga on 11.11.2024.
//  Project Group 4

import SwiftUI
import MapKit

// Main view displaying the map and saved locations.
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                // Display current location alert if available
                if let alert = locationManager.currentLocationAlert {
                    Text(alert)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.bottom)
                }
                
                // Search field for searching addresses (no implementation yet)
                TextField("Search Address", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Map with user location and annotations
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
                
                // List of saved locations
                List {
                    ForEach(locationManager.savedLocations) { location in
                        HStack {
                            Text(location.name)
                            Spacer()
                            Button("Remove") {
                                locationManager.removeLocation(location)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("SpotAlert")
            .onAppear {
                locationManager.requestPermission()
                locationManager.setInitialRegion(
                    center: CLLocationCoordinate2D(latitude: 60.2176, longitude: 24.8041),
                    name: "Karaportti 2, Espoo"
                )
            }
        }
    }
}
