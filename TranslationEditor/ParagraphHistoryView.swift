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
	}
}
