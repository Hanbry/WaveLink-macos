import SwiftUI

struct StandbyView: View {
    @EnvironmentObject var serialManager: SerialManager
    @State private var showingSystemInfo = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Display
            GroupBox(label: Label("System Status", systemImage: "info.circle")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Connection:")
                        Circle()
                            .fill(serialManager.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(serialManager.isConnected ? "Connected" : "Disconnected")
                    }
                    
                    if let portInfo = serialManager.selectedPortInfo {
                        Text("Port: \(portInfo.name)")
                        Text("Baud Rate: 57600")
                    }
                }
                .padding()
            }
            .padding()
            
            // System Controls
            GroupBox(label: Label("System Controls", systemImage: "slider.horizontal.3")) {
                VStack(spacing: 15) {
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.System.version)
                    }) {
                        Label("Show Version", systemImage: "info.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.System.help)
                    }) {
                        Label("Show Help", systemImage: "questionmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.System.channel)
                    }) {
                        Label("Show Channel Status", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.System.reset)
                    }) {
                        Label("Reset System", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding()
            }
            .padding()
            
            // Received Data Display
            GroupBox(label: Label("System Messages", systemImage: "text.bubble")) {
                ScrollView {
                    Text(serialManager.receivedData)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("System Status")
    }
}

struct StandbyView_Previews: PreviewProvider {
    static var previews: some View {
        StandbyView()
            .environmentObject(SerialManager())
    }
} 