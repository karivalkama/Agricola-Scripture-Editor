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
	
	// Creates a query that can be used for retrieving paragraph edit data
	func createQuery(userId: String?, bookId: String?, chapterIndex: Int?, sectionIndex: Int?, paragraphIndex: Int?, created: Double? = nil, descending: Bool = false) -> CBLQuery
	{
		return createQuery(forKeys: [Key(userId), Key(bookId), Key(chapterIndex), Key(paragraphIndex), Key(created)], descending: descending)
	}
}
