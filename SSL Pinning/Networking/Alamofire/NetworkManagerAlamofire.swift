//
//  NetworkManagerAlamofire.swift
//  SSL Pinning
//
//  Created by Ahmed Abo Elsood on 04/10/2024.
//

import Foundation
import Alamofire
import TrustKit

class NetworkManagerAlamofire : SessionDelegate{
    static let shared = NetworkManagerAlamofire()
    
    var afSession = Session.default
    
    init(){
        super.init()
        //MARK: - Alamofire Config
        let evaluators: [String: ServerTrustEvaluating] = [
            "api.openweathermap.org": PublicKeysTrustEvaluator()
        ]
        let manager = ServerTrustManager(evaluators: evaluators)
        afSession = Session.init(serverTrustManager: manager)
        
        //MARK: - TrustKit Config
//        CertificatePinner.pinCertificates()
//        afSession = Session.init(delegate: self ,serverTrustManager: manager)
    }
    
    func fetchData<T: Decodable>(from url: URL?, completion: @escaping (Result<T, Error>) -> Void) {
        guard let urlString = url?.absoluteString else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        afSession.request(urlString)
            .validate()  // Validate response status codes (default is 200-299)
            .responseData { response in  // Ensure we receive data
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let decodedResponse = try decoder.decode(T.self, from: data)
                        completion(.success(decodedResponse))
                    } catch {
                        completion(.failure(error))  // Pass decoding error
                    }

                case .failure(let error):
                    if let afError = error.asAFError {
                        switch afError {
                        case .serverTrustEvaluationFailed(let reason):
                            print("Server trust evaluation failed:", reason)
                            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "SSL Pinning Failed"])))

                        default:
                            completion(.failure(afError))  // Handle other AFError cases
                        }
                    } else {
                        completion(.failure(error))  // Handle general errors
                    }
                }
            }
    }
}

extension NetworkManagerAlamofire  {
    
    override func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if TrustKit.sharedInstance().pinningValidator.handle(challenge, completionHandler: completionHandler) == false {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
}
