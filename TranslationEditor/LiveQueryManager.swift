//
//  LiveQueryManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class is used for managing and listening to a live query
class LiveQueryManager<Listener: LiveQueryListener>: NSObject
{
	// PROPERTIES	------
	
	private let query: CBLLiveQuery
	private var listeners = [(Listener, String?)]()
	private(set) var rows = [Row<Listener.Queried>]()
	
	private var observes = false
	
	
	// INIT	--------------
	
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
					do
					{
						// Parses the results
						while let row = results.nextRow()
						{
							rows.append(try Row<Listener.Queried>(row))
						}
						
						// Informs the listeners
						for (listener, queryId) in listeners
						{
							listener.rowsUpdated(rows: rows, forQuery: queryId)
						}
					}
					catch
					{
						print("ERROR: Failed to parse live query results \(error)")
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
	
	func start()
	{
		if !observes
		{
			query.addObserver(self, forKeyPath: "rows", options: [], context: nil)
			observes = true
		}
		query.start()
	}
	
	func pause()
	{
		query.stop()
	}
	
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
	
	/*
	func addListener(_ listener: Listener, withQueryId queryId: String? = nil)
	{
		if !listeners.contains(where: { $0 === listener })
		{
			
		}
	}
*/
}
