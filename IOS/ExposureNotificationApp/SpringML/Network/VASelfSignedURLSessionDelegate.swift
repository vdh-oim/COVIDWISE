//
//  VASelfSignedURLSessionDelegate.swift
//  ExposureNotificationApp
//
//

import Foundation

class VASelfSignedURLSessionDelegate: NSObject, URLSessionDelegate {
    let selfSignedCertDER = "TODO"
    static let pubKeyInB64 = "TODO"
    static let pubKeyInB64Data = Data(base64Encoded: VASelfSignedURLSessionDelegate.pubKeyInB64)! as NSData
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // First load our extra root-CAs to be trusted from the app bundle.
            guard let trust = challenge.protectionSpace.serverTrust else {
                challenge.sender?.cancel(challenge)
                return
            }

            let selfSignedCertDERData = Data(base64Encoded: selfSignedCertDER, options: .ignoreUnknownCharacters)!
            let rootCaData = selfSignedCertDERData as CFData
            let rootCert = SecCertificateCreateWithData(nil, rootCaData)!
            SecTrustSetAnchorCertificates(trust, [rootCert] as CFArray)
            SecTrustSetAnchorCertificatesOnly(trust, false)

            
            if !SMLConfig.CertPinningDisabled {
                guard let pubKey: SecKey = SecTrustCopyPublicKey(trust) else { challenge.sender?.cancel(challenge); return; }
                var err: Unmanaged<CFError>?
                let pubKeyER = SecKeyCopyExternalRepresentation(pubKey, &err)
                if let err = err {
                }
                if let pubKeyER = pubKeyER {
                    if(pubKeyER == VASelfSignedURLSessionDelegate.pubKeyInB64Data) {
                        
                    }
                    else {
                        let str = (pubKeyER as Data).base64EncodedString()
                        challenge.sender?.cancel(challenge); return;
                    }
                }
                else {
                    challenge.sender?.cancel(challenge); return;
                }
            }
            
            var trustError: CFError?
            let result = SecTrustEvaluateWithError(trust, &trustError)
            if let trustError = trustError {
                if(trustError._code == -67602) {
                    // Bypass certificate trust challenge response
                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
                }
                else {
                    challenge.sender?.cancel(challenge)
                }
            }
            else {
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            challenge.sender?.cancel(challenge)
        }
    }
}
