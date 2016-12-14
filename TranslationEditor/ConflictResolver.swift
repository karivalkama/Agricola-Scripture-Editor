//
//  ConflictResolver.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This interface goes through the database and resolves conflicts it finds
class ConflictResolver
{
	// PROPERTIES	-----------
	
	static let instance = ConflictResolver()
	
	private var mergers = [String : Merge]()
	
	
	// INIT	-------------------
	
	private init()
	{
		// Static interface
	}
	
	
	// OTHER METHODS	-------
	
	// Adds a new tool to handle merge conflicts
	func addMerger(_ merger: @escaping Merge, forType type: String)
	{
		mergers[type] = merger
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
			DATABASE.inTransaction
			{
				do
				{
					while let row = results.nextRow()
					{
						if let document = row.document
						{
							let conflicts = try document.getConflictingRevisions()
							if conflicts.count > 1
							{
								// Checks if there is a merge available for the conflict
								if let type = document[PROPERTY_TYPE] as? String
								{
									do
									{
										if let merge = self.mergers[type]
										{
											let mergeResult = try merge(document.documentID ,conflicts.map { PropertySet($0.properties!) })
											conflictsHandled += 1
											
											let current = document.currentRevision!
											for revision in conflicts
											{
												let newRevision = revision.createRevision()
												if revision == current
												{
													// Adds the merge results to the current revision
													let afterMergeProperties = newRevision.properties.map { PropertySet($0.toDict) }.or(PropertySet.empty) + mergeResult
													newRevision.properties = NSMutableDictionary(dictionary: afterMergeProperties.toDict)
												}
												else
												{
													// Other, conflicting revisions, are deleted
													newRevision.isDeletion = true
												}
												
												// Saves the change to each revision
												// Uses special save feature to update conflicting revisions
												try newRevision.saveAllowingConflict()
											}
										}
										else
										{
											print("CONFLICT: No merge function for type \(type)")
										}
									}
									catch
									{
										print("CONFLICT: Merging failed for document \(document.documentID) \(error)")
									}
								}
								else
								{
									print("CONFLICT: Conflict in a typeless document \(document.documentID)")
								}
							}
						}
					}
				}
				catch
				{
					print("CONFLICT: Conflict handling failed with error \(error)")
					return false
				}
				
				return conflictsHandled > 0
			}
		}
		catch
		{
			print("CONFLICT: Conflict handlign failed with error \(error)")
		}
		
		return conflictsHandled
	}
}
