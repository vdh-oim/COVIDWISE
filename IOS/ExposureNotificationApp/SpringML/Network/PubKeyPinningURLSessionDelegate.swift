//
//  PubKeyPinningURLSessionDelegate.swift
//  ExposureNotificationApp
//
//

import Foundation

class PubKeyPinningURLSessionDelegate: NSObject, URLSessionDelegate {
    static let pubKeyInB64Data = Data(base64Encoded: "TODO")! as CFData
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // First load our extra root-CAs to be trusted from the app bundle.
            guard let trust = challenge.protectionSpace.serverTrust else {
                challenge.sender?.cancel(challenge)
                return
            }
            if !SMLConfig.CertPinningDisabled {
                let certificateCount = SecTrustGetCertificateCount(trust)
                if(certificateCount < 2) {
                    challenge.sender?.cancel(challenge);
                    completionHandler(.cancelAuthenticationChallenge, nil);
                    return;
                }
                guard let intermediateCertificate = SecTrustGetCertificateAtIndex(trust, 1) else {
                    challenge.sender?.cancel(challenge);
                    completionHandler(.cancelAuthenticationChallenge, nil);
                    return;
                }
                guard let pubKey: SecKey = SecCertificateCopyKey(intermediateCertificate) else {  challenge.sender?.cancel(challenge); completionHandler(.cancelAuthenticationChallenge, nil); return; }
                var err: Unmanaged<CFError>?
                let pubKeyER = SecKeyCopyExternalRepresentation(pubKey, &err)
                if let err = err {
                }
                if let pubKeyER = pubKeyER {
                    if(pubKeyER == Self.pubKeyInB64Data) {
                        
                    }
                    else {
                        
                        let str = (pubKeyER as Data).base64EncodedString()
                        challenge.sender?.cancel(challenge);
                        completionHandler(.cancelAuthenticationChallenge, nil)
                        return;
                    }
                }
                else {
                    challenge.sender?.cancel(challenge);
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    return;
                }
            }
            
            var trustError: CFError?
            let result = SecTrustEvaluateWithError(trust, &trustError)
            if let trustError = trustError {
                challenge.sender?.cancel(challenge)
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            else {
                // Trust certificate.
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            NSLog("Got unexpected authentication method \(challenge.protectionSpace.authenticationMethod)");
            challenge.sender?.cancel(challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
