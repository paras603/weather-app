//
//  ViewController.swift
//  Lab03
//
//  Created by Paras Mani Rai on 2024-11-04.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var climateLabel: UILabel!
    @IBOutlet weak var toggleTemperatureTitle: UILabel!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    @IBOutlet weak var changeTemperatureSwitch: UISwitch!
    
    private let locationManager = CLLocationManager()
    private var temperatureCelsius: Float?
    private var temperatureFahrenheit: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchTextField.delegate = self
        locationManager.delegate = self
        customizeSymbols()
    }
    
    private func customizeSymbols(){
        let config = UIImage.SymbolConfiguration(paletteColors: [ .systemGray5, .systemYellow, .systemCyan ] )
        weatherConditionImage.preferredSymbolConfiguration = config
        weatherConditionImage.image = UIImage(systemName: "cloud.sun.rain.fill")
    }
    
    @IBAction func onLocationTapped(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    private func displayLocation(locationText: String){
        locationLabel.text = locationText
    }
    
    @IBAction func toggleTemperature(_ sender: UISwitch) {
        if sender.isOn {
            // Display Fahrenheit
            if let tempF = temperatureFahrenheit {
                temperatureLabel.text = "\(tempF)°F"
            }
        } else {
            // Display Celsius
            if let tempC = temperatureCelsius {
                temperatureLabel.text = "\(tempC)°C"
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        print(textField.text ?? "")
        loadWeather(search: textField.text)
        return true
    }
    
    private func loadWeather(search: String?){
        guard let search = search else{
            return
        }
        
        // Turn off the temperature switch before a new search
        changeTemperatureSwitch.setOn(false, animated: true)
        
        
        //get URL
        guard let url = getURL(query: search) else {
            print("could not get URL")
            return
        }
        
        //create URLSession
        let session = URLSession.shared
        
        //task for the session
        let dataTask = session.dataTask(with: url) { (data, response, error) in
            //network call finished
            print("network call completed")
            
            guard error == nil else {
                print("Received error")
                return
            }
            
            guard let data = data else {
                print("no data found")
                return
            }
            
            if let weatherResponse = self.paraseJSON(data: data){
                print(weatherResponse.location.name)
                print(weatherResponse.current.temp_c)
                print(weatherResponse.current.temp_f)
                print(weatherResponse.current.condition.text)
                print(weatherResponse.current.condition.code)
                
                DispatchQueue.main.async{
                    self.locationLabel.text = weatherResponse.location.name
                    self.temperatureCelsius = weatherResponse.current.temp_c
                    self.temperatureFahrenheit = weatherResponse.current.temp_f
                    self.temperatureLabel.text = "\(self.temperatureCelsius ?? 0)°C"
                    
                    // Update weather condition image based on the weather code
                    let iconName = self.getWeatherIconName(for: weatherResponse.current.condition.code)
                    self.weatherConditionImage.image = UIImage(systemName: iconName)
                    
                    self.climateLabel.text = weatherResponse.current.condition.text
                    self.searchTextField.text = ""
                }
            }
        }
        
        //start the task
        dataTask.resume()
    }
    
    private func getURL(query: String) -> URL?{
        let baseURL = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        let apiKey = "b383b86d6cc44d24bd651526240511"
//        guard let url = "\(baseURL)\(currentEndPoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
//            return nil
//        }
        let url = "\(baseURL)\(currentEndPoint)?key=\(apiKey)&q=\(query)"
        print(url)
        
        return URL(string: url)
    }
    
    private func paraseJSON(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
        }catch{
            print("error decoding")
        }
        
        return weather
    }
    
    private func getWeatherIconName(for code: Int) -> String {
        let weatherIcons: [Int: String] = [
            1000: "sun.max.fill",            // Sunny
            1003: "cloud.sun.fill",          // Partly Cloudy
            1006: "cloud.fill",              // Cloudy
            1009: "smoke.fill",              // Overcast
            1030: "cloud.fog.fill",          // Mist
            1063: "cloud.drizzle.fill",      // Patchy rain possible
            1066: "cloud.snow.fill",         // Patchy snow possible
            1069: "cloud.sleet.fill",        // Patchy sleet possible
            1072: "cloud.hail.fill",         // Patchy freezing drizzle possible
            1087: "cloud.bolt.fill",         // Thundery outbreaks possible
            1183: "cloud.drizzle.fill",      // light rain
                                            // lignt rain shower
            // Add more mappings as needed
        ]
        
        return weatherIcons[code] ?? "questionmark.circle.fill" // Default icon if code is not mapped
    }

    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        print("got location")
        
        if let location = locations.last {
            print("location: \(location)")
            let latitude = location.coordinate.latitude
            let longtitude = location.coordinate.longitude
//            print("latitude: \(latitude), longitude: \(longtitude)")
            
            let query = "\(latitude),\(longtitude)"
            print(query)
            loadWeather(search: query)
            
//            displayLocation(locationText: "(\(latitude), \(longtitude))")
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error)
    }

}

struct WeatherResponse: Decodable{
    let location: Location
    let current: Weather
}

struct Location: Decodable{
    let name: String
}

struct Weather: Decodable{
    let temp_c: Float
    let temp_f: Float
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable{
    let text: String
    let code: Int
}

