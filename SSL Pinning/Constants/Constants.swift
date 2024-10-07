//
//  Constants.swift
//  SSL Pinning
//
//  Created by Ahmed Abo Elsood on 04/10/2024.
//

import Foundation

class Constants {
    
    static func weatherUrl()->URL?{
        var urlString = URL(string: "https://api.openweathermap.org/data/2.5/weather")
        
        urlString?.append(
            queryItems: [
                URLQueryItem(name: "lat", value: "31.5"),
                URLQueryItem(name: "lon", value: "32.5"),
                URLQueryItem(name: "units", value: "metric"),
                URLQueryItem(name: "appid", value: "6c2eee34075a3140f34b803f5c6c2e14")])
        
        return urlString
    }
    
    static let localPublicKey = "CpmBztr3L/AZjANtR+K3vhridQoIsoyqTl5yU5zQQLQ="
    
}
