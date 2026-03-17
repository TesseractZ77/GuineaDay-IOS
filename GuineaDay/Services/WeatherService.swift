import Foundation

// A simple structure to hold our fake weather data
struct WeatherData {
    let currentTempC: Double
    let condition: String // e.g. "Sunny", "Cloudy"
}

@Observable
class WeatherService {
    static let shared = WeatherService()
    
    var currentWeatherData: WeatherData?
    
    private init() {
        // Automatically load the mocked offline data upon creation
        loadOfflineWeather()
    }
    
    func loadOfflineWeather() {
        // For our 100% offline standalone App, we hardcode happy weather!
        self.currentWeatherData = WeatherData(currentTempC: 24.5, condition: "Sunny")
    }
}
