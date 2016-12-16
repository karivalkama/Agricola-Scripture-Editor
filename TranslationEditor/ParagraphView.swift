//
//  ParagraphView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// The paragraph view is used for querying paragraph data
final class ParagraphView: View
{
	// TYPES	--------
	
	typealias Queried = Paragraph
	typealias MyQuery = Query<ParagraphView>
	
	
	// ATTRIBUTES	----
	
	static let KEY_DEPRECATED = "deprecated"
	static let KEY_MOST_RECENT = "most_recent"
	static let KEY_BOOK_ID = "book_id"
	static let KEY_CHAPTER_INDEX = "chapter_index"
	static let KEY_SECTION_INDEX = "section_index"
	static let KEY_PARAGRAPH_INDEX = "paragraph_index"
	static let KEY_CREATED = "created"
	
	static let keyNames = [KEY_DEPRECATED, KEY_MOST_RECENT, KEY_BOOK_ID, KEY_CHAPTER_INDEX, KEY_SECTION_INDEX, KEY_PARAGRAPH_INDEX, KEY_CREATED]
	
	static let instance = ParagraphView()
	
	let view: CBLView
	
	
	// INIT	------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraphs")
		view.setMapBlock(createMapBlock
		{
			(paragraph, emit) in
			
			// Key = is deprecated + is latest version + bookid + chapter index + section index + paragraph index + created
			let key = [paragraph.isDeprecated, paragraph.isMostRecent, paragraph.bookId, paragraph.chapterIndex, paragraph.sectionIndex, paragraph.index, paragraph.created] as [Any]
			
			emit(key, nil)
			
		}, reduce: countRowsReduce, version: "3")
	}
	
	
	// OTHER METHODS	--
	
	// Finds the latest paragraphs in a certain chapter
	func latestParagraphQuery(bookId: String, chapterIndex: Int) -> MyQuery
	{
		return latestParagraphQuery(bookId: bookId, firstChapter: chapterIndex, lastChapter: chapterIndex)
	}
	
	// Finds the latest paragraphs in a certain chapter range
	func latestParagraphQuery(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) -> MyQuery
	{
		let keys = [
			ParagraphView.KEY_DEPRECATED : Key(false),
			ParagraphView.KEY_MOST_RECENT : Key(true),
			ParagraphView.KEY_BOOK_ID : Key(bookId),
			ParagraphView.KEY_CHAPTER_INDEX : Key(min: firstChapter, max: lastChapter)
		]
		return MyQuery(range: keys)
	}
	
	// Finds the paragraph(s) at the provided index. Only non-deprecated latest versions are included
	func paragraphIndexQuery(bookId: String, chapterIndex: Int, sectionIndex: Int, paragraphIndex: Int) -> MyQuery
	{
		let keys = [
			ParagraphView.KEY_DEPRECATED : Key(false),
			ParagraphView.KEY_MOST_RECENT : Key(true),
			ParagraphView.KEY_BOOK_ID : Key(bookId),
			ParagraphView.KEY_CHAPTER_INDEX : Key(chapterIndex),
			ParagraphView.KEY_SECTION_INDEX : Key(sectionIndex),
			ParagraphView.KEY_PARAGRAPH_INDEX : Key(paragraphIndex)
		]
		
		return MyQuery(range: keys)
	}
	
	// Checks whether the provided range contains at least a single conflict
	func hasConflictsInRange(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) throws -> Bool
	{
		var conflictFound = false
		try enumerateConflictsInRange(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter)
		{
			_ in
			
			conflictFound = true
			return false
		}
		
		return conflictFound
	}
	
	// Finds all conflicting paragraphs in the provided range
	// The mutually exclusive paragraphs are within a single array
	func conflictsInRange(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) throws -> [[Paragraph]]
	{
		var conflicts = [[Paragraph]]()
		// Goes through each conflict row
		try enumerateConflictsInRange(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter)
		{
			row in
			
			let bookId = row[ParagraphView.KEY_BOOK_ID].string()
			let chapterIndex = row[ParagraphView.KEY_CHAPTER_INDEX].int()
			let sectionIndex = row[ParagraphView.KEY_SECTION_INDEX].int()
			let paragraphIndex = row[ParagraphView.KEY_PARAGRAPH_INDEX].int()
			
			// Finds the paragraphs for those indices
			let paragraphsAtIndex = try paragraphIndexQuery(bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, paragraphIndex: paragraphIndex).resultObjects()
			if paragraphsAtIndex.count > 1
			{
				conflicts.append(paragraphsAtIndex)
			}
			
			return true
		}
		
		return conflicts
	}
	
	// Calls the enumerator on each conflicting (multiple current paragraphs for the same index) row in range
	// If the enumerator returns false, the process is stopped
	func enumerateConflictsInRange(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil, using enumerator: (Row<ParagraphView>) throws -> (Bool)) throws
	{
		var reduceQuery = latestParagraphQuery(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter).asQueryOfType(QueryType.reduce)
		reduceQuery.groupByKey = ParagraphView.KEY_PARAGRAPH_INDEX
		
		try reduceQuery.enumerateResult
		{
			row in
			
			// Finds all rows that have a conflict (more than 1 option for index)
			if row.value.int() > 1
			{
				return try enumerator(row)
			}
			
			return true
		}
	}
}
