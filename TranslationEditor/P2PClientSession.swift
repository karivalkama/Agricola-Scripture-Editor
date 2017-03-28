//
//  P2PClientSession.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class handles connection between P2P client and host
// Only a single session is used at a time
class P2PClientSession: ConnectionListener
{
	// ATTRIBUTES	--------------
	
	private(set) static var instance: P2PClientSession?
	
	let projectId: String
	
	private(set) var status: ConnectionStatus
	
	
	// COMPUTED PROPERTIES	------
	
	// Checks whether there is a currently active connection in place
	static var isConnected: Bool
	{
		return instance.exists { $0.status != .disconnected }
	}
	
	
	// INIT	----------------------
	
	private init(serverURL: String, userName: String?, password: String?, projectId: String)
	{
		self.projectId = projectId
		self.status = .connecting
		
		// Starts online connection and listens for the new status
		ConnectionManager.instance.connect(serverURL: serverURL, userName: userName, password: password, continuous: true)
		ConnectionManager.instance.registerListener(self)
	}
	
	
	// IMPLEMENTED METHODS	-------
	
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		self.status = status
		
		// Terminates the session when the connection disconnects
		if status == .disconnected
		{
			P2PClientSession.instance = nil
		}
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		// Doesn't need to react to progress updates
	}
	
	
	// OTHER METHODS	----------
	
	// Starts a new P2P session. If there was a previous session in place, terminates it
	static func start(serverURL: String, userName: String?, password: String?, projectId: String)
	{
		instance = P2PClientSession(serverURL: serverURL, userName: userName, password: password, projectId: projectId)
	}
	
	// Stops the ongoing P2P session, if there is one in place
	static func stop()
	{
		if isConnected
		{
			ConnectionManager.instance.disconnect()
			instance = nil
		}
	}
}
