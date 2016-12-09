//
//  CommitView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class CommitView: View
{
	// TYPES	-------------
	
	typealias Queried = Commit
	
	
	// PROPERTIES	---------
	
	static let instance = CommitView()
	
	let view: CBLView
	
	
	// INIT	-----------------
	
	private init()
	{
		view = DATABASE.viewNamed("commits")
		view.setMapBlock(createMapBlock
		{
			(commit, emit) in
			
			// Key = paragraph id + creation time
			let key = [commit.paragraphId, commit.created] as [Any]
			
			emit(key, nil)
			
		}, version: "1")
	}
	
	
	// OTHER	-------------
	
	func createQuery(paragraphId: String?, created: Double? = nil, descending: Bool = false) -> CBLQuery
	{
		return createQuery(forKeys: [paragraphId, created], descending: descending)
	}
	
	func lastCommit(of paragraphId: String) throws -> Commit?
	{
		return try Commit.fromQuery(createQuery(paragraphId: paragraphId, descending: true))
	}
	
	// Returns an array of commits that were introduced before the provided commit to the same paragraph
	// The returned commits are ordered from the most recent to the oldest
	func commits(before commit: Commit, limit: UInt? = nil) throws -> [Commit]
	{
		let query = createAllQuery(descending: true)
		
		query.startKey = [commit.paragraphId, commit.created]
		query.startKeyDocID = commit.idString
		query.inclusiveStart = false
		
		if let limit = limit
		{
			query.limit = limit
		}
		
		return try Commit.arrayFromQuery(query)
	}
}
