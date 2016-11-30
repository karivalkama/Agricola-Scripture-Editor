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
	
	func query(bookId: String?, chapterIndex: Int?, sectionIndex: Int?, paragraphIndex: Int?) -> CBLQuery
	{
		return query(forKeys: [bookId, chapterIndex, sectionIndex, paragraphIndex])
	}
}
