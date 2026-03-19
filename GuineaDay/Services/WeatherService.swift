import Foundation
import CoreLocation

struct WeatherData {
    let currentTempC: Double
    let condition: String
}

@Observable
class WeatherService: NSObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    var currentWeatherData: WeatherData?

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // Called when location is received
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation() // only need one reading
        Task {
            await fetchLiveWeather(lat: location.coordinate.latitude,
                                   lon: location.coordinate.longitude)
        }
    }

    // Called if permission is denied or location unavailable — fall back to Melbourne
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location unavailable: \(error.localizedDescription) — falling back to Melbourne")
        Task { await fetchLiveWeather(lat: -37.8136, lon: 144.9631) }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // User denied — fall back to Melbourne
            Task { await fetchLiveWeather(lat: -37.8136, lon: 144.9631) }
        default:
            break
        }
    }

    func fetchLiveWeather(lat: Double, lon: Double) async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true"
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current_weather"] as? [String: Any],
               let temperature = current["temperature"] as? Double,
               let weathercode = current["weathercode"] as? Int {
                let condition = conditionString(for: weathercode)
                DispatchQueue.main.async {
                    self.currentWeatherData = WeatherData(currentTempC: temperature, condition: condition)
                }
            }
        } catch {
            print("❌ Failed to fetch weather: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.currentWeatherData = WeatherData(currentTempC: 22.0, condition: "☁️ Offline")
            }
        }
    }

    private func conditionString(for code: Int) -> String {
        switch code {
        case 0:           return "☀️"
        case 1, 2, 3:     return "⛅️"
        case 45, 48:      return "🌫"
        case 51...65,
             80...82:     return "🌧"
        case 71...75,
             85, 86:      return "❄️"
        case 95...99:     return "⛈"
        default:          return "☀️"
        }
    }
}
