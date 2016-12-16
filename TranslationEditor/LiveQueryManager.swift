//
//  LiveQueryManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class is used for managing and listening to a live query
class LiveQueryManager<QueryTarget: View>: NSObject
{
	// PROPERTIES	------
	
	private let query: CBLLiveQuery
	private var listeners = [AnyLiveQueryListener<QueryTarget>]()
	private(set) var rows = [Row<QueryTarget>]()
	
	private var observes = false
	
	
	// INIT	--------------
	
	// Creates a new query manager for the provided query
	init(query: CBLLiveQuery)
	{
		self.query = query
	}
	
	
	// OVERRIDDEN	-----
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
	{
		if keyPath == "rows"
		{
			if let query = object as? CBLLiveQuery
			{
				if let results = query.rows
				{
					rows = []
					
					// Parses the results
					while let row = results.nextRow()
					{
						rows.append(Row<QueryTarget>(row))
					}
					
					// Informs the listeners
					for listener in listeners
					{
						listener.rowsUpdated(rows: rows)
					}
				}
			}
		}
		else
		{
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	
	// OTHER METHODS	----
	
	// Starts the query (if not started already) and the listening process
	func start()
	{
		if !observes
		{
			query.addObserver(self, forKeyPath: "rows", options: [], context: nil)
			observes = true
		}
		query.start()
	}
	
	// Pauses the query temporarily but doesn't stop observing process
	func pause()
	{
		query.stop()
	}
	
	// Stops the query and the observation process
	func stop()
	{
		if observes
		{
			query.removeObserver(self, forKeyPath: "rows")
			observes = false
		}
		rows = []
		query.stop()
	}
	
	// Adds a new listener that will be informed when the query updates
	// The query id is sent along the rows to the listener, if present
	func addListener(_ listener: AnyLiveQueryListener<QueryTarget>)
	{
		// No duplicates allowed
		if !listeners.containsReference(to: listener)
		{
			listeners.append(listener)
		}
	}

	// Removes a listener from this manager. This manager won't be calling the listener in the future
	func removeListener(_ listener: AnyLiveQueryListener<QueryTarget>)
	{
		for i in 0 ..< listeners.count
		{
			if listeners[i] === listener
			{
				listeners.remove(at: i)
				break
			}
		}
	}
	
	func removeListeners()
	{
		listeners = []
	}
}
