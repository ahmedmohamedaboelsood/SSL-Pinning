//
//  NetworkManagerURLSession.swift
//  SSL Pinning
//
//  Created by Ahmed Abo Elsood on 04/10/2024.
//

import Foundation
import CommonCrypto
import TrustKit

class NetworkManagerURLSession : NSObject{
    
    static let shared = NetworkManagerURLSession()
    var session = URLSession()
    
    override init() {
        super.init()
        //MARK: - TrustKit Config
        //CertificatePinner.pinCertificates()
        
        //MARK: - URLSession Config
        session = URLSession.init(configuration: .ephemeral, delegate: self, delegateQueue: nil)
    }
    
    //MARK: - Public Key
    
    // ASN.1 (Abstract Syntax Notation One) is a standard format used in cryptography to encode public keys.
    // This array is the header for RSA 2048-bit keys.
    // RSA one of the most widely used cryptographic algorithms for securing data.
    
    private let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    
    // SHA-256 Hashing Function
    
    private func sha256(data : Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
    
    func fetchData<T: Codable>(from urlString: URL?, model: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let urlString else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let task = session.dataTask(with: urlString) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

extension NetworkManagerURLSession : URLSessionDelegate{
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        //MARK: - TrustKit
        trustKitPublicKeyPinnig(challenge, completionHandler: completionHandler)
        
        //MARK: - Certificate Pinning  🫨
        //certificatePinnig(challenge,completionHandler: completionHandler)
        
        //MARK: - Public Key Pinning  🫨
        //publicKeyPinnig(challenge,completionHandler: completionHandler)
        
    }
    
    private func publicKeyPinnig(_ challenge : URLAuthenticationChallenge , completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        
        // Extract server trust and the first certificate
        
        guard let serverTrust = challenge.protectionSpace.serverTrust, let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            return
        }
        
        if let serverPublicKey = SecCertificateCopyKey(certificate), let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) {
            
            let data: Data = serverPublicKeyData as Data
            let serverHashKey = sha256(data: data)
            
            //comparing server and local hash keys
            if serverHashKey == Constants.localPublicKey {
                let credential: URLCredential = URLCredential(trust: serverTrust)
                print("Public Key pinning is successfull")
                completionHandler(.useCredential, credential)
            } else {
                print("Public Key pinning is failed")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
    
    private func certificatePinnig(_ challenge : URLAuthenticationChallenge , completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        
        // Extract server trust and the first certificate
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Evaluate the server trust
        var error: CFError?
        let isServerTrusted = SecTrustEvaluateWithError(serverTrust, &error)
        
        // Extract remote certificate data
        let remoteCertificateData = SecCertificateCopyData(certificate) as Data
        
        // Get local certificate data
        guard let pathToCertificate = Bundle.main.path(forResource: "openweathermap.org", ofType: "cer"),
              let localCertificateData = NSData(contentsOfFile: pathToCertificate) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        print("Remote certificate data: \(remoteCertificateData)")
        print("Local certificate data: \(localCertificateData)")
        
        // Compare certificates
        if isServerTrusted && remoteCertificateData == localCertificateData as Data {
            let credential = URLCredential(trust: serverTrust)
            print("Certificate pinning successful")
            completionHandler(.useCredential, credential)
        } else {
            print("Certificate pinning failed")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    private func trustKitPublicKeyPinnig(_ challenge : URLAuthenticationChallenge , completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        if TrustKit.sharedInstance().pinningValidator.handle(challenge, completionHandler: completionHandler) == false {
            
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
