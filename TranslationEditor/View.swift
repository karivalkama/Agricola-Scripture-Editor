//
//  View.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This protocol is implemented by CBL view interfaces
// The purpose of these views is to make creating queries easier
protocol View
{
	// The type of object queried through this view
	associatedtype Queried: Storable
	
	// All classes implementing this protocol must be globally accessible as singular instances
	static var instance: Self {get}
	
	// The cbl view used by this view
	var view: CBLView {get}
}

extension View
{
	// Calling this function will set the map function of the view
	// The map function can also be called through the view, but this version allows the 
	// user to operate on a parsed instance instead of raw document data
	func createMapBlock(using block: @escaping (Queried, CBLMapEmitBlock) -> ()) -> CBLMapBlock
	{
		func mapBlock(doc: [String : Any], emit: CBLMapEmitBlock)
		{
			do
			{
				// Only works on documents of the correct type
				if let type = doc[PROPERTY_TYPE] as? String, type == Queried.type
				{
					if let idString = doc["_id"] as? String
					{
						let id = Queried.createId(from: idString)
						let object = try Queried.create(from: PropertySet(doc), withId: id)
						
						block(object, emit)
					}
				}
			}
			catch
			{
				print("DB: Error within map function: \(error)")
			}
		}
		
		return mapBlock
	}
	
	// Creates a query that fetches the results from a certain key range
	// The keys that are specified (not nil) are required of the returned rows
	// If there is a nil key, that means that any value is accepted for that key. That also means that the following keys won't be tested at all since they are hierarchical
	// The query is ascending by default
	func createQuery(forKeys keys: [Any?], descending: Bool = false) -> CBLQuery
	{
		let query = view.createQuery()
		
		query.descending = descending
		query.prefetch = true
		
		// A specified key limits the results to certain range. A nil value (end) is used to specify which keys can have any value
		var min = [Any]()
		var max = [Any]()
		
		for key in keys
		{
			if let key = key
			{
				min.append(key)
				max.append(key)
			}
			else
			{
				min.append(NSNull())
				max.append([:])
				break
			}
		}
		
		// Descending queries have inverted ranges
		if descending
		{
			query.startKey = max
			query.endKey = min
		}
		else
		{
			query.startKey = min
			query.endKey = max
		}
		
		return query
	}
}
