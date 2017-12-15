//
//  View.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.11.2016.
//  Copyright © 2017 SIL. All rights reserved.
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
	
	// The names of the keys. Ordered.
	static var keyNames: [String] {get}
	
	// The cbl view used by this view
	var view: CBLView {get}
}

// TODO: Update the view to use indexes. emit(CBLTextKey(longText), value);
extension View
{	
	// Calling this function will set the map function of the view
	// The map function can also be called through the view, but this version allows the 
	// user to operate on a parsed instance instead of raw document data
	func createMapBlock(using block: @escaping (Queried, CBLMapEmitBlock) -> ()) -> CBLMapBlock
	{
		func mapBlock(doc: [String : Any], emit: CBLMapEmitBlock)
		{
			// The object must be of correct type
			
			do
			{
				if let object = try Queried.create(cblProperties: doc)
				{
					block(object, emit)
				}
			}
			catch
			{
				print("DB ERROR: Error within map function: \(error)")
			}
		}
		
		return mapBlock
	}
	
	// Finds the correct index for a certain key name, if present within the keys
	static func indexOfKey(_ key: String) -> UInt?
	{
		for i in 0 ..< keyNames.count
		{
			if keyNames[i] == key
			{
				return UInt(i)
			}
		}
		
		return nil
	}
	
	// Finds the correct group level to use for grouping by the specified key
	static func groupLevel(for key: String) -> UInt?
	{
		// If there is only a single key, only grouplevel 1 is allowed
		if keyNames.count == 1
		{
			return 1
		}
		else if let index = indexOfKey(key)
		{
			// Also, last index can't be grouped
			if index == UInt(keyNames.count - 1)
			{
				return 0
			}
			else
			{
				return index + 1
			}
		}
		else
		{
			return nil
		}
	}
	
	// Creates a new query of this view
	func createQuery(ofType type: QueryType = .object, withKeys keys: [String : Key] = [:]) -> Query<Self>
	{
		return Query<Self>(type: type, range: keys)
	}
	
	// Creates a key set / range from the specified values
	// The values must be presented in the same order as in keyNames array
	// You may omit from 0 to n last values
	static func makeKeys(from keyValues: [Any?]) -> [String: Key]
	{
		var keys = [String: Key]()
		
		for i in 0 ..< keyValues.count
		{
			keys[keyNames[i]] = Key(keyValues[i])
		}
		
		return keys
	}
	
	/*
	// Creates a query that returns each row of this view
	func createAllQuery(descending: Bool = false) -> CBLQuery
	{
		let query = view.createQuery()
		query.descending = descending
		
		query.prefetch = true
		query.mapOnly = true
		
		return query
	}*/
	
	// Creates a query for a set of specified keys
	// Not all keys need to be specified
	/*
	func createQuery(forKeys keys: [String : Key], descending: Bool = false) -> CBLQuery
	{
		let key = Self.keyNames.map { keys[$0].or(Key.undefined) }
		return createQuery(key, descending: descending)
	}*/
	
	// Creates a query that fetches the results from a certain key range
	// The keys that are specified (not nil) are required of the returned rows
	// If there is a nil key, that means that any value is accepted for that key. That also means that the following keys won't be tested at all since they are hierarchical
	// The query is ascending by default
	/*
	func createQuery(_ key: [Key], descending: Bool = false) -> CBLQuery
	{
		let query = createAllQuery(descending: descending)
		
		if key.isEmpty
		{
			return query
		}
		
		// If only a single key is used, doesn't use array format
		if key.count == 1
		{
			let first = key.first!
			let key = descending ? first.inverted : first
			
			if key.isDefined
			{
				query.startKey = key.min
				query.endKey = key.max
			}
				
			return query
		}
		
		// A specified key limits the results to certain range. A nil value is used to specify which keys can have any value
		var min = [Any]()
		var max = [Any]()
		
		var lastSpecifiedIndex = -1
		for i in 0 ..< key.count
		{
			let key = key[i]
			min.append(key.min)
			max.append(key.max)
			
			if key.isDefined
			{
				lastSpecifiedIndex = i
			}
		}
		
		// If no keys were specified, uses a allQuery
		if lastSpecifiedIndex < 0
		{
			return query
		}
		// May also drop a certain amount of unnecessary keys at the end
		else
		{
			let unnecessaryKeys = key.count - lastSpecifiedIndex - 2
			if unnecessaryKeys > 0
			{
				min = Array(min.dropLast(unnecessaryKeys))
				max = Array(max.dropLast(unnecessaryKeys))
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
		
		// If all keys have been specified, the query is inclusive, otherwise it is exclusive
		/*
		query.inclusiveStart = allKeysSpecified
		query.inclusiveEnd = allKeysSpecified
		*/
		
		return query
	}*/
}
