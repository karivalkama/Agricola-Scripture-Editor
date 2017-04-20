//
//  ParagraphNotesView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class ParagraphNotesView: View
{
	// TYPES	-------------
	
	typealias Queried = ParagraphNotes
	
	
	// ATTRIBUTES	---------
	
	static let KEY_COLLECTION = "collection"
	static let KEY_CHAPTER = "chapter"
	static let KEY_PATH = "path_id"
	
	static let keyNames = [KEY_COLLECTION, KEY_CHAPTER, KEY_PATH]
	static let instance = ParagraphNotesView()
	
	let view: CBLView
	
	
	// INIT	-----------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_notes_view")
		view.setMapBlock(createMapBlock
		{
			notes, emit in
			
			// Key = collectionId + chapter index + path id
			let key: [Any] = [notes.collectionId, notes.chapterIndex, notes.pathId]
			emit(key, nil)
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	---
	
	func notesQuery(collectionId: String, minChapter: Int? = nil, maxChapter: Int? = nil) -> Query<ParagraphNotesView>
	{
		let keys = [
			ParagraphNotesView.KEY_COLLECTION: Key(collectionId),
			ParagraphNotesView.KEY_CHAPTER: Key([minChapter, maxChapter]),
			ParagraphNotesView.KEY_PATH: Key.undefined
		]
		
		return createQuery(withKeys: keys)
	}
	
	// Finds the paragraph notes instances for the provided paragraph
	func notesForParagraph(collectionId: String, chapterIndex: Int, pathId: String) throws -> [ParagraphNotes]
	{
		let keys = ParagraphNotesView.makeKeys(from: [collectionId, chapterIndex, pathId])
		return try createQuery(withKeys: keys).resultObjects()
	}
}
