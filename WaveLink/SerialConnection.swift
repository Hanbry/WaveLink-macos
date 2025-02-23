import Foundation
import IOKit
import IOKit.serial

class SerialConnection {
    private var port: Int32 = -1
    private var path: String
    private var readThread: Thread?
    private var isReading = false
    
    let baudRate: speed_t
    let onDataReceived: (Data) -> Void
    
    init(path: String, baudRate: Int = 57600, onDataReceived: @escaping (Data) -> Void) {
        self.path = path
        self.baudRate = speed_t(baudRate)
        self.onDataReceived = onDataReceived
    }
    
    deinit {
        close()
    }
    
    func open() -> Bool {
        port = Darwin.open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard port >= 0 else {
            print("Error opening serial port")
            return false
        }
        
        var options = termios()
        tcgetattr(port, &options)
        
        // Input flags
        options.c_iflag &= ~UInt(IGNBRK | BRKINT | ICRNL | INLCR | PARMRK | INPCK | ISTRIP | IXON)
        
        // Output flags
        options.c_oflag &= ~UInt(OCRNL | ONLCR | ONLRET | ONOCR | OFILL | OPOST)
        
        // Local flags
        options.c_lflag &= ~UInt(ECHO | ECHONL | ICANON | IEXTEN | ISIG)
        
        // Control flags
        options.c_cflag &= ~UInt(CSIZE | PARENB)
        options.c_cflag |= UInt(CS8 | CREAD | CLOCAL)
        
        // Set baud rate
        cfsetispeed(&options, baudRate)
        cfsetospeed(&options, baudRate)
        
        // Set read timeout
        options.c_cc.19 = 0  // VMIN = 0: Return as soon as any data is received
        options.c_cc.17 = 1  // VTIME = 1: 100ms timeout
        
        // Apply settings
        if tcsetattr(port, TCSANOW, &options) != 0 {
            print("Error configuring serial port")
            close()
            return false
        }
        
        startReading()
        return true
    }
    
    func close() {
        stopReading()
        if port >= 0 {
            Darwin.close(port)
            port = -1
        }
    }
    
    func send(_ data: Data) {
        guard port >= 0 else { return }
        
        data.withUnsafeBytes { buffer in
            let bytesWritten = write(port, buffer.baseAddress, buffer.count)
            if bytesWritten < 0 {
                print("Error writing to serial port: \(errno)")
            }
        }
    }
    
    func send(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        send(data)
    }
    
    private func startReading() {
        isReading = true
        readThread = Thread { [weak self] in
            self?.readLoop()
        }
        readThread?.start()
    }
    
    private func stopReading() {
        isReading = false
        readThread = nil
    }
    
    private func readLoop() {
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        while isReading {
            let bytesRead = read(port, buffer, bufferSize)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                DispatchQueue.main.async { [weak self] in
                    self?.onDataReceived(data)
                }
            } else if bytesRead < 0 && errno != EAGAIN {
                print("Error reading from serial port")
                break
            }
            
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
}

// MARK: - Serial Port Discovery
extension SerialConnection {
    static func availablePorts() -> [String] {
        var ports: [String] = []
        
        let matchingDict = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
        matchingDict[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes
        
        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS {
            var service: io_object_t
            repeat {
                service = IOIteratorNext(iterator)
                if service != 0 {
                    let path = getDevPath(from: service)
                    if let path = path {
                        ports.append(path)
                    }
                    IOObjectRelease(service)
                }
            } while service != 0
            IOObjectRelease(iterator)
        }
        
        return ports
    }
    
    private static func getDevPath(from service: io_object_t) -> String? {
        var path: String?
        if let bsdPathAsCFString = IORegistryEntryCreateCFProperty(service,
                                                                  "IOCalloutDevice" as CFString,
                                                                  kCFAllocatorDefault, 0) {
            path = (bsdPathAsCFString.takeUnretainedValue() as! CFString) as String
        }
        return path
    }
} 