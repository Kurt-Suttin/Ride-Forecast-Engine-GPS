// Ride Forecast Engine (Rfe GPS)
// ContentView.swift

import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var destinationText = ""
    @State private var etaText = "ETA: --"
    @State private var route: MKRoute?

    var body: some View {
        VStack(spacing: 0) {

            // 🧭 Destination input field
            VStack(spacing: 8) {
                HStack {
                    TextField("Enter destination", text: $destinationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button("Go") {
                        geocodeDestination()
                    }
                    .padding(.trailing)
                }
            }

            // 🗺 MAP - shows user location
            Map(coordinateRegion: $locationManager.region, interactionModes: .all, showsUserLocation: true)
                .overlay(
                    route != nil ? AnyView(RouteMapOverlay(route: route!)) : AnyView(EmptyView())
                )
                .frame(height: UIScreen.main.bounds.height * 0.65)
                .ignoresSafeArea(edges: .top)

            // 📦 Bottom panel
            VStack(alignment: .leading, spacing: 12) {
                Text("Ride Forecast")
                    .font(.title2.bold())

                HStack {
                    Image(systemName: "cloud.rain.fill")
                    Text("Rain expected in 15 min")
                        .font(.subheadline)
                }

                Divider()

                Text(etaText)
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 5)
        }
    }

    // 🔍 Convert typed destination into coordinates
    func geocodeDestination() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(destinationText) { placemarks, error in
            if let error = error {
                print("Geocoding error:", error.localizedDescription)
                return
            }

            if let location = placemarks?.first?.location {
                print("📍 Destination coordinates:", location.coordinate)
                calculateRoute(to: location.coordinate)
            } else {
                print("No matching location found.")
            }
        }
    }

    // 🛣️ Calculate ETA and draw route
    func calculateRoute(to destination: CLLocationCoordinate2D) {
        let sourcePlacemark = MKPlacemark(coordinate: locationManager.region.center)
        let destPlacemark = MKPlacemark(coordinate: destination)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destPlacemark)
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Route error:", error.localizedDescription)
                return
            }

            if let calculatedRoute = response?.routes.first {
                self.route = calculatedRoute
                let etaMinutes = Int(calculatedRoute.expectedTravelTime / 60)
                self.etaText = "ETA: \(etaMinutes) min"
            }
        }
    }
}

// Overlay for drawing a route using UIKit's MKPolylineRenderer
struct RouteMapOverlay: UIViewRepresentable {
    let route: MKRoute

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
