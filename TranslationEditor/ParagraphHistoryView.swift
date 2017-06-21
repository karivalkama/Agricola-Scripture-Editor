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
	}
	
	
	// OTHER METHODS	---
	
	// A query for the whole history of a paragraph, from oldest to the most recent
	func historyQuery(bookId: String, chapterIndex: Int, pathId: String) -> Query<ParagraphHistoryView>
	{
		return createQuery(withKeys: createKey(bookId: bookId, firstChapter: chapterIndex, lastChapter: chapterIndex, pathId: pathId))
	}
	
	// A query for the whole history of a specific paragraph instance, from the oldest to the most recent
	func historyQuery(paragraphId: String) -> Query<ParagraphHistoryView>
	{
		return createQuery(withKeys: createKey(paragraphId: paragraphId))
	}
	
	// The backwards or forwards history of a certain paragraph instance
	func historyOfParagraphQuery(paragraphId: String, limit: Int? = nil, goForward: Bool = false) -> Query<ParagraphHistoryView>
	{
		var keys = createKey(paragraphId: paragraphId)
		if goForward
		{
			keys[ParagraphHistoryView.KEY_CREATED] = Key([Paragraph.created(fromId: paragraphId), nil])
		}
		else
		{
			keys[ParagraphHistoryView.KEY_CREATED] = Key([nil, Paragraph.created(fromId: paragraphId)])
		}
		
		var query = createQuery(withKeys: keys)
		query.exclusive = true
		query.limit = limit
		query.descending = !goForward
		
		return query
	}
	
	// A convenience method for running a history query in search of the next paragraph in the history
	func previousParagraphVersion(paragraphId: String) throws -> Paragraph?
	{
		return try historyOfParagraphQuery(paragraphId: paragraphId, limit: 1).firstResultObject()
	}
	
	func nextParagraphVersion(paragraphId: String) throws -> Paragraph?
	{
		return try historyOfParagraphQuery(paragraphId: paragraphId, limit: 1, goForward: true).firstResultObject()
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
	
	func mostRecentId(bookId: String, chapterIndex: Int, pathId: String) throws -> String?
	{
		// Creates the key first
		let keys = [
			ParagraphHistoryView.KEY_BOOK_ID: Key(bookId),
			ParagraphHistoryView.KEY_CHAPTER_INDEX: Key(chapterIndex),
			ParagraphHistoryView.KEY_PATH_ID: Key(pathId),
			ParagraphHistoryView.KEY_CREATED: Key.undefined]
		
		// The most recent id(s) are produced by a reduce query
		let query = createQuery(ofType: .reduce, withKeys: keys)
		
		return try query.firstResultRow()?.value.array?.first?.string
	}
	
	// Finds the id of the most recent version of the paragraph
	func mostRecentId(forParagraphWithId paragraphId: String) throws -> String?
	{
		return try mostRecentId(bookId: Paragraph.bookId(fromId: paragraphId), chapterIndex: Paragraph.chapterIndex(fromId: paragraphId), pathId: Paragraph.pathId(fromId: paragraphId))
	}
	
	// Checks whether the specified range contains any conflicts
	func rangeContainsConflicts(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) throws -> Bool
	{
		let query = Query<ParagraphHistoryView>.reduceQuery(groupBy: ParagraphHistoryView.KEY_PATH_ID).withRange(createKey(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter, pathId: nil))
		
		var conflictFound = false
		try query.enumerateResult
		{
			row in
			
			if row.value.array().count > 1
			{
				conflictFound = true
				return false
			}
			else
			{
				return true
			}
		}
		
		return conflictFound
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
	
	// Finds the ids of the conflicting paragraph versions for the specified paragraph path
	// Returns nil if there are no conglicts for the paragraph
	func conflictsForParagraph(withId paragraphId: String) throws -> [String]?
	{
		var query = createQuery(ofType: .reduce, withKeys: createKey(paragraphId: paragraphId))
		query.groupByKey = ParagraphHistoryView.KEY_PATH_ID
		
		if let row = try query.firstResultRow()
		{
			let ids = row.value.array { $0.string }
			if ids.count > 1
			{
				return ids
			}
			else
			{
				return nil
			}
		}
		else
		{
			return nil
		}
	}
	
	func autoCorrectConflictsInRange(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) throws
	{
		let conflicts = try conflictsInRange(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter)
		
		// If there are no conflicts, skips the operation
		guard !conflicts.isEmpty else
		{
			return
		}
		
		// From paragraph id -> to paragraph id
		var deprecateRanges = [(String, String?)]()
		
		for conflictIds in conflicts.values
		{
			let idsWithTimes = conflictIds.map { ($0, Paragraph.created(fromId: $0)) }
			// Only keeps the most recent version
			let mostRecentId = idsWithTimes.max { $0.1 <= $1.1 }!.0
			
			// Deprecates until common ancestor
			let commonAncestorId = try ParagraphHistoryView.instance.commonAncestorOf(paragraphIds: conflictIds)?.idString
			for paragraphId in conflictIds
			{
				if paragraphId != mostRecentId
				{
					deprecateRanges.add((paragraphId, commonAncestorId))
				}
			}
		}
		
		// Performs the actual database updates
		try DATABASE.tryTransaction
		{
			for (fromParagraphId, toParagraphId) in deprecateRanges
			{
				if let toParagraphId = toParagraphId
				{
					try Paragraph.get(fromParagraphId)?.deprecateWithHistory(until: toParagraphId)
				}
				else
				{
					try self.deprecatePath(ofId: fromParagraphId)
				}
			}
		}
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
	
	private func createKey(paragraphId: String) -> [String: Key]
	{
		let id = Paragraph.createId(from: paragraphId)
		let bookId = id[Paragraph.PROPERTY_BOOK_ID].string()
		let chapterIndex = id[Paragraph.PROPERTY_CHAPTER_INDEX].int()
		let pathId = id[Paragraph.PROPERTY_PATH_ID].string()
		
		return createKey(bookId: bookId, firstChapter: chapterIndex, lastChapter: chapterIndex, pathId: pathId)
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
