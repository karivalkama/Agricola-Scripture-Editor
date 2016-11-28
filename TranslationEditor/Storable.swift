//
//  DBModel.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes implementing this protocol can be updated into and from the database
protocol Storable
{
	// The properties that form the unique index of the instance
	// These properties should always be constants
	var idProperties: [Any] {get}
	// The other properties that the istance has
	var properties: [String : Any?] {get}
	
	// Updates the object's state based on the provided properties
	func update(with properties: PropertySet)
	
	// Creates a new instance from the provided data
	// The id properties should be created using the provided 'id'
	// The other properties are based on 'properties'
	// One can use the update(with properties) -method here as necessary
	static func create(from properties: PropertySet, withId id: [PropertyValue]) -> Self
}

extension Storable
{
	// The parsed unique id of the instance, based on the id properties
	var id: String {return parseId(from: idProperties)}
	// The database document corresponding to this instance
	var document: CBLDocument {return DATABASE.document(withID: id)!}
	
	// Pushes the instance data into the database
	// If 'overwrite' is set to true, removes any values from the database 
	// document that are not found in the instance at the time of this method call
	func push(overwrite: Bool = false) throws
	{
		let document = DATABASE.document(withID: id)
		try document?.update
		{
			newRev in
			
			for (propertyName, propertyValue) in self.properties
			{
				if let propertyValue = propertyValue
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
	
	// Updates the instance by reading its data from the database
	func update()
	{
		update(with: PropertySet(document.properties!))
	}
	
	// Wraps a database document into an instance of this class
	static func create(from document: CBLDocument) -> Self
	{
		let idProperties = document.documentID.components(separatedBy: ID_SEPARATOR).map{PropertyValue($0)}
		return create(from: PropertySet(document.properties!), withId: idProperties)
	}
	
	// Finds and creates an instance of this class for the provided id
	// Returns nil if there wasn't a saved revision for the provided id
	static func get(_ id: String) -> Self?
	{
		return create(from: DATABASE.existingDocument(withID: id)!)
	}
	
	// Finds or creates an instance of this class for the provided id
	// Returns nil if there wasn't a saved revision for the provided id
	static func get(_ idArray: [Any]) -> Self?
	{
		return get(parseId(from: idArray))
	}
}
