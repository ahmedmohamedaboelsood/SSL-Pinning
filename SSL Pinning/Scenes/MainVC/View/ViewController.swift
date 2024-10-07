//
//  ViewController.swift
//  SSL Pinning
//
//  Created by Ahmed Abo Elsood on 04/10/2024.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var minTempLabel: UILabel!
    @IBOutlet weak var maxTempLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //callURLSessionApi()
        callAlamofireApi()
    }
    
    private func callAlamofireApi(){
        NetworkManagerAlamofire.shared.fetchData(from: Constants.weatherUrl()) { (result: Result<WeatherData, Error>) in
            switch result {
            case .success(let weatherData):
                DispatchQueue.main.async{
                    self.minTempLabel.text = "\(weatherData.main.tempMin)"
                    self.maxTempLabel.text = "\(weatherData.main.tempMax)"
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }


    private func callURLSessionApi(){
        NetworkManagerURLSession.shared.fetchData(from: Constants.weatherUrl(), model: WeatherData.self) { result in
            switch result {
            case .success(let weatherData):
                DispatchQueue.main.async{
                    self.minTempLabel.text = "\(weatherData.main.tempMin)"
                    self.maxTempLabel.text = "\(weatherData.main.tempMax)"
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

