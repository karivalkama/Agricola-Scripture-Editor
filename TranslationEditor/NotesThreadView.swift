//
//  NotesThreadView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class NotesThreadView: View
{
	// TYPES	-----------
	
	typealias Queried = NotesThread
	
	
	// ATTRIBUTES	-------
	
	static let KEY_COLLECTION = "collection"
	static let KEY_CHAPTER = "chapter"
	static let KEY_NOTE = "note"
	static let KEY_VERSE = "verse"
	static let KEY_CREATED = "created"
	
	static let instance = NotesThreadView()
	static let keyNames = [KEY_COLLECTION, KEY_CHAPTER, KEY_NOTE, KEY_VERSE, KEY_CREATED]
	
	let view: CBLView
	
	
	// INIT	----------------
	
	private init()
	{
		view = DATABASE.viewNamed("notes_thread_view")
		view.setMapBlock(createMapBlock
		{
			thread, emit in
			
			// Key = collection id + chapter index + note uid + created
			let key: [Any] = [thread.collectionId, thread.chapterIndex, ParagraphNotes.uid(fromId: thread.noteId), (thread.targetVerseIndex?.index).or(0), thread.created]
			emit(key, nil)
			
		}, reduce: countRowsReduce, version: "2")
	}
	
	
	// OTHER METHODS	--
	
	func threadQuery(collectionId: String, minChapter: Int? = nil, maxChapter: Int? = nil) -> Query<NotesThreadView>
	{
		let keys = [
			NotesThreadView.KEY_COLLECTION: Key(collectionId),
			NotesThreadView.KEY_CHAPTER: Key([minChapter, maxChapter]),
			NotesThreadView.KEY_NOTE: Key.undefined,
			NotesThreadView.KEY_CREATED: Key.undefined
		]
		
		return createQuery(withKeys: keys)
	}
	
	func threadsForNoteQuery(noteId: String) -> Query<NotesThreadView>
	{
		return createQuery(withKeys: NotesThreadView.keysForNote(withId: noteId))
	}
	
	func countThreadsForNote(withId noteId: String) throws -> Int
	{
		let count = try createQuery(ofType: .reduce, withKeys: NotesThreadView.keysForNote(withId: noteId)).resultRows().first?.value.int
		return count.or(0)
	}
	
	static func keysForNote(withId noteId: String) -> [String : Key]
	{
		return [
			KEY_COLLECTION: Key(ParagraphNotes.collectionId(fromId: noteId)),
			KEY_CHAPTER: Key(ParagraphNotes.chapterIndex(fromId: noteId)),
			KEY_NOTE: Key(ParagraphNotes.uid(fromId: noteId)),
			KEY_CREATED: Key.undefined
		]
	}
}
