import Foundation
import SwiftUI

class SerialManager: ObservableObject {
    @Published var isConnected = false
    @Published var availablePorts: [String] = []
    @Published var selectedPort: String? {
        didSet {
            if let port = selectedPort {
                setupConnection(path: port)
            }
        }
    }
    
    @Published var receivedData = ""
    private var connection: SerialConnection?
    
    init() {
        updateAvailablePorts()
        
        // Monitor for device changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceChanged),
            name: NSNotification.Name("IOServicePublishNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceChanged),
            name: NSNotification.Name("IOServiceTerminateNotification"),
            object: nil
        )
    }
    
    func updateAvailablePorts() {
        availablePorts = SerialConnection.availablePorts()
    }
    
    private func setupConnection(path: String) {
        connection = SerialConnection(path: path, baudRate: 57600) { [weak self] data in
            if let string = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.receivedData += string
                }
            }
        }
    }
    
    func connect() {
        guard let connection = connection else { return }
        isConnected = connection.open()
    }
    
    func disconnect() {
        connection?.close()
        isConnected = false
    }
    
    func sendCommand(_ command: String) {
        connection?.send(command + "\r")
    }
    
    @objc private func deviceChanged(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateAvailablePorts()
        }
    }
}

// MARK: - Port Information
extension SerialManager {
    struct PortInfo {
        let path: String
        var name: String {
            path.components(separatedBy: "/").last ?? path
        }
    }
    
    var selectedPortInfo: PortInfo? {
        guard let path = selectedPort else { return nil }
        return PortInfo(path: path)
    }
    
    var availablePortInfos: [PortInfo] {
        availablePorts.map { PortInfo(path: $0) }
    }
} 