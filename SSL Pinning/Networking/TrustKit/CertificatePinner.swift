//
//  CertificatePinner.swift
//  SSL Pinning
//
//  Created by Ahmed Abo Elsood on 06/10/2024.
//

import Foundation
import TrustKit

public class CertificatePinner {
   public class func pinCertificates() {
        let trustKitConfig = [
            kTSKEnforcePinning: true,
            kTSKIncludeSubdomains: true,
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "api.openweathermap.org": [
                    kTSKPublicKeyHashes: [
                        Constants.localPublicKey,
                        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",
                        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
                    ],
                ]
            ]
            ] as [String : Any]
        TrustKit.initSharedInstance(withConfiguration:trustKitConfig)
    }
}
