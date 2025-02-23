import Foundation

enum OperationMode: String {
    case pactor = "PAC"
    case packet = "PR"
    case standby = "STBY"
}

struct PTCCommand {
    static let switchToPactor = "pac"
    static let switchToPacket = "pr"
    static let disconnect = "d"
    static let quit = "q"
    static let status = "sta"
    
    // PACTOR commands
    struct Pactor {
        static let listen = "pl"
        static let call = "pc"
        static let longPath = "plong"
        static let shortPath = "pshort"
        static let speedUp = "+"
        static let speedDown = "-"
        
        static func callStation(_ callsign: String) -> String {
            return "pc \(callsign)"
        }
    }
    
    // Packet Radio commands
    struct Packet {
        static let connect = "c"
        static let disconnect = "d"
        static let monitor = "m"
        static let unproto = "u"
        
        static func connectTo(_ callsign: String) -> String {
            return "c \(callsign)"
        }
        
        static func setUnproto(_ path: String) -> String {
            return "u \(path)"
        }
    }
    
    // Mailbox commands
    struct Mailbox {
        static let enter = "box"
        static let list = "dir"
        static let read = "r"
        static let delete = "era"
        static let send = "send"
        static let quit = "q"
        
        static func readMessage(_ number: Int) -> String {
            return "r \(number)"
        }
        
        static func deleteMessage(_ number: Int) -> String {
            return "era \(number)"
        }
        
        static func sendMessage(to recipient: String, subject: String) -> String {
            return "send \(recipient) \(subject)"
        }
    }
    
    // System commands
    struct System {
        static let reset = "res"
        static let version = "ver"
        static let help = "help"
        static let channel = "chan"
        
        static func setBaudRate(_ rate: Int) -> String {
            return "baud \(rate)"
        }
    }
} 