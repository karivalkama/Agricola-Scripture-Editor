//
//  ConflictResolver.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This interface goes through the database and resolves conflicts it finds
class ConflictResolver
{
	// PROPERTIES	-----------
	
	static let instance = ConflictResolver()
	
	// Type -> Id String + Conflicting property versions --> Merged properties
	private var mergers = [String : (String, [PropertySet]) throws -> PropertySet]()
	
	
	// INIT	-------------------
	
	private init()
	{
		// Static interface
	}
	
	
	// OTHER METHODS	-------
	
	// Adds a new tool to handle merge conflicts
	func addMerger<T: Storable>(_ merger: @escaping ([T]) throws -> (T))
	{
		mergers[T.type] =
		{
			idString, conflictProperties in
			
			return try merger(conflictProperties.map { try T.create(from: $0, withId: T.createId(from: idString)) }).toPropertySet
		}
	}
	
	// Performs the conflict search algorithm
	// Returns the number of handled conflicts
	func run() -> Int
	{
		var conflictsHandled = 0
		
		// Creates a query for all conflicting documents
		let query = DATABASE.createAllDocumentsQuery()
		query.allDocsMode = .onlyConflicts
		
		// Runs the query and applies merge where possible
		do
		{
			let results = try query.run()
			
			try DATABASE.tryTransaction
			{
				// Goes through each conflict row
				while let row = results.nextRow()
				{
					guard let document = row.document else
					{
						continue
					}
					
					// Finds the conflicting revisions
					let conflicts = try document.getConflictingRevisions()
					guard conflicts.count > 1 else
					{
						continue
					}
					
					guard let type = document[PROPERTY_TYPE] as? String else
					{
						print("ERROR: Conflict in typeless document \(document.documentID)")
						continue
					}
					
					// Finds the correct merge function
					guard let merge = self.mergers[type] else
					{
						print("ERROR: No conflict merger for document of type \(type)")
						continue
					}
					
					let mergedProperties = try merge(document.documentID, conflicts.map { PropertySet($0.properties!) })
					conflictsHandled += 1
					
					let current = document.currentRevision!
					for revision in conflicts
					{
						let newRevision = revision.createRevision()
						if revision == current
						{
							// Sets merge results to the version marked as current
							let finalProperties = newRevision.properties.map { PropertySet($0.toDict) }.or(PropertySet.empty) + mergedProperties
							newRevision.properties = NSMutableDictionary(dictionary: finalProperties.toDict)
						}
						else
						{
							// Deletes the other revisions
							newRevision.isDeletion = true
						}
						
						try newRevision.saveAllowingConflict()
					}
				}
			}
		}
		catch
		{
			print("ERROR: Conflict handling failed with error: \(error)")
		}
		
		return conflictsHandled
	}
}
