//
//  NetworkMonitor.swift
//  Scanivore
//
//  Network connectivity monitoring for better error handling
//

import Foundation
import Network

@MainActor
public class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published public var isConnected = true
    @Published public var connectionType: NWInterface.InterfaceType?
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                if path.status != .satisfied {
                    print("⚠️ [NetworkMonitor] Network connection lost")
                } else if let type = self?.connectionType {
                    print("✅ [NetworkMonitor] Network connected via \(type)")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    public var isConnectedViaCellular: Bool {
        isConnected && connectionType == .cellular
    }
    
    public var isConnectedViaWiFi: Bool {
        isConnected && connectionType == .wifi
    }
    
    public var connectionDescription: String {
        guard isConnected else { return "No connection" }
        
        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .other:
            return "Other"
        default:
            return "Unknown"
        }
    }
}