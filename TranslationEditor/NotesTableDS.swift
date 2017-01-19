//
//  NotesTableDS.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 19.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate struct IndexStatus
{
	let rowCount: Int
	// Path id -> first cell index (inclusive), last cell index (exclusive)
	let pathIndex: [String : (Int, Int)]
	
	// Each note in order of the path ids
	let orderedNotes: [ParagraphNotes]
	// A row index matching each note
	let noteStartIndices: [Int]
}

class NotesTableDS: NSObject
{
	// ATTRIBUTES	---------
	
	private static let NOTE_CELL_ID = "NoteCell"
	private static let THREAD_CELL_ID = "ThreadCell"
	private static let POST_CELL_ID = "PostCell"
	
	// Path ids, ordered
	private var pathIds = [String]()
	
	// Path id -> Note
	private var notes = [String : ParagraphNotes]()
	// Note id -> Threads
	private var threads = [String : [NotesThread]]()
	// Thread if -> posts
	private var posts = [String : [NotesPost]]()
	
	// Instance id -> Custom visibility state
	private var visibleState = [String : Bool]()
	
	private var indexStatus = IndexStatus(rowCount: 0, pathIndex: [:], orderedNotes: [], noteStartIndices: [])
	
	
	// OTHER METHDODS	-----
	
	// This method should be called each time the displayed paragraphs change
	// The notes will be ordered based on this path data
	func updateDisplayPaths(pathIds: [String])
	{
		if self.pathIds != pathIds
		{
			self.pathIds = pathIds
			updateIndexStatus()
		}
	}
	
	// Finds the IndexPaths that match the provided path id
	func indexesForPath(_ pathId: String) -> [IndexPath]
	{
		if let (startIndex, endIndex) = indexStatus.pathIndex[pathId]
		{
			return [Int](startIndex ..< endIndex).map { IndexPath(row: $0, section: 0) }
		}
		else
		{
			return []
		}
	}
	
	private func shouldDisplayPostsForThread(_ thread: NotesThread) -> Bool
	{
		// If there is a custom visibility state, uses that. 
		// Otherwise only displays threads that are not resolved
		return visibleState[thread.idString].or(!thread.isResolved)
	}
	
	private func shouldDisplayThreadsForNote(withId noteId: String) -> Bool
	{
		// If threre is a custom visibility state, uses that.
		// Otherwise only displays notes that contain unresolved threads
		return visibleState[noteId].or(threads[noteId].or([]).contains { !$0.isResolved })
	}
	
	private func cellsForThread(_ thread: NotesThread) -> Int
	{
		// If the thread is displayed, the posts are counted, 
		// otherwise only the thread itself counts
		if shouldDisplayPostsForThread(thread)
		{
			return 1 + (posts[thread.idString]?.count).or(0)
		}
		else
		{
			return 1
		}
	}
	
	private func cellsForNote(withId noteId: String) -> Int
	{
		// If the note contents are displayed, counts the number of cells displayed for each thread
		if shouldDisplayThreadsForNote(withId: noteId)
		{
			return threads[noteId].or([]).reduce(1, { $0 + cellsForThread($1) })
		}
		// Otherwise only displays the note itself
		else
		{
			return 1
		}
	}
	
	// Updates the basic indexing information
	// This method should be called each time the contents of the table change
	private func updateIndexStatus()
	{
		var orderedNotes = [ParagraphNotes]()
		var noteStartIndices = [Int]()
		
		var pathIndex = [String : (Int, Int)]()
		
		var index = 0
		for pathId in pathIds
		{
			if let note = notes[pathId]
			{
				orderedNotes.append(note)
				noteStartIndices.append(index)
				
				let nextIndex = index + cellsForNote(withId: note.idString)
				
				pathIndex[pathId] = (index, nextIndex)
				index = nextIndex
			}
		}
		
		indexStatus = IndexStatus(rowCount: index, pathIndex: pathIndex, orderedNotes: orderedNotes, noteStartIndices: noteStartIndices)
	}
}
