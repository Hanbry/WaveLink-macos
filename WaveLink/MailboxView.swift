import SwiftUI

struct Message: Identifiable {
    let id: Int
    let from: String
    let subject: String
    let date: String
    let size: String
}

struct MailboxView: View {
    @EnvironmentObject var serialManager: SerialManager
    @State private var messages: [Message] = []
    @State private var showingNewMessage = false
    @State private var selectedMessage: Int?
    @State private var messageContent = ""
    @State private var isInMailbox = false
    
    // New message properties
    @State private var recipient = ""
    @State private var subject = ""
    @State private var messageBody = ""
    
    var body: some View {
        VStack {
            // Mailbox Controls
            HStack {
                Button(action: {
                    if !isInMailbox {
                        serialManager.sendCommand(PTCCommand.Mailbox.enter)
                        isInMailbox = true
                    }
                    serialManager.sendCommand(PTCCommand.Mailbox.list)
                    parseMessages()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                
                Spacer()
                
                Button(action: {
                    showingNewMessage = true
                }) {
                    Label("New Message", systemImage: "square.and.pencil")
                }
            }
            .padding()
            
            // Messages List
            List(messages) { message in
                VStack(alignment: .leading) {
                    HStack {
                        Text("From: \(message.from)")
                            .font(.headline)
                        Spacer()
                        Text(message.date)
                            .font(.caption)
                    }
                    Text(message.subject)
                        .font(.subheadline)
                    Text("Size: \(message.size)")
                        .font(.caption)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedMessage = message.id
                    serialManager.sendCommand(PTCCommand.Mailbox.readMessage(message.id))
                }
                .contextMenu {
                    Button(role: .destructive) {
                        serialManager.sendCommand(PTCCommand.Mailbox.deleteMessage(message.id))
                        // Refresh the list after deletion
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            serialManager.sendCommand(PTCCommand.Mailbox.list)
                            parseMessages()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            // Message Content View
            if selectedMessage != nil {
                ScrollView {
                    Text(messageContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .padding()
            }
        }
        .sheet(isPresented: $showingNewMessage) {
            NavigationView {
                Form {
                    Section(header: Text("Message Details")) {
                        TextField("Recipient", text: $recipient)
                        TextField("Subject", text: $subject)
                    }
                    
                    Section(header: Text("Message")) {
                        TextEditor(text: $messageBody)
                            .frame(height: 200)
                    }
                }
                .navigationTitle("New Message")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingNewMessage = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") {
                            sendMessage()
                            showingNewMessage = false
                        }
                        .disabled(recipient.isEmpty || messageBody.isEmpty)
                    }
                }
            }
        }
        .navigationTitle("Mailbox")
        .onDisappear {
            if isInMailbox {
                serialManager.sendCommand(PTCCommand.Mailbox.quit)
                isInMailbox = false
            }
        }
    }
    
    private func parseMessages() {
        // This is a simple parser for the directory listing
        // Format typically looks like:
        // 1 DC7XJ Test message 12.02.24 1KB
        let lines = serialManager.receivedData.split(separator: "\n")
        messages = lines.compactMap { line in
            let parts = line.split(separator: " ")
            guard parts.count >= 5,
                  let id = Int(parts[0]) else { return nil }
            
            let from = String(parts[1])
            let dateIndex = parts.count - 2
            let sizeIndex = parts.count - 1
            let subjectWords = parts[2..<dateIndex].joined(separator: " ")
            
            return Message(
                id: id,
                from: from,
                subject: subjectWords,
                date: String(parts[dateIndex]),
                size: String(parts[sizeIndex])
            )
        }
    }
    
    private func sendMessage() {
        serialManager.sendCommand(PTCCommand.Mailbox.sendMessage(to: recipient, subject: subject))
        // Wait briefly for the system to be ready for the message body
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            serialManager.sendCommand(messageBody)
            // Send Ctrl+Z to end the message
            serialManager.sendCommand("\u{1A}")
        }
        
        // Clear the form
        recipient = ""
        subject = ""
        messageBody = ""
    }
}

struct MailboxView_Previews: PreviewProvider {
    static var previews: some View {
        MailboxView()
            .environmentObject(SerialManager())
    }
} 