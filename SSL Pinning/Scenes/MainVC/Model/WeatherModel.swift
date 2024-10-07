//
//  WeatherModel.swift
//  SSL Pinning
//
//  Created by Ahmed Abo Elsood on 04/10/2024.
//

import Foundation
import Foundation

// MARK: - WeatherData
struct WeatherData: Codable {
    let main: Main
}
// MARK: - Main
struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}
