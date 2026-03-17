//import Foundation
//
//// A simple structure to hold our fake weather data
//struct WeatherData {
//    let currentTempC: Double
//    let condition: String // e.g. "Sunny", "Cloudy"
//}
//
//@Observable
//class WeatherService {
//    static let shared = WeatherService()
//    
//    var currentWeatherData: WeatherData?
//    
//    private init() {
//        // Automatically load the mocked offline data upon creation
//        loadOfflineWeather()
//    }
//    
//    func loadOfflineWeather() {
//        // For our 100% offline standalone App, we hardcode happy weather!
//        self.currentWeatherData = WeatherData(currentTempC: 24.5, condition: "Sunny")
//    }
//}
import Foundation

// A simple structure to hold our real-time weather data
struct WeatherData {
    let currentTempC: Double
    let condition: String // e.g., "Sunny", "Cloudy"
}

@Observable
class WeatherService {
    static let shared = WeatherService()
    
    var currentWeatherData: WeatherData?
    
    // Default coordinates Mel-AU
    // Change these to your own city's coordinates!
    private let latitude = -37.8136
    private let longitude = 144.9631
    
    private init() {
        // Automatically fetch live weather upon creation
        Task {
            await fetchLiveWeather()
        }
    }
    
    func fetchLiveWeather() async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Extract the simple data we need from Open-Meteo's JSON response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current_weather"] as? [String: Any],
               let temperature = current["temperature"] as? Double,
               let weathercode = current["weathercode"] as? Int {
                
                // Convert WMO weather codes to a human-readable string and emoji
                let condition = conditionString(for: weathercode)
                
                // Update the app's UI on the main thread
                DispatchQueue.main.async {
                    self.currentWeatherData = WeatherData(currentTempC: temperature, condition: condition)
                }
            }
        } catch {
            print("❌ Failed to fetch weather: \(error.localizedDescription)")
            
            // Fallback strategy if offline
            DispatchQueue.main.async {
               self.currentWeatherData = WeatherData(currentTempC: 22.0, condition: "☁️ Offline")
            }
        }
    }
    
    // Helper to translate Open-Meteo "Weather Codes" into our strings
    private func conditionString(for code: Int) -> String {
        switch code {
        case 0: return "☀️"
        case 1, 2, 3: return "⛅️"
        case 45, 48: return "🌫"
        case 51...55, 61...65, 80...82: return "🌧"
        case 71...75, 85, 86: return "❄️"
        case 95...99: return "⛈"
        default: return "☀️"
        }
    }
}

