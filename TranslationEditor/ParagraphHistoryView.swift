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
	
	static let KEY_PARAGRAPH_ID = "paragraph_id"
	static let KEY_DEPRECATED = "deprecated"
	
	static let keyNames = [KEY_PARAGRAPH_ID, KEY_DEPRECATED]
	
	static let instance = ParagraphHistoryView()
	
	let view: CBLView
	
	
	// INIT	----------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_history")
		
		view.setMapBlock(createMapBlock
		{
			paragraph, emit in
			
			// Key = Previous paragraph id + deprecated
			if let lastVersionId = paragraph.createdFrom
			{
				let key = [lastVersionId, paragraph.isDeprecated] as [Any]
				emit(key, nil)
			}
			
		}, reduce: countRowsReduce, version: "1")
	}
	
	
	// OTHER METHODS	---
	
	// Creates a query that will search for the next version(s) of a paragraph
	// If includeDeprecated is set to true, also returns possible deprecated versions
	func nextVersionQuery(paragraphId: String, includeDeprecated: Bool = false) -> CBLQuery
	{
		var keys = [ParagraphHistoryView.KEY_PARAGRAPH_ID : Key(paragraphId)]
		if !includeDeprecated
		{
			keys[ParagraphHistoryView.KEY_DEPRECATED] = Key(false)
		}
		
		return createQuery(forKeys: keys)
	}
	
	func nextVersionIds(paragraphId: String, includeDeprecated: Bool = false) throws -> [String]
	{
		let query = nextVersionQuery(paragraphId: paragraphId, includeDeprecated: includeDeprecated)
		query.prefetch = false
		
		return []
	}
}
