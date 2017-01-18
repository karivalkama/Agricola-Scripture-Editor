//
//  NotesPostView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class NotesPostView: View
{
	// TYPES	-----------
	
	typealias Queried = NotesPost
	typealias MyQuery = Query<NotesPostView>
	
	
	// ATTRIBUTES	-------
	
	static let KEY_COLLECTION = "collection"
	static let KEY_CHAPTER = "chapter"
	static let KEY_THREAD_CREATED = "thread_created"
	static let KEY_CREATED = "created"
	
	static let instance = NotesPostView()
	static let keyNames = [KEY_COLLECTION, KEY_CHAPTER, KEY_THREAD_CREATED, KEY_CREATED]
	
	let view: CBLView
	
	
	// INIT	---------------
	
	private init()
	{
		view = DATABASE.viewNamed("notes_post_view")
		view.setMapBlock(createMapBlock
		{
			post, emit in
			
			// Key = collection id + chapter index + thread created + created
			let key: [Any] = [post.collectionId, post.chapterIndex, post.threadCreated, post.created]
			emit(key, nil)
		
		}, reduce: countRowsReduce, version: "1")
	}
	
	
	// OTHER METHODS	----
	
	func postsQuery(collectionId: String, minChapter: Int? = nil, maxChapter: Int? = nil) -> MyQuery
	{
		let keys = [
			NotesPostView.KEY_COLLECTION: Key(collectionId),
			NotesPostView.KEY_CHAPTER: Key([minChapter, maxChapter]),
			NotesPostView.KEY_THREAD_CREATED: Key.undefined,
			NotesPostView.KEY_CREATED: Key.undefined
		]
		
		return createQuery(withKeys: keys)
	}
	
	func postsForThreadQuery(threadId: String) -> MyQuery
	{
		return createQuery(withKeys: NotesPostView.keysForThread(withId: threadId))
	}
	
	func countPostsForThread(withId threadId: String) throws -> Int
	{
		let count = try createQuery(ofType: .reduce, withKeys: NotesPostView.keysForThread(withId: threadId)).resultRows().first?.value.int
		return count.or(0)
	}
	
	// TODO: Add thead post count query application
	
	static func keysForThread(withId threadId: String) -> [String : Key]
	{
		return [
			KEY_COLLECTION: Key(ParagraphNotes.collectionId(fromId: threadId)),
			KEY_CHAPTER: Key(ParagraphNotes.chapterIndex(fromId: threadId)),
			KEY_THREAD_CREATED: Key(NotesThread.created(fromId: threadId)),
			KEY_CREATED: Key.undefined
		]
	}
}
