#!/usr/bin/env swift

// SSL Debugging Script for Scanivore iOS App
// This script tests SSL connectivity to the Railway backend

import Foundation

let apiURL = "https://clear-meat-api-production.up.railway.app/api/v1/products/count"

// Test 1: Basic URL Session
print("🔍 Testing SSL Connection to Railway Backend")
print("=" * 60)
print("URL: \(apiURL)")

let semaphore = DispatchSemaphore(value: 0)

// Create URLSession with custom configuration
let config = URLSessionConfiguration.default
config.tlsMinimumSupportedProtocolVersion = .TLSv12
config.tlsMaximumSupportedProtocolVersion = .TLSv13
config.timeoutIntervalForRequest = 30

let session = URLSession(configuration: config, delegate: SSLDebugDelegate(), delegateQueue: nil)

class SSLDebugDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, 
                   didReceive challenge: URLAuthenticationChallenge, 
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        print("\n📋 SSL Challenge Details:")
        print("  Protection Space: \(challenge.protectionSpace)")
        print("  Host: \(challenge.protectionSpace.host)")
        print("  Port: \(challenge.protectionSpace.port)")
        print("  Protocol: \(challenge.protectionSpace.protocol ?? "unknown")")
        print("  Authentication Method: \(challenge.protectionSpace.authenticationMethod)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                print("\n🔐 Server Trust Information:")
                
                // Get certificate chain
                let certCount = SecTrustGetCertificateCount(serverTrust)
                print("  Certificate Chain Length: \(certCount)")
                
                for i in 0..<certCount {
                    if let cert = SecTrustGetCertificateAtIndex(serverTrust, i) {
                        print("\n  Certificate #\(i+1):")
                        if let summary = SecCertificateCopySubjectSummary(cert) as? String {
                            print("    Subject: \(summary)")
                        }
                        
                        // Get certificate data
                        let certData = SecCertificateCopyData(cert) as Data
                        print("    Size: \(certData.count) bytes")
                    }
                }
                
                // Evaluate trust
                var error: CFError?
                let isValid = SecTrustEvaluateWithError(serverTrust, &error)
                
                print("\n✅ Trust Evaluation:")
                print("  Valid: \(isValid)")
                if let error = error {
                    print("  ❌ Error: \(error)")
                }
                
                // Accept the certificate
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
}

// Make the request
let url = URL(string: apiURL)!
let task = session.dataTask(with: url) { data, response, error in
    print("\n📡 Response Details:")
    
    if let error = error {
        print("  ❌ Error: \(error)")
        if let nsError = error as NSError? {
            print("  Error Code: \(nsError.code)")
            print("  Error Domain: \(nsError.domain)")
            print("  User Info: \(nsError.userInfo)")
        }
    }
    
    if let httpResponse = response as? HTTPURLResponse {
        print("  ✅ Status Code: \(httpResponse.statusCode)")
        print("  Headers: \(httpResponse.allHeaderFields)")
    }
    
    if let data = data, let body = String(data: data, encoding: .utf8) {
        print("  Response Body: \(body)")
    }
    
    semaphore.signal()
}

print("\n🚀 Starting connection...")
task.resume()

// Wait for completion
semaphore.wait()
print("\n✅ Test completed")
