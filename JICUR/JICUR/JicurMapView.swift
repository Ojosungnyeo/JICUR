import GoogleMaps
import SwiftUI

struct JicurMapView: UIViewRepresentable {
    var scene: MapScene
    var onTap: (MapCoordinate) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition(latitude: scene.center.latitude, longitude: scene.center.longitude, zoom: scene.zoom)
        let options = GMSMapViewOptions()
        options.camera = camera
        let map = GMSMapView(options: options)
        map.delegate = context.coordinator
        map.mapType = .normal
        map.isBuildingsEnabled = true
        map.settings.compassButton = false
        map.settings.myLocationButton = false
        map.isMyLocationEnabled = false
        map.setMinZoom(12, maxZoom: 19)
        map.mapStyle = try? GMSMapStyle(jsonString: Self.mapStyleJSON)
        render(scene, on: map)
        fitRoute(scene.route, on: map, animated: false)
        return map
    }

    func updateUIView(_ map: GMSMapView, context: Context) {
        context.coordinator.onTap = onTap
        map.clear()
        render(scene, on: map)
        fitRoute(scene.route, on: map, animated: true)
    }

    private func fitRoute(_ coordinates: [MapCoordinate], on map: GMSMapView, animated: Bool) {
        guard coordinates.count > 1 else {
            let camera = GMSCameraPosition(latitude: scene.center.latitude, longitude: scene.center.longitude, zoom: scene.zoom)
            if animated {
                map.animate(to: camera)
            } else {
                map.camera = camera
            }
            return
        }
        var bounds = GMSCoordinateBounds()
        coordinates.forEach { bounds = bounds.includingCoordinate(.init(latitude: $0.latitude, longitude: $0.longitude)) }
        let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 190, left: 55, bottom: 245, right: 55))
        animated ? map.animate(with: update) : map.moveCamera(update)
    }

    private func render(_ scene: MapScene, on map: GMSMapView) {
        let path = GMSMutablePath()
        scene.route.forEach { path.addLatitude($0.latitude, longitude: $0.longitude) }

        let route = GMSPolyline(path: path)
        route.strokeColor = UIColor(red: 0.12, green: 0.42, blue: 0.29, alpha: 1)
        route.strokeWidth = 6
        route.geodesic = false
        route.map = map

        scene.places.forEach { place in
            let marker = GMSMarker(position: .init(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
            marker.title = place.title
            marker.snippet = place.subtitle
            marker.iconView = MarkerView(place: place)
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.78)
            marker.tracksViewChanges = false
            marker.map = map
        }
    }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        var onTap: (MapCoordinate) -> Void
        init(onTap: @escaping (MapCoordinate) -> Void) { self.onTap = onTap }
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            onTap(.init(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
    }

    private static let mapStyleJSON = #"""
    [
      {"featureType":"all","elementType":"labels","stylers":[{"visibility":"off"}]},
      {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
      {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f1f3f7"}]},
      {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#f1f3f7"}]},
      {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#edf1ed"}]},
      {"featureType":"poi","stylers":[{"visibility":"off"}]},
      {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#e8eee8"}]},
      {"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},
      {"featureType":"road.local","elementType":"geometry","stylers":[{"visibility":"off"}]},
      {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#ffffff"},{"weight":1}]},
      {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"visibility":"off"}]},
      {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#e3e7ed"}]},
      {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"visibility":"off"}]},
      {"featureType":"transit","stylers":[{"visibility":"off"}]},
      {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#dfe7ed"}]},
      {"featureType":"water","elementType":"labels","stylers":[{"visibility":"off"}]}
    ]
    """#
}

private final class MarkerView: UIView {
    init(place: MapPlace) {
        let color: UIColor
        let symbol: String
        switch place.kind {
        case .start: color = .systemGreen; symbol = "figure.walk"
        case .forest: color = .systemTeal; symbol = "wind"
        case .rest: color = .systemOrange; symbol = "sun.horizon.fill"
        case .destination: color = UIColor(red: 0.16, green: 0.45, blue: 0.28, alpha: 1); symbol = "house.fill"
        }
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 58))
        backgroundColor = color
        layer.cornerRadius = 25
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
        let image = UIImageView(image: UIImage(systemName: symbol))
        image.tintColor = .white
        image.contentMode = .scaleAspectFit
        image.frame = bounds.insetBy(dx: 14, dy: 17)
        addSubview(image)
    }
    required init?(coder: NSCoder) { nil }
}
