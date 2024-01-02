//
//  ContentView.swift
//  SocketAppS
//
//  Created by Enes Saglam on 2.01.2024.
//

import SwiftUI
import SocketIO

final class Service : ObservableObject {
    private var manager = SocketManager(socketURL: URL(string: "ws://localhost:3000")!,config: [.log(true), .compress])
    @Published var messages = [String]()
    init(){
        let socket = manager.defaultSocket
        socket.on(clientEvent: .connect) {(data, ack)in
            print("connected")
            socket.emit("NodeJS Server Port", "Hi nodejs server!")
        }
        socket.on("iOS client Port") { [weak self ](data, ack) in
            if let data = data[0] as? [String: String],
               let rawMassage = data["msg"] {
                DispatchQueue.main.async {
                    self?.messages.append(rawMassage)
                }
            }
        }
        sendMessage("hello")
        socket.connect()
    }
    func sendMessage(_ message: String) {
        let socket = manager.defaultSocket
        socket.on(clientEvent: .connect) { Data, ack in
            socket.emit("NodeJS Server Port", message)
            self.objectWillChange.send()
        }
        socket.connect()
       }
    
}
struct ContentView: View {
    @ObservedObject var service = Service()
    @State private var newMessage = ""

    var body: some View {
        VStack {
            
            Text("Received Message from Node.js")
                .font(.largeTitle)
            ForEach(service.messages, id:  \.self){ msg in
                Text(msg)
                    .font(.title)
            }
            TextField("Enter your message", text: $newMessage)
                           .padding()
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                       
                       Button("Send Message") {
                           service.sendMessage(newMessage)
                           newMessage = ""
                       }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
