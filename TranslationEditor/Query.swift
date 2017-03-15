//
//  Query.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 15.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A Query is an interface / wrapper for a CBL query
// The point of this interface is to make use of Row (and with that, the Storable) easier when working with CBL queries
// Plus, this version of query has value semantics, so it is safer to share
struct Query<V: View>
{
	// PROPERTIES	---------
	
	private var min: Any?
	private var max: Any?
	
	var minId: String? // Minimum id, only works when all keys have been specified
	var maxId: String? // Maximum id, only works when all keys have been specified
	var exclusive: Bool = false
	
	var descending = false
	
	var limit: Int?
	var skip: Int?
	
	var type = QueryType.object
	var groupByKey: String? // Only usable when the type is reduce
	
	
	// COMP. PROPERTIES	-----
	
	// A CBL query based on this query entry
	var toCBLQuery: CBLQuery
	{
		let query = V.instance.view.createQuery()
		
		query.descending = descending
		if descending
		{
			query.startKey = max
			query.endKey = min
			
			query.endKeyDocID = minId
			query.startKeyDocID = maxId
		}
		else
		{
			query.startKey = min
			query.endKey = max
			
			query.startKeyDocID = minId
			query.endKeyDocID = maxId
		}
		
		if let limit = limit
		{
			query.limit = UInt(limit)
		}
		if let skip = skip
		{
			query.skip = UInt(skip)
		}
		
		query.inclusiveEnd = !exclusive
		query.inclusiveStart = !exclusive
		
		query.prefetch = type == .object
		query.mapOnly = type != .reduce
		if let groupByKey = groupByKey, type == .reduce
		{
			if let groupIndex = V.groupLevel(for: groupByKey)
			{
				query.groupLevel = groupIndex
			}
		}
		
		return query
	}
	
	// A live query manager based on this query instance
	var liveQueryManager: LiveQueryManager<V>
	{
		return LiveQueryManager<V>(query: toCBLQuery.asLive())
	}
	
	
	// INIT	-----------------
	
	// Creates a new query with specified properties
	init(type: QueryType = .object, range keys: [String : Key]? = nil, descending: Bool = false, limit: Int? = nil, skip: Int? = nil, groupBy groupKey: String? = nil)
	{
		self.type = type
		self.descending = descending
		self.limit = limit
		self.skip = skip
		self.groupByKey = groupKey
		
		if let keys = keys
		{
			setKeyRange(keys)
		}
	}
	
	// Wraps a CBL query into a query
	init(_ query: CBLQuery)
	{
		self.descending = query.descending
		self.limit = Int(query.limit)
		self.skip = Int(query.skip)
		
		if descending
		{
			self.min = query.endKey
			self.max = query.startKey
			
			if let startKey = query.startKeyDocID
			{
				maxId = startKey
			}
			if let endKey = query.endKeyDocID
			{
				minId = endKey
			}
		}
		else
		{
			self.min = query.startKey
			self.max = query.endKey
			
			minId = query.startKeyDocID
			maxId = query.endKeyDocID
		}
		
		exclusive = !query.inclusiveStart || !query.inclusiveEnd
		
		if query.mapOnly
		{
			if query.prefetch
			{
				self.type = .object
			}
			else
			{
				self.type = .noObjects
			}
		}
		else
		{
			self.type = .reduce
		}
		
		if query.groupLevel > 0, V.keyNames.count >= Int(query.groupLevel)
		{
			self.groupByKey = V.keyNames[Int(query.groupLevel)]
		}
	}
	
	// Creates a new all objects query
	static func allObjectsQuery() -> Query
	{
		return Query(type: .object)
	}
	
	// Creates a new reduce query
	static func reduceQuery(groupBy key: String? = nil) -> Query
	{
		return Query(type: .reduce, groupBy: key)
	}
	
	
	// OTHER METHODS	-----
	
	// Returns a version of this query that is limited to certain number of items / rows
	func limitedTo(_ limit: Int, skip: Int? = nil) -> Query
	{
		var copy = self
		copy.limit = limit
		
		if let skip = skip
		{
			copy.skip = skip
		}
		
		return copy
	}
	
	// Returns a version of this query that has the specified type
	func asQueryOfType(_ type: QueryType) -> Query
	{
		if self.type == type
		{
			return self
		}
		else
		{
			var copy = self
			copy.type = type
			return copy
		}
	}
	
	// Returns a query with updated range
	func withRange(_ keys: [String : Key]) -> Query
	{
		var copy = self
		copy.setKeyRange(keys)
		
		return copy
	}
	
	// Updates the range of the query
	mutating func setKeyRange(_ keys: [String : Key])
	{
		let keyArray = V.keyNames.map { keys[$0].or(Key.undefined) }
		
		if !keyArray.isEmpty
		{
			// If only a single key is used, doesn't use array format
			if keyArray.count == 1
			{
				let first = keyArray.first!
				if first.isDefined
				{
					self.min = first.min
					self.max = first.max
				}
			}
			else
			{
				// A specified key limits the results to certain range. A nil value is used to specify which keys can have any value
				var min = [Any]()
				var max = [Any]()
				
				var lastSpecifiedIndex = -1
				for i in 0 ..< keyArray.count
				{
					let key = keyArray[i]
					min.append(key.min)
					max.append(key.max)
					
					if key.isDefined
					{
						lastSpecifiedIndex = i
					}
				}
				
				// If no keys were specified, uses a allQuery
				// May also drop a certain amount of unnecessary keys at the end
				if lastSpecifiedIndex >= 0
				{
					let unnecessaryKeys = keyArray.count - lastSpecifiedIndex - 2
					if unnecessaryKeys > 0
					{
						min = Array(min.dropLast(unnecessaryKeys))
						max = Array(max.dropLast(unnecessaryKeys))
					}
					
					self.min = min
					self.max = max
				}
			}
		}
	}
	
	// Performs this query and returns the first result row, if available
	// If the query is NOT of reduce type, limits the range to 1 for convenience. Reduce queries are still ran for the whole range though.
	func firstResultRow() throws -> Row<V>?
	{
		let query = type == .reduce ? self : limitedTo(1)
		let result = try query.toCBLQuery.run()
		
		if let rawRow = result.nextRow()
		{
			return Row<V>(rawRow)
		}
		else
		{
			return nil
		}
	}
	
	// Performs this query and returns all resulting rows
	func resultRows() throws -> [Row<V>]
	{
		let result = try toCBLQuery.run()
		
		var rows = [Row<V>]()
		while let rawRow = result.nextRow()
		{
			rows.append(Row<V>(rawRow))
		}
		
		return rows
	}
	
	// Performs this query and enumerates through the results using the provided enumerator
	// If the enumerator returns false, the process is stopped
	func enumerateResult(using enumerator: (Row<V>) throws -> Bool) throws
	{
		let result = try toCBLQuery.run()
		while let rawRow = result.nextRow()
		{
			if try !enumerator(Row<V>(rawRow))
			{
				break
			}
		}
	}
	
	// Performs this query and returns the object parsed from the first row, if available
	func firstResultObject() throws -> V.Queried?
	{
		return try firstResultRow().map { try $0.object() }
	}
	
	// Performs this query and returns all objects parsed from the result
	func resultObjects() throws -> [V.Queried]
	{
		return try resultRows().map { try $0.object() }
	}
	
	// Performs this query and enumerates through the resulting objects using the provided enumerator
	// If the enumerator returns false, the process is stopped
	func enumerateResultObjects(using enumerator: (V.Queried) throws -> Bool) throws
	{
		let result = try toCBLQuery.run()
		while let rawRow = result.nextRow()
		{
			if try !enumerator(Row<V>(rawRow).object())
			{
				break
			}
		}
	}
}
