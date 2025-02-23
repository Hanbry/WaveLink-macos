//
//  ContentView.swift
//  WaveLink
//
//  Created by Adrian Lohr on 23.02.25.
//

import SwiftUI

enum MainViewSelection {
    case standby
    case pactor
    case packet
    case mailbox
}

struct ContentView: View {
    @StateObject private var serialManager = SerialManager()
    @State private var selectedView: MainViewSelection = .standby
    @State private var showingPortSelector = false
    
    var body: some View {
        NavigationView {
            SidebarView(selectedView: $selectedView)
            
            Group {
                switch selectedView {
                case .pactor:
                    PactorView()
                case .packet:
                    PacketView()
                case .mailbox:
                    MailboxView()
                case .standby:
                    StandbyView()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack {
                    Circle()
                        .fill(serialManager.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Button(action: {
                        showingPortSelector = true
                    }) {
                        Text(serialManager.selectedPortInfo?.name ?? "Select Port")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPortSelector) {
            PortSelectorView(serialManager: serialManager)
        }
        .environmentObject(serialManager)
    }
}

struct SidebarView: View {
    @Binding var selectedView: MainViewSelection
    
    var body: some View {
        List(selection: $selectedView) {
            NavigationLink(destination: StandbyView()) {
                Label("Standby", systemImage: "power.circle")
            }
            .tag(MainViewSelection.standby)
            
            NavigationLink(destination: PactorView()) {
                Label("PACTOR", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(MainViewSelection.pactor)
            
            NavigationLink(destination: PacketView()) {
                Label("Packet Radio", systemImage: "network")
            }
            .tag(MainViewSelection.packet)
            
            NavigationLink(destination: MailboxView()) {
                Label("Mailbox", systemImage: "tray.full")
            }
            .tag(MainViewSelection.mailbox)
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
    }
}

struct PortSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var serialManager: SerialManager
    
    var body: some View {
        NavigationView {
            List(serialManager.availablePortInfos, id: \.path) { portInfo in
                Button(action: {
                    serialManager.selectedPort = portInfo.path
                    serialManager.connect()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(portInfo.name)
                        Spacer()
                        if serialManager.selectedPort == portInfo.path {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Serial Port")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
