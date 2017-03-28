//
//  P2PClientSession.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation
import QRCodeReader

// This delegate will be informed when the session status changes
protocol P2PClientSessionDelegate: class
{
	// This function is called if the session setup got cancelled and no session was started
	func sessionSetupDidCancel()
	
	// This function is called before a session is started to make sure it is ok to use 
	// the provided project in this context
	// NB: It is possible that there is no project with a matching id on the system at the time of this function call
	func sessionShouldStart(projectId: String) -> Bool
	
	// This function is called after a P2P session successfully starts
	func sessionDidStart(_ session: P2PClientSession)
	
	// This function is called after a P2P session is terminated
	func sessionDidEnd(_ session: P2PClientSession)
}

// This class handles connection between P2P client and host
// Only a single session is used at a time
class P2PClientSession: ConnectionListener
{
	// ATTRIBUTES	--------------
	
	private(set) static var instance: P2PClientSession?
	
	let projectId: String
	
	private(set) var status: ConnectionStatus
	
	private weak var delegate: P2PClientSessionDelegate?
	
	
	// INIT	----------------------
	
	private init(serverURL: String, userName: String?, password: String?, projectId: String)
	{
		self.projectId = projectId
		self.status = .connecting
		
		// Starts online connection and listens for the new status
		ConnectionManager.instance.connect(serverURL: serverURL, userName: userName, password: password, continuous: true)
		ConnectionManager.instance.registerListener(self)
		
		delegate?.sessionDidStart(self)
	}
	
	
	// IMPLEMENTED METHODS	-------
	
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		self.status = status
		
		// Terminates the session when the connection disconnects
		if status == .disconnected
		{
			P2PClientSession.instance = nil
			delegate?.sessionDidEnd(self)
		}
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		// Doesn't need to react to progress updates
		var reader = QRCodeReaderViewController(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
	}
	
	
	// OTHER METHODS	----------
	
	static func startSessionScan(delegate: P2PClientSessionDelegate? = nil)
	{
		
	}
}
