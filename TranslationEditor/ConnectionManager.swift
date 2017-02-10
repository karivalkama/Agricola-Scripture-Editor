//
//  ConnectionManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This interface handles database connections to server(s) and P2P hosts
class ConnectionManager
{
	// ATTRBUTES	------------
	
	static let instance = ConnectionManager()
	
	private(set) var status = ConnectionStatus.disconnected
	
	private var replications = [CBLReplication]()
	private var observers = [NSObjectProtocol]()
	
	
	// INIT	--------------------
	
	// Initialisation hidden behind static interface
	private init()
	{
		// Set up connection systems (?)
	}
	
	
	// OTHER METHODS	--------
	
	// Connects to a new server address
	// Authorization is optional
	func connect(serverURL: String, userName: String? = nil, password: String? = nil)
	{
		// First disconnects the previous connection
		disconnect()
		
		guard let url = URL(string: DATABASE.name, relativeTo: URL(string: serverURL)) else
		{
			print("ERROR: Failed to create url based on '\(serverURL)'")
			return
		}
		
		// Creates new connections, uses authorization if available
		replications = [DATABASE.createPullReplication(url), DATABASE.createPushReplication(url)]
		
		replications.forEach { $0.continuous = true }
		
		if let userName = userName, let password = password
		{
			let auth = CBLAuthenticator.basicAuthenticator(withName: userName, password: password)
			replications.forEach { $0.authenticator = auth }
		}
		
		// Starts the synchronization
		status = .connecting
		replications.forEach { $0.start() }
		
		observers = replications.map { NotificationCenter.default.addObserver(forName: NSNotification.Name.cblReplicationChange, object: $0, queue: nil, using: updateStatus) }
	}
	
	// Disconnects the current connection
	// Has no effect if there is no connection
	func disconnect()
	{
		// Removes the observers first
		observers.forEach { NotificationCenter.default.removeObserver($0) }
		
		// Then stops the replications
		replications.forEach { $0.stop() }
		
		observers = []
		replications = []
		status = .disconnected
	}
	
	private func updateStatus(n: Notification)
	{
		// If either replication is active, this process is considered to be active too
		if replications.contains(where: { $0.status == .active })
		{
			let total = replications.reduce(0, { $0 + $1.changesCount })
			
			if total > 0
			{
				let completed = replications.reduce(0, { $0 + $1.completedChangesCount })
				status = .active(completion: Double(completed) / Double(total))
			}
			else
			{
				status = .active(completion: 0)
			}
			
		}
		// Same goes with offline
		else if replications.contains(where: { $0.status == .offline })
		{
			status = .offline
		}
		else
		{
			// Checks for authentication errors
			if replications.contains(where: { ($0.lastError as? NSError)?.code == 401 })
			{
				status = .unauthorized
			}
			else
			{
				status = .upToDate
			}
		}
	}
}

enum ConnectionStatus
{
	case disconnected, connecting, upToDate, offline, unauthorized
	case active(completion: Double)
}
