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

class NotesTableDS: NSObject, UITableViewDataSource
{
	// ATTRIBUTES	---------
	
	private static let NOTE_CELL_ID = "NoteCell"
	private static let THREAD_CELL_ID = "ThreadCell"
	private static let POST_CELL_ID = "PostCell"
	
	private weak var tableView: UITableView!
	
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
	
	
	// INIT	-----------------
	
	init(tableView: UITableView)
	{
		self.tableView = tableView
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return indexStatus.rowCount
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Finds the note and the desired index within that note
		var note: ParagraphNotes!
		var remainingIndex = 0
		
		for i in 0 ..< indexStatus.noteStartIndices.count
		{
			// Checks if the index is in this note's range
			if indexStatus.noteStartIndices.count >= i + 1 || indexStatus.noteStartIndices[i + 1] > indexPath.row
			{
				note = indexStatus.orderedNotes[i]
				remainingIndex = indexPath.row - indexStatus.noteStartIndices[i]
				
				break
			}
		}
		
		// In case the index is right on the note row, creates a row of that type
		if remainingIndex == 0
		{
			// TODO: Set the cell contents, etc.
			return tableView.dequeueReusableCell(withIdentifier: NotesTableDS.NOTE_CELL_ID)!
		}
		// Otherwise finds the thread that contains the specified index
		else
		{
			remainingIndex -= 1
			
			for thread in threads[note.idString]!
			{
				// In the index is on a specific thread, displays a thread cell
				if remainingIndex == 0
				{
					// TODO: Set the cell contents, etc.
					return tableView.dequeueReusableCell(withIdentifier: NotesTableDS.THREAD_CELL_ID)!
				}
				else
				{
					let threadCellCount = cellsForThread(thread)
					
					// Checks if the displayed cell is within this thread
					if remainingIndex < threadCellCount
					{
						// TODO: Find the correct post (remaining - 1 :th) and set up the cell
						return tableView.dequeueReusableCell(withIdentifier: NotesTableDS.POST_CELL_ID)!
					}
					// Otherwise moves to the next thread
					else
					{
						remainingIndex -= threadCellCount
					}
				}
			}
		}
		
		return UITableViewCell()
	}
	
	
	// OTHER METHDODS	-----
	
	// This method should be called each time the displayed paragraphs change
	// The notes will be ordered based on this path data
	func updateDisplayPaths(pathIds: [String])
	{
		if self.pathIds != pathIds
		{
			self.pathIds = pathIds
			update()
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
	
	// Updates the basic indexing information, as well as the table
	// This method should be called each time the contents of the table change
	private func update()
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
		// Also updates the table contents
		tableView.reloadData()
	}
}
