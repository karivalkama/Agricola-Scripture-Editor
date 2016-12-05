//
//  DBModel.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes implementing this protocol can be updated into and from the database
protocol Storable: JSONConvertible
{
	// The properties that form the unique index of the instance
	// These properties should always be constants
	// Id properties don't need to (/ shouldn't) be part of the reqular object properties 
	var idProperties: [Any] {get}
	
	// Each class has a certain way of parsing a unique identifier from certain properties. 
	// This map is used for retrieving those properties from id data.
	// Each property name should match a certain index / range of id parts, which must correspond with the idProperties values
	static var idIndexMap : [String : IdIndex] {get}
	
	// The type of this storable instance. Should be stored as a property, always
	static var type: String {get}
	
	// Updates the object's state based on the provided properties
	func update(with properties: PropertySet) throws
	
	// Creates a new instance from the provided data
	// The id properties should be created using the provided 'id'
	// The other properties are based on 'properties'
	// One can use the update(with properties) -method here as necessary
	// Should throw a JSONParseError if the instance couldn't be created
	static func create(from properties: PropertySet, withId id: Id) throws -> Self
}

extension Storable
{
	// The parsed unique id of the instance, based on the id properties
	var idString: String {return parseId(from: idProperties)}
	
	// The parsed id for this instance. The id can be used for accessing 
	// constant id properties of this class
	var id: Id {return Self.createId(from: idString)}
	
	// The database document corresponding to this instance
	var document: CBLDocument {return DATABASE.document(withID: idString)!}
	
	// Pushes the instance data into the database
	// If 'overwrite' is set to true, removes any values from the database 
	// document that are not found in the instance at the time of this method call
	func push(overwrite: Bool = false) throws
	{
		try document.update
		{
			newRev in
			
			for (propertyName, propertyValue) in self.properties
			{
				if let propertyValue = propertyValue.any
				{
					newRev[propertyName] = propertyValue
				}
				else if overwrite
				{
					newRev.properties?.removeObject(forKey: propertyName)
				}
			}
			
			return true
		}
	}
	
	// Pushes certain property data to the database
	// If 'overwrite' is set to true, the property data will match the database data even if this model doesn't have a value for the provided property
	func pushProperties(named propertyNames: [String], overwrite: Bool = false) throws
	{
		if !propertyNames.isEmpty
		{
			try document.update
			{
				newRev in
				
				for propertyName in propertyNames
				{
					if let property = self.properties[propertyName], let value = property.any
					{
						newRev[propertyName] = value
					}
					else if overwrite
					{
						newRev.properties?.removeObject(forKey: propertyName)
					}
				}
				
				return true
			}
		}
	}
	
	// Updates the instance by reading its data from the database
	func update() throws
	{
		try update(with: PropertySet(document.properties!))
	}
	
	// Updates this instance with the data of another instance
	func update(with other: JSONConvertible) throws
	{
		try update(with: other.toPropertySet)
	}
	
	// Deletes the instance from the database
	func delete() throws
	{
		try document.delete()
	}
	
	// Parses an id compatible with this class from a unique id string
	static func createId(from idString: String) -> Id
	{
		return Id(id: idString, indexMap: idIndexMap)
	}
	
	// Wraps a database document into an instance of this class
	static func wrap(_ document: CBLDocument) throws -> Self
	{
		return try create(from: PropertySet(document.properties!), withId: createId(from: document.documentID))
	}
	
	// Finds and creates an instance of this class for the provided id
	// Returns nil if there wasn't a saved revision for the provided id
	// Throws an error if instance generation failed
	static func get(_ id: String) throws -> Self?
	{
		if let document = DATABASE.existingDocument(withID: id)
		{
			return try wrap(document)
		}
		else
		{
			return nil
		}
	}
	
	// Finds or creates an instance of this class for the provided id
	// Returns nil if there wasn't a saved revision for the provided id
	static func get(_ idArray: [Any]) throws -> Self?
	{
		return try get(parseId(from: idArray))
	}
	
	// Retrieves a single instance of this class by using the provided query
	// The query limit is automatically set to 1
	// If the query results were empty, returns nil
	static func fromQuery(_ query: CBLQuery) throws -> Self?
	{
		query.limit = 1
		
		var foundInstance: Self?
		try enumerateQuery(query)
		{
			foundInstance = $0
			return false
		}
		
		return foundInstance
	}
	
	// Retrieves a list of objects from a single database query
	static func arrayFromQuery(_ query: CBLQuery) throws -> [Self]
	{
		var foundInstances = [Self]()
		try enumerateQuery(query)
		{
			foundInstances.append($0)
			return true
		}
		
		return foundInstances
	}
	
	// Goes through the results of the provided query using the provided enumerator
	// A parsed instance is passed to the enumerator for each results row
	// The return value of the enumerator decides, whether the next row will be parsed
	static func enumerateQuery(_ query: CBLQuery, using enumerator: (Self) throws -> Bool) throws
	{
		query.prefetch = true
		
		let results = try query.run()
		
		while let row = results.nextRow()
		{
			if try !enumerator(try Row<Self>(row).object)
			{
				break
			}
		}
	}
}
