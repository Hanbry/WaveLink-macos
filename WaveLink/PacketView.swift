import SwiftUI

struct PacketView: View {
    @EnvironmentObject var serialManager: SerialManager
    @State private var callsign = ""
    @State private var unprotoPath = ""
    @State private var messageToSend = ""
    @State private var isMonitoring = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status and Control Bar
            HStack {
                Button(action: {
                    serialManager.sendCommand(PTCCommand.switchToPacket)
                }) {
                    Label("Switch to Packet", systemImage: "arrow.right.circle")
                }
                
                Button(action: {
                    isMonitoring.toggle()
                    serialManager.sendCommand(isMonitoring ? PTCCommand.Packet.monitor : PTCCommand.disconnect)
                }) {
                    Label(isMonitoring ? "Stop Monitor" : "Start Monitor",
                          systemImage: isMonitoring ? "stop.circle" : "antenna.radiowaves.left.and.right")
                }
                .tint(isMonitoring ? .red : .blue)
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .padding()
            
            // Connection Controls
            HStack {
                TextField("Enter callsign", text: $callsign)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    serialManager.sendCommand(PTCCommand.Packet.connectTo(callsign))
                }) {
                    Label("Connect", systemImage: "link")
                }
                .disabled(callsign.isEmpty)
                
                Button(action: {
                    serialManager.sendCommand(PTCCommand.Packet.disconnect)
                }) {
                    Label("Disconnect", systemImage: "link.badge.plus")
                }
            }
            .padding(.horizontal)
            
            // Unproto Path Controls
            HStack {
                TextField("Enter unproto path", text: $unprotoPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    serialManager.sendCommand(PTCCommand.Packet.setUnproto(unprotoPath))
                }) {
                    Label("Set Path", systemImage: "arrow.triangle.branch")
                }
                .disabled(unprotoPath.isEmpty)
            }
            .padding(.horizontal)
            
            // Received Text Display
            ScrollView {
                Text(serialManager.receivedData)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            // Message Input and Send
            VStack {
                TextEditor(text: $messageToSend)
                    .frame(height: 100)
                    .font(.system(.body, design: .monospaced))
                    .cornerRadius(8)
                
                HStack {
                    Button(action: {
                        serialManager.sendCommand(messageToSend)
                        messageToSend = ""
                    }) {
                        Label("Send", systemImage: "paperplane")
                    }
                    .disabled(messageToSend.isEmpty)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            PacketSettingsView()
        }
        .navigationTitle("Packet Radio Mode")
    }
}

struct PacketSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var serialManager: SerialManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Status")) {
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.status)
                    }) {
                        Text("Request Status")
                    }
                }
                
                Section(header: Text("Channel")) {
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.System.channel)
                    }) {
                        Text("Show Channel Status")
                    }
                }
            }
            .navigationTitle("Packet Radio Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct PacketView_Previews: PreviewProvider {
    static var previews: some View {
        PacketView()
            .environmentObject(SerialManager())
    }
} 