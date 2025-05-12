//
//  NetworkManagerAlamofire.swift
//  SSL Pinning
//
//  Created by Ahmed Abo Elsood on 04/10/2024.
//

import Foundation
import Alamofire
import TrustKit

final class NetworkManagerAlamofire: SessionDelegate {

    static let shared = NetworkManagerAlamofire(useTrustKit: true)
    var afSession: Session!

    private init(useTrustKit: Bool = false) {
        super.init()

        if useTrustKit {
            // ✅ TrustKit-based SSL Pinning
            CertificatePinner.pinCertificates()
            let config = URLSessionConfiguration.default
            afSession = Session(configuration: config, delegate: self)
        } else {
            // ✅ Alamofire ServerTrustManager-based SSL Pinning
            let evaluators: [String: ServerTrustEvaluating] = [
                "api.openweathermap.org": PinnedCertificatesTrustEvaluator()
            ]
            let trustManager = ServerTrustManager(evaluators: evaluators)
            afSession = Session(serverTrustManager: trustManager)
        }
    }

    func fetchData<T: Decodable>(from url: URL?, completion: @escaping (Result<T, Error>) -> Void) {
        guard let urlString = url?.absoluteString else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        afSession.request(urlString)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(decoded))
                    } catch {
                        completion(.failure(error))
                    }

                case .failure(let error):
                    if let afError = error.asAFError {
                        switch afError {
                        case .serverTrustEvaluationFailed(let reason):
                            print("❌ SSL Pinning failed:", reason)
                            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "SSL Pinning Failed"])))
                        default:
                            completion(.failure(afError))
                        }
                    } else {
                        completion(.failure(error))
                    }
                }
            }
    }

    // MARK: - TrustKit SSL Pinning Handler
    override func urlSession(_ session: URLSession, task: URLSessionTask,
                             didReceive challenge: URLAuthenticationChallenge,
                             completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if TrustKit.sharedInstance().pinningValidator.handle(challenge, completionHandler: completionHandler) == false {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
