import Foundation
import CoreLocation
import UIKit

/// Service for launching external navigation apps (Apple Maps, Google Maps, Waze)
class NavigationService {
    static let shared = NavigationService()

    private init() {}

    // MARK: - Navigation App Types

    enum NavigationApp: String, CaseIterable {
        case appleMaps = "Apple Maps"
        case googleMaps = "Google Maps"
        case waze = "Waze"

        var icon: String {
            switch self {
            case .appleMaps: return "map.fill"
            case .googleMaps: return "map.circle.fill"
            case .waze: return "car.fill"
            }
        }

        var urlScheme: String {
            switch self {
            case .appleMaps: return "maps://"
            case .googleMaps: return "comgooglemaps://"
            case .waze: return "waze://"
            }
        }
    }

    // MARK: - Public Methods

    /// Get list of navigation apps that are installed on the device
    func getAvailableNavigationApps() -> [NavigationApp] {
        var availableApps: [NavigationApp] = []

        for app in NavigationApp.allCases {
            if app == .appleMaps {
                // Apple Maps is always available
                availableApps.append(app)
            } else if canOpenApp(app) {
                availableApps.append(app)
            }
        }

        return availableApps
    }

    /// Check if a specific navigation app is installed
    func canOpenApp(_ app: NavigationApp) -> Bool {
        guard let url = URL(string: app.urlScheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Launch navigation to a destination using the specified app
    /// - Parameters:
    ///   - app: The navigation app to use
    ///   - origin: The starting location (optional - defaults to current location)
    ///   - destination: The destination coordinate
    ///   - destinationName: Optional name for the destination
    func startNavigation(using app: NavigationApp, from origin: Coordinate? = nil, to destination: Coordinate, destinationName: String? = nil) {
        let url: URL?

        switch app {
        case .appleMaps:
            url = buildAppleMapsURL(origin: origin, destination: destination, name: destinationName)
        case .googleMaps:
            url = buildGoogleMapsURL(origin: origin, destination: destination, name: destinationName)
        case .waze:
            url = buildWazeURL(origin: origin, destination: destination, name: destinationName)
        }

        guard let navigationURL = url else {
            print("❌ NavigationService: Failed to create URL for \(app.rawValue)")
            return
        }

        print("🗺️ NavigationService: Launching \(app.rawValue) with URL: \(navigationURL)")

        UIApplication.shared.open(navigationURL) { success in
            if success {
                print("✅ NavigationService: Successfully launched \(app.rawValue)")
            } else {
                print("❌ NavigationService: Failed to launch \(app.rawValue)")
            }
        }
    }

    // MARK: - URL Building

    private func buildAppleMapsURL(origin: Coordinate?, destination: Coordinate, name: String?) -> URL? {
        var components = URLComponents(string: "maps://")

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "daddr", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "dirflg", value: "d") // d = driving
        ]

        // Add origin if provided
        if let origin = origin {
            queryItems.append(URLQueryItem(name: "saddr", value: "\(origin.latitude),\(origin.longitude)"))
        }

        components?.queryItems = queryItems
        return components?.url
    }

    private func buildGoogleMapsURL(origin: Coordinate?, destination: Coordinate, name: String?) -> URL? {
        var components = URLComponents(string: "comgooglemaps://")

        let destinationParam = "\(destination.latitude),\(destination.longitude)"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "daddr", value: destinationParam),
            URLQueryItem(name: "directionsmode", value: "driving")
        ]

        // Add origin if provided
        if let origin = origin {
            queryItems.append(URLQueryItem(name: "saddr", value: "\(origin.latitude),\(origin.longitude)"))
        }

        components?.queryItems = queryItems
        return components?.url
    }

    private func buildWazeURL(origin: Coordinate?, destination: Coordinate, name: String?) -> URL? {
        // Waze doesn't support explicit origin in URL scheme - it always uses current location
        // If origin is provided, we could show a warning, but for now just navigate to destination
        var components = URLComponents(string: "waze://")

        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "navigate", value: "yes")
        ]

        return components?.url
    }
}

// MARK: - Convenience Methods

extension NavigationService {
    /// Launch navigation with a user-friendly app picker
    /// Shows action sheet if multiple apps available, launches directly if only one
    func startNavigationWithPicker(from origin: Coordinate? = nil, to destination: Coordinate, destinationName: String?, from viewController: UIViewController?) {
        let availableApps = getAvailableNavigationApps()

        guard !availableApps.isEmpty else {
            print("❌ NavigationService: No navigation apps available")
            return
        }

        // If only one app available, launch it directly
        if availableApps.count == 1 {
            startNavigation(using: availableApps[0], from: origin, to: destination, destinationName: destinationName)
            return
        }

        // Show picker if multiple apps available
        let alert = UIAlertController(
            title: "Choose Navigation App",
            message: "Select which app to use for navigation",
            preferredStyle: .actionSheet
        )

        for app in availableApps {
            let action = UIAlertAction(title: app.rawValue, style: .default) { [weak self] _ in
                self?.startNavigation(using: app, from: origin, to: destination, destinationName: destinationName)
            }
            alert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)

        viewController?.present(alert, animated: true)
    }
}
