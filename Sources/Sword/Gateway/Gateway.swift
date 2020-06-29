//
//  Gateway.swift
//  Sword
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation
import Dispatch

//#if !os(Linux)
//import Starscream
//#else
//import Sockets
//import TLS
//import URI
//import WebSockets
//#endif
import HTTPKit

protocol Gateway: class {
	var eventLoopGroup: EventLoopGroup { get set }

  var gatewayUrl: String { get set }

  var heartbeatPayload: Payload { get }
  
  var heartbeatQueue: DispatchQueue! { get }
  
  var isConnected: Bool { get set }
  
  var session: WebSocket? { get set }
  
  var wasAcked: Bool { get set }
  
  func handleDisconnect(for code: Int)
	func handleDisconnect(with code: WebSocketErrorCode)
  
  func handlePayload(_ payload: Payload)
  
  func heartbeat(at interval: Int)
  
  func reconnect()
  
  func send(_ text: String, presence: Bool)
  
  func start()

  func stop()

}

extension Gateway {
  
  /// Starts the gateway connection
  func start() {
//    #if !os(Linux)
//    if self.session == nil {
//      self.session = WebSocket(url: URL(string: self.gatewayUrl)!)
//
//      self.session?.onConnect = { [unowned self] in
//        self.isConnected = true
//      }
//
//      self.session?.onText = { [unowned self] text in
//        self.handlePayload(Payload(with: text))
//      }
//
//      self.session?.onDisconnect = { [unowned self] error in
//        self.isConnected = false
//
//        guard let error = error else { return }
//
//        self.handleDisconnect(for: (error as NSError).code)
//      }
//    }
//
//    self.session?.connect()
//    #else
	let client = HTTPClient(configuration: .init(tlsConfig:.clientDefault), on: self.eventLoopGroup)
	var req = HTTPRequest(url: self.gatewayUrl)
	req.isKeepAlive = true
	
	req.webSocketUpgrade(onUpgrade:  { [unowned self](ws: WebSocket) in
		self.session = ws
		self.isConnected = true

		ws.onText({ _, text in
			self.handlePayload(Payload(with: text))
		})

		ws.onCloseCode({ (code: WebSocketErrorCode) in

			self.isConnected = false
			self.handleDisconnect(with: code)
		})
	})

	do {

		let rep = try client.send(req).wait()
		print(rep)

	}catch{
		print("[Sword] \(error.localizedDescription)")
		self.start()
	}

//    do {
//      let gatewayUri = try URI(self.gatewayUrl)
//      let tcp = try TCPInternetSocket(
//        scheme: "https",
//        hostname: gatewayUri.hostname,
//        port: gatewayUri.port ?? 443
//      )
//      let stream = try TLS.InternetSocket(tcp, TLS.Context(.client))
//      try WebSocket.connect(to: gatewayUrl, using: stream) {
//        [unowned self] ws in
//        
//        self.session = ws
//        self.isConnected = true
//        
//        ws.onText = { _, text in
//          self.handlePayload(Payload(with: text))
//        }
//
//        ws.onClose = { _, code, _, _ in
//          self.isConnected = false
//
//          guard let code = code else { return }
//
//          self.handleDisconnect(for: Int(code))
//        }
//      }
//    }catch {
//      print("[Sword] \(error.localizedDescription)")
//      self.start()
//    }
//    #endif
  }

}
