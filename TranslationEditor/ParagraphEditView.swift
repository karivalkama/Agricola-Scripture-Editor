//
//  ParagraphEditView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This view is used for accessing paragraph edit status data
final class ParagraphEditView: View
{
	// TYPES	-------------
	
	typealias Queried = ParagraphEdit
	
	
	// PROPERTIES	---------
	
	static let KEY_BOOK_ID = "book_id"
	static let KEY_CHAPTER_INDEX = "chapter_index"
	static let KEY_USER_ID = "user_id"
	
	static let keyNames = [KEY_BOOK_ID, KEY_USER_ID, KEY_CHAPTER_INDEX]
	
	static let instance = ParagraphEditView()
	
	let view: CBLView
	
	
	// INIT	-----------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_edits")
		view.setMapBlock(createMapBlock
		{
			(edit, emit) in
			
			// Key = book id + user id + chapter id
			let key = [edit.bookId, edit.userId, edit.chapterIndex] as [Any]
			
			emit(key, nil)
			
		}, version: "3")
	}
	
	
	// OTHER METHODS	---
	
	// Finds all paragraph edits in certain character range. Ordered.
	func editsForRangeQuery(bookId: String, userId: String? = nil, firstChapterIndex: Int? = nil, lastChapterIndex: Int? = nil) -> Query<ParagraphEditView>
	{
		let keys = [
			ParagraphEditView.KEY_BOOK_ID : Key(bookId),
			ParagraphEditView.KEY_USER_ID : Key(userId),
			ParagraphEditView.KEY_CHAPTER_INDEX : Key([firstChapterIndex, lastChapterIndex])
		]
		
		return Query<ParagraphEditView>(range: keys)
	}
}
