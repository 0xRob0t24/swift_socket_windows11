import WinSDK

func createServer() {
    var wsaData = WSADATA()
    
    // Initialize Winsock
    let version: WORD = 0x0202 // MAKEWORD(2, 2)
    let result = WSAStartup(version, &wsaData)
    guard result == 0 else {
        print("WSAStartup failed with error \(result)")
        return
    }
    
    // Create socket
    let socketHandle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP.rawValue)
    guard socketHandle != INVALID_SOCKET else {
        print("Socket creation failed with error \(WSAGetLastError())")
        WSACleanup()
        return
    }

    print("Socket created successfully!")

    // Set up sockaddr_in
    var serverAddr = sockaddr_in()
    memset(&serverAddr, 0, MemoryLayout<sockaddr_in>.size)
    serverAddr.sin_family = UInt16(AF_INET)
    serverAddr.sin_port = htons(8080) // Port 8080

    // Set sin_addr to INADDR_ANY
    let addrAny: UInt32 = 0 // INADDR_ANY in network byte order
    let addrAnyNetworkOrder = addrAny.bigEndian
    withUnsafeMutablePointer(to: &serverAddr.sin_addr) { addrPointer in
        addrPointer.withMemoryRebound(to: UInt32.self, capacity: 1) { boundPointer in
            boundPointer.pointee = addrAnyNetworkOrder
        }
    }

    // Bind socket to address
    let bindResult = withUnsafePointer(to: &serverAddr) { addr in
        addr.withMemoryRebound(to: sockaddr.self, capacity: 1) { rawAddr in
            bind(socketHandle, rawAddr, Int32(MemoryLayout<sockaddr_in>.size))
        }
    }
    
    guard bindResult != SOCKET_ERROR else {
        print("Bind failed with error \(WSAGetLastError())")
        closesocket(socketHandle)
        WSACleanup()
        return
    }

    print("Socket bound successfully!")

    // Listen for incoming connections
    let listenResult = listen(socketHandle, SOMAXCONN)
    guard listenResult != SOCKET_ERROR else {
        print("Listen failed with error \(WSAGetLastError())")
        closesocket(socketHandle)
        WSACleanup()
        return
    }

    print("Listening on port 8080...")
    
    // Accept incoming connection
    var clientAddr = sockaddr_in()
    var clientAddrLen = Int32(MemoryLayout<sockaddr_in>.size)
    let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { clientAddrPointer in
        clientAddrPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rawClientAddr in
            accept(socketHandle, rawClientAddr, &clientAddrLen)
        }
    }
    
    guard clientSocket != INVALID_SOCKET else {
        print("Accept failed with error \(WSAGetLastError())")
        closesocket(socketHandle)
        WSACleanup()
        return
    }

    print("Client connected!")

    // Receive data from client
    var buffer = [CChar](repeating: 0, count: 1024)
    let recvResult = recv(clientSocket, &buffer, Int32(buffer.count), 0)
    
    if recvResult > 0 {
        print("Received data: \(String(cString: buffer))")
    } else if recvResult == 0 {
        print("Connection closed by client")
    } else {
        print("Recv failed with error \(WSAGetLastError())")
    }

    // Send response to client
    let response = "Hello from server"
    let sendResult = response.withCString { cString in
        send(clientSocket, cString, Int32(strlen(cString)), 0)
    }
    
    if sendResult == SOCKET_ERROR {
        print("Send failed with error \(WSAGetLastError())")
    } else {
        print("Response sent successfully!")
    }
    
    // Close client socket
    closesocket(clientSocket)
    
    // Close server socket
    closesocket(socketHandle)
    
    // Clean up Winsock
    WSACleanup()
}

createServer()
