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
	
	func conflictsInChapter(bookId: String, chapterIndex: Int) throws -> [String : [String]]
	{
		let query = Query<ParagraphHistoryView>.reduceQuery(groupBy: ParagraphHistoryView.KEY_PATH_ID).withRange(createKey(bookId: bookId, chapterIndex: chapterIndex, pathId: nil))
		
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
	
	private func createKey(bookId: String?, chapterIndex: Int?, pathId: String?) -> [String : Key]
	{
		return [
			ParagraphHistoryView.KEY_BOOK_ID : Key(bookId),
			ParagraphHistoryView.KEY_CHAPTER_INDEX : Key(chapterIndex),
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
