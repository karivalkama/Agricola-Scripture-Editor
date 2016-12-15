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
	
	func latestParagraphQuery(bookId: String, chapterIndex: Int) -> CBLQuery
	{
		return latestParagraphQuery(bookId: bookId, firstChapter: chapterIndex, lastChapter: chapterIndex)
	}
	
	func latestParagraphQuery(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) -> CBLQuery
	{
		let keys = [
			ParagraphView.KEY_DEPRECATED : Key(false),
			ParagraphView.KEY_MOST_RECENT : Key(true),
			ParagraphView.KEY_BOOK_ID : Key(bookId),
			ParagraphView.KEY_CHAPTER_INDEX : Key(min: firstChapter, max: lastChapter)
		]
		return createQuery(forKeys: keys)
	}
	
	func paragraphIndexQuery(bookId: String, chapterIndex: Int, sectionIndex: Int, paragraphIndex: Int) -> CBLQuery
	{
		let keys = [
			ParagraphView.KEY_DEPRECATED : Key(false),
			ParagraphView.KEY_MOST_RECENT : Key(true),
			ParagraphView.KEY_BOOK_ID : Key(bookId),
			ParagraphView.KEY_CHAPTER_INDEX : Key(chapterIndex),
			ParagraphView.KEY_SECTION_INDEX : Key(sectionIndex),
			ParagraphView.KEY_PARAGRAPH_INDEX : Key(paragraphIndex)
		]
		
		return createQuery(forKeys: keys)
	}
	
	func conflictsInRange(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) throws -> [[Paragraph]]
	{
		let query = latestParagraphQuery(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter)
		
		// Uses reduce & grouping to find row amount for each paragraph index
		query.mapOnly = false
		query.prefetch = false
		query.groupLevel = ParagraphView.groupLevel(for: ParagraphView.KEY_PARAGRAPH_INDEX)!
		
		var conflicts = [[Paragraph]]()
		let results = try query.run()
		while let row = results.nextRow()
		{
			// A conflict is a index with more than one option for the latest paragraph
			if row.value as! Int > 1
			{
				let bookId = row.key(at: 2) as! String
				let chapterIndex = row.key(at: 3) as! Int
				let sectionIndex = row.key(at: 4) as! Int
				let paragraphIndex = row.key(at: 5) as! Int
				
				// Retrieves the conflicting paragraphs from the database
				let conflictQuery = paragraphIndexQuery(bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, paragraphIndex: paragraphIndex)
				let paragraphs = try Paragraph.arrayFromQuery(conflictQuery)
				if paragraphs.count > 1
				{
					conflicts.append(paragraphs)
				}
			}
		}
		
		return conflicts
	}
}
