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
			
		}, reduce:
		{
			(_, values, rereduce) in
			
			// Simply counts the rows
			if rereduce
			{
				if let values = values as? [Int]
				{
					var total = 0
					values.forEach { total += $0 }
					return total
				}
				else
				{
					return 0
				}
			}
			else
			{
				return values.count
			}
			
		}, version: "3")
	}
	
	
	// OTHER METHODS	--
	
	func latestParagraphQuery(bookId: String, chapterIndex: Int) -> CBLQuery
	{
		return latestParagraphQuery(bookId: bookId, firstChapter: chapterIndex, lastChapter: chapterIndex)
	}
	
	func latestParagraphQuery(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) -> CBLQuery
	{
		// Deprecated = false, latest version = true
		// Section index, paragraph index and created unspecified
		return createQuery(forKeys: [Key(false), Key(true), Key(bookId), Key(min: firstChapter, max: lastChapter), nil, nil, nil])
	}
	
	func conflictsInRange(bookId: String, firstChapter: Int? = nil, lastChapter: Int? = nil) throws -> [[Paragraph]]
	{
		let query = latestParagraphQuery(bookId: bookId, firstChapter: firstChapter, lastChapter: lastChapter)
		
		// Uses reduce & grouping to find row amount for each paragraph index
		query.mapOnly = false
		query.prefetch = false
		query.groupLevel = 6
		
		var conflicts = [[Paragraph]]()
		let results = try query.run()
		while let row = results.nextRow()
		{
			// A conflict is a index with more than one option for the latest paragraph
			if row.value as! Int > 1
			{
				let bookId = row.key(at: 2)!
				let chapterIndex = row.key(at: 3)!
				let sectionIndex = row.key(at: 4)!
				let paragraphIndex = row.key(at: 5)!
				
				// Retrieves the conflicting paragraphs from the database
				let conflictQuery = createQuery(forKeys: [Key(false), Key(true), Key(bookId), Key(chapterIndex), Key(sectionIndex), Key(paragraphIndex), nil])
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
