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
			
			// Key = Book id + chapter index + section index + paragraph index
			let key = [paragraph.bookId, paragraph.chapterIndex, paragraph.sectionIndex, paragraph.index] as [Any]
			emit(key, nil)
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	--
	
	func createQuery(bookId: String?, chapterIndex: Int?, sectionIndex: Int?, paragraphIndex: Int?) -> CBLQuery
	{
		return createQuery(forKeys: [bookId, chapterIndex, sectionIndex, paragraphIndex])
	}
	
	func getChapterParagraphs(bookId: String, chapterIndex: Int) throws -> [Paragraph]
	{
		let query = createQuery(bookId: bookId, chapterIndex: chapterIndex, sectionIndex: nil, paragraphIndex: nil)
		return try ParagraphView.paragraphsFromQuery(query: query)
	}
	
	static func paragraphsFromQuery(query: CBLQuery) throws -> [Paragraph]
	{
		var paragraphs = [Paragraph]()
		
		let result = try query.run()
		while let rawRow = result.nextRow()
		{
			let paragraphRow = try Row<Paragraph>(rawRow)
			paragraphs.append(paragraphRow.object)
		}
		
		return paragraphs
	}
}
