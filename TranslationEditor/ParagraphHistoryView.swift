//
//  ParagraphHistoryView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class ParagraphHistoryView: View
{
	// TYPES	-------------
	
	typealias Queried = Paragraph
	
	
	// PROPERTIES	---------
	
	static let KEY_BOOK_ID = "book_id"
	static let KEY_CHAPTER_INDEX = "chapter_index"
	static let KEY_PATH_ID = "path_id"
	static let KEY_CREATED = "created"
	
	static let VALUE_MOST_RECENT = "most_recent"
	static let VALUE_ID = "id"
	
	static let keyNames = [KEY_BOOK_ID, KEY_CHAPTER_INDEX, KEY_PATH_ID, KEY_CREATED]
	
	static let instance = ParagraphHistoryView()
	
	let view: CBLView
	
	
	// INIT	----------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_history")
		
		// Book id + chapter index + path id + created => is most recent
		view.setMapBlock(createMapBlock
		{
			paragraph, emit in
			
			// Only keeps track of non-deprecated paragraphs
			if !paragraph.isDeprecated
			{
				// Key = book id + chapter index + path id + created
				// This creates a properly ordered key
				let key = [paragraph.bookId, paragraph.chapterIndex, paragraph.pathId, paragraph.created] as [Any]
				
				// Value = most recent + id
				var value = PropertySet()
				value[ParagraphHistoryView.VALUE_MOST_RECENT] = PropertyValue(paragraph.isMostRecent)
				value[ParagraphHistoryView.VALUE_ID] = PropertyValue(paragraph.idString)
				
				emit(key, value.toDict)
			}
			
		}, reduce:
		{
			_, values, rereduce in
			
			// Lists the ids of most recent rows
			if rereduce
			{
				// rereduce combines collected lists
				var combinedIds = [String]()
				values.forEach { combinedIds.append(contentsOf: $0 as! [String]) }
				
				return combinedIds
			}
			else
			{
				var recentIds = [String]()
				for rawValue in values
				{
					let value = PropertySet(rawValue as! [String : Any])
					if value[ParagraphHistoryView.VALUE_MOST_RECENT].bool()
					{
						recentIds.append(value[ParagraphHistoryView.VALUE_ID].string())
					}
				}
				
				return recentIds
			}
			
		}, version: "2")
		
		/*
		view.setMapBlock(createMapBlock
		{
			paragraph, emit in
			
			// Key = Previous paragraph id + deprecated
			if let lastVersionId = paragraph.createdFrom
			{
				let key = [lastVersionId, paragraph.isDeprecated] as [Any]
				emit(key, nil)
			}
			
		}, reduce: countRowsReduce, version: "1")*/
	}
	
	
	// OTHER METHODS	---
	
	// A query for the whole history of a paragraph, from oldest to the most recent
	func historyQuery(bookId: String, chapterIndex: Int, pathId: String) -> Query<ParagraphHistoryView>
	{
		return createQuery().withRange(createKey(bookId: bookId, firstChapter: chapterIndex, lastChapter: chapterIndex, pathId: pathId))
	}
	
	// A query for the whole history of a specific paragraph instance, from the oldest to the most recent
	func historyQuery(paragraphId: String) -> Query<ParagraphHistoryView>
	{
		// Parses the search data from the id first
		let id = Paragraph.createId(from: paragraphId)
		let bookId = id[Paragraph.PROPERTY_BOOK_ID].string()
		let chapterIndex = id[Paragraph.PROPERTY_CHAPTER_INDEX].int()
		let pathId = id[Paragraph.PROPERTY_PATH_ID].string()
		
		return historyQuery(bookId: bookId, chapterIndex: chapterIndex, pathId: pathId)
	}
	
	// The backwards or forwards history of a certain paragraph instance
	func historyOfParagraphQuery(paragraphId: String, limit: Int, goForward: Bool = false) -> Query<ParagraphHistoryView>
	{
		var query = historyQuery(paragraphId: paragraphId)
		query.limit = limit
		
		if goForward
		{
			query.minId = (paragraphId, false)
		}
		else
		{
			query.maxId = (paragraphId, false)
		}
		
		return query
	}
	
	// Deprecates the whole path of a paragraph
	func deprecatePath(ofId paragraphId: String) throws
	{
		// Finds the ids to deprecate
		let ids = try historyQuery(paragraphId: paragraphId).resultRows().map { $0.id! }
		
		// Deprecates the ids, if there are any
		if !ids.isEmpty
		{
			try DATABASE.tryTransaction
			{
				try Paragraph.deprecate(ids: ids)
			}
		}
	}
	
	// Finds the id of the most recent version of the paragraph
	func mostRecentId(forParagraphWithId paragraphId: String) throws -> String?
	{
		// Creates the key first
		let keys = [
			ParagraphHistoryView.KEY_BOOK_ID: Key(Paragraph.bookId(fromId: paragraphId)),
			ParagraphHistoryView.KEY_CHAPTER_INDEX: Key(Paragraph.chapterIndex(fromId: paragraphId)),
			ParagraphHistoryView.KEY_PATH_ID: Key(Paragraph.pathId(fromId: paragraphId)),
			ParagraphHistoryView.KEY_CREATED: Key.undefined]
		
		// The most recent id(s) are produced by a reduce query
		let query = createQuery(ofType: .reduce, withKeys: keys)
		
		return try query.firstResultRow()?.value.array?.first?.string
	}
	
	// Finds all conflicting paragraphs in certain chapter range
	// Returns a map for each conflicting paragraph path that has all conflicting ids as values
	func conflictsInRange(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) throws -> [String : [String]]
	{
		let query = Query<ParagraphHistoryView>.reduceQuery(groupBy: ParagraphHistoryView.KEY_PATH_ID).withRange(createKey(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter, pathId: nil))
		
		// Runs the query and finds the rows where there are multiple latest versions
		var conflictPaths = [String : [String]]()
		try query.enumerateResult
		{
			row in
			
			let ids = row.value.array()
			if ids.count > 1
			{
				conflictPaths[row[ParagraphHistoryView.KEY_PATH_ID].string()] = ids.map { $0.string() }
			}
			
			return true
		}
		
		return conflictPaths
	}
	
	// Finds the latest common ancestor of all the provided paragraph ids
	// This method should be called only for paragraphs that share a path / history together. Usually for paragraphs returned by the conflictsInRange -method
	func commonAncestorOf(paragraphIds: [String]) throws -> Paragraph?
	{
		if paragraphIds.count < 2
		{
			return nil
		}
		
		// Finds the history of the paragraphs (assumes that they have the same history)
		var query = historyQuery(paragraphId: paragraphIds.first!).asQueryOfType(.noObjects)
		query.descending = true
		
		var pathLeaves = [String : Paragraph]()
		var conflictsFound = false
		var timeLimit: TimeInterval!
		var commonAncestor: Paragraph?
		
		// Enumerates through the history back in time
		try query.enumerateResult
		{
			row in
			
			// Until all of the conflicts are found, searches for the marked nodes
			if !conflictsFound
			{
				if paragraphIds.contains(row.id!)
				{
					let paragraph = try row.object()
					pathLeaves[row.id!] = paragraph
					
					if pathLeaves.count == paragraphIds.count
					{
						conflictsFound = true
						timeLimit = paragraph.created
						
						// Finds the last nodes before the provided limit
						for paragraphId in paragraphIds
						{
							if let ancestor = try pathLeaves[paragraphId]?.latestVersionBefore(timeLimit)
							{
								pathLeaves[paragraphId] = ancestor
							}
							else
							{
								return false
							}
						}
						
						// It may be that the common ancestor was already found
						let id = row.id!
						if pathLeaves.filter({ $0.1.idString == id }).count == pathLeaves.count
						{
							commonAncestor = paragraph
							return false
						}
					}
				}
			}
			// After all of the conflicts (but not the common ancestor) are found, 
			// Checks if any of the following paragraphs suffices as the common ancestor
			else
			{
				let paragraph = try row.object()
				var thisIsTheOne = true
				
				for paragraphId in paragraphIds
				{
					if let ancestor = try pathLeaves[paragraphId]!.latestVersionBefore(paragraph.created)
					{
						pathLeaves[paragraphId] = ancestor
						if ancestor.idString != paragraph.idString
						{
							thisIsTheOne = false
						}
					}
					else
					{
						return false
					}
				}
				
				if thisIsTheOne
				{
					commonAncestor = paragraph
					return false
				}
			}
			
			return true
		}
		
		return commonAncestor
	}
	
	private func createKey(bookId: String?, firstChapter: Int?, lastChapter: Int?, pathId: String?) -> [String : Key]
	{
		return [
			ParagraphHistoryView.KEY_BOOK_ID : Key(bookId),
			ParagraphHistoryView.KEY_CHAPTER_INDEX : Key([firstChapter, lastChapter]),
			ParagraphHistoryView.KEY_PATH_ID : Key(pathId)
		]
	}
	
	/*
	// Creates a query that will search for the next version(s) of a paragraph
	// If includeDeprecated is set to true, also returns possible deprecated versions
	func nextVersionQuery(paragraphId: String, includeDeprecated: Bool = false) -> Query<ParagraphHistoryView>
	{
		var keys = [ParagraphHistoryView.KEY_PARAGRAPH_ID : Key(paragraphId)]
		if !includeDeprecated
		{
			keys[ParagraphHistoryView.KEY_DEPRECATED] = Key(false)
		}
		
		return Query<ParagraphHistoryView>(range: keys)
	}
	
	// Finds the paragraph ids of the versions following the provided paragraph version
	func nextVersionIds(paragraphId: String, includeDeprecated: Bool = false) throws -> [String]
	{
		let query = nextVersionQuery(paragraphId: paragraphId, includeDeprecated: includeDeprecated).asQueryOfType(QueryType.noObjects)
		let rows = try query.resultRows()
		
		return rows.map { $0.id! }
	}
	
	// Checks whether the version 'tree' splits on this paragraph id / version
	// This can be used for determining whether a paragraph version is the root of a conlict
	func versionSplits(paragraphId: String, includeDeprecated: Bool = false) throws -> Bool
	{
		let query = nextVersionQuery(paragraphId: paragraphId, includeDeprecated: includeDeprecated).asQueryOfType(QueryType.reduce)
		
		if let row = try query.firstResultRow()
		{
			return row.value.int() > 1
		}
		else
		{
			return false
		}
	}*/
}
