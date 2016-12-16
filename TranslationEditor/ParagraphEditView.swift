//
//  ParagraphEditView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This view is used for accessing paragraph edit status data
final class ParagraphEditView: View
{
	// TYPES	-------------
	
	typealias Queried = ParagraphEdit
	
	
	// PROPERTIES	---------
	
	static let KEY_USER_ID = "user_id"
	static let KEY_BOOK_ID = "book_id"
	static let KEY_CHAPTER_INDEX = "chapter_index"
	static let KEY_SECTION_INDEX = "section_index"
	static let KEY_PARAGRAPH_INDEX = "paragraph_index"
	static let KEY_CREATED = "created"
	
	static let keyNames = [KEY_USER_ID, KEY_BOOK_ID, KEY_CHAPTER_INDEX, KEY_SECTION_INDEX, KEY_PARAGRAPH_INDEX, KEY_CREATED]
	
	static let instance = ParagraphEditView()
	
	let view: CBLView
	
	
	// INIT	-----------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_edits")
		view.setMapBlock(createMapBlock
		{
			(edit, emit) in
			
			// Key = user id + book id + chapter id + section id + paragraph index + creation millis
			let key = [edit.userId, edit.paragraph.bookId, edit.paragraph.chapterIndex, edit.paragraph.sectionIndex, edit.paragraph.index, edit.created] as [Any]
			
			emit(key, nil)
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	---
	
	// Finds all paragraph edits in certain character range. Ordered.
	func editsForRangeQuery(userId: String? = nil, bookId: String? = nil, firstChapterIndex: Int? = nil, lastChapterIndex: Int? = nil) -> Query<ParagraphEditView>
	{
		let keys = [
			ParagraphEditView.KEY_USER_ID : Key(userId),
			ParagraphEditView.KEY_BOOK_ID : Key(bookId),
			ParagraphEditView.KEY_CHAPTER_INDEX : Key(min: firstChapterIndex, max: lastChapterIndex)
		]
		
		return Query<ParagraphEditView>(range: keys)
	}
}
