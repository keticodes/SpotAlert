import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""

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
                
                TextField("Search Address", text: $searchText, onCommit: {
                    searchForLocation()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

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
                locationManager.loadLocations()
            }
        }
    }

    private func searchForLocation() {
        guard !searchText.isEmpty else { return }
        locationManager.searchLocation(for: searchText) { coordinate in
            guard let coordinate = coordinate else {
                print("Location not found")
                return
            }
            let newLocation = AlertLocation(name: searchText, coordinate: coordinate)
            locationManager.addLocation(newLocation)
        }
    }
}
