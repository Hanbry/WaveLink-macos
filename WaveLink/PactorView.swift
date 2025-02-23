import SwiftUI

struct PactorView: View {
    @EnvironmentObject var serialManager: SerialManager
    @State private var callsign = ""
    @State private var receivedText = ""
    @State private var messageToSend = ""
    @State private var isListening = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status and Control Bar
            HStack {
                Button(action: {
                    serialManager.sendCommand(PTCCommand.switchToPactor)
                }) {
                    Label("Switch to PACTOR", systemImage: "arrow.right.circle")
                }
                
                Button(action: {
                    isListening.toggle()
                    serialManager.sendCommand(isListening ? PTCCommand.Pactor.listen : PTCCommand.disconnect)
                }) {
                    Label(isListening ? "Stop Listening" : "Start Listening", 
                          systemImage: isListening ? "stop.circle" : "ear")
                }
                .tint(isListening ? .red : .blue)
                
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
                    serialManager.sendCommand(PTCCommand.Pactor.callStation(callsign))
                }) {
                    Label("Connect", systemImage: "antenna.radiowaves.left.and.right")
                }
                .disabled(callsign.isEmpty)
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
            
            // Message Input and Controls
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
                    
                    Spacer()
                    
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.Pactor.speedDown)
                    }) {
                        Label("Speed Down", systemImage: "tortoise")
                    }
                    
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.Pactor.speedUp)
                    }) {
                        Label("Speed Up", systemImage: "hare")
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            PactorSettingsView()
        }
        .navigationTitle("PACTOR Mode")
    }
}

struct PactorSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var serialManager: SerialManager
    @State private var selectedPath = "Short"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Path Selection")) {
                    Picker("Path Type", selection: $selectedPath) {
                        Text("Short Path").tag("Short")
                        Text("Long Path").tag("Long")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedPath) { oldValue, newValue in
                        serialManager.sendCommand(newValue == "Short" ? 
                            PTCCommand.Pactor.shortPath : 
                            PTCCommand.Pactor.longPath)
                    }
                }
                
                Section(header: Text("Status")) {
                    Button(action: {
                        serialManager.sendCommand(PTCCommand.status)
                    }) {
                        Text("Request Status")
                    }
                }
            }
            .navigationTitle("PACTOR Settings")
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

struct PactorView_Previews: PreviewProvider {
    static var previews: some View {
        PactorView()
            .environmentObject(SerialManager())
    }
} 