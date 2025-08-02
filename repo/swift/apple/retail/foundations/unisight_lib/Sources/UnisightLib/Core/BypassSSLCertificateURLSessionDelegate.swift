import Foundation
import Network

/// URLSession delegate that bypasses SSL certificate validation for testing purposes
/// ⚠️ WARNING: This should ONLY be used for testing and development
/// DO NOT use this in production as it bypasses all SSL security
@available(iOS 13.0, *)
public class BypassSSLCertificateURLSessionDelegate: NSObject, URLSessionDelegate {
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Bypass SSL certificate validation for testing
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        // For other authentication challenges, use default behavior
        completionHandler(.performDefaultHandling, nil)
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            print("[UnisightLib] Network request failed: \(error.localizedDescription)")
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        // Handle successful response
        if let response = dataTask.response as? HTTPURLResponse {
            print("[UnisightLib] Telemetry data sent successfully. Status: \(response.statusCode)")
        }
    }
}