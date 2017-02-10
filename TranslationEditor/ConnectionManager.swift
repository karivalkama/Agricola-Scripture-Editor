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
	private(set) var targetTransferCount = 0
	private(set) var completedTransferCount = 0
	
	private var replications = [CBLReplication]()
	private var observers = [NSObjectProtocol]()
	private var listeners = [ConnectionListener]()
	
	
	// COMPUTED PROPERTIES	----
	
	// The relative progress of the sync process
	// Between 0 and 1
	var progress: Double
	{
		if targetTransferCount == 0
		{
			return status == .upToDate ? 1 : 0
		}
		else
		{
			return Double(completedTransferCount) / Double(targetTransferCount)
		}
	}
	
	
	// INIT	--------------------
	
	// Initialisation hidden behind static interface
	private init() { }
	
	
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
	
	// Adds a new listener to this connection manager. 
	// The listener will be informed whenever the manager's status changes
	func registerListener(_ listener: ConnectionListener)
	{
		if !listeners.contains(where: { $0 === listener })
		{
			listeners.append(listener)
		}
	}
	
	// Removes a listener from this connection manager so that it is no longer informed when connection status changes
	func removeListener(_ listener: ConnectionListener)
	{
		listeners = listeners.filter { !($0 === listener) }
	}
	
	private func updateStatus(n: Notification)
	{
		let oldStatus = status
		
		// If either replication is active, this process is considered to be active too
		if replications.contains(where: { $0.status == .active })
		{
			targetTransferCount = Int(replications.reduce(0, { $0 + $1.changesCount }))
			completedTransferCount = Int(replications.reduce(0, { $0 + $1.completedChangesCount }))
			
			status = .active
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
				completedTransferCount = targetTransferCount
				status = .upToDate
			}
		}
		
		// Informs the listeners of the status change
		if oldStatus != status
		{
			listeners.forEach { $0.onConnectionStatusChange(newStatus: status) }
		}
	}
}

// These are the different statuses a connection may have
enum ConnectionStatus
{
	// Connection is disconnected when there is no attempt to connect, connecting before any connection results have been made, 
	// offline when connection establishing fails, unauthorized when the provided credentials are not accepted 
	// and upToDate when all data has been synced
	case disconnected, connecting, upToDate, offline, unauthorized
	// The connection is active while it is transferring data
	case active
}
