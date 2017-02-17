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

// This listener type is used when one has to implement listening for multiple live queries
fileprivate class UpdateListener<QueryTarget: View>: LiveQueryListener
{
	// TYPES	---------------
	
	typealias Updator = ([QueryTarget.Queried]) -> ()
	
	
	// ATTRIBUTES	-----------
	
	private let updator: Updator
	
	
	// INIT	-------------------
	
	init(using updator: @escaping Updator)
	{
		self.updator = updator
	}
	
	
	// IMPLEMENTED METHODS	---
	
	fileprivate func rowsUpdated(rows: [Row<QueryTarget>])
	{
		do
		{
			try updator(rows.map { try $0.object() })
		}
		catch
		{
			print("ERROR: Failed to read live object data \(error)")
		}
	}
}

// TODO: Remove showlistener protocol
class NotesTableDS: NSObject, UITableViewDataSource, LiveResource, TranslationParagraphListener
{
	// ATTRIBUTES	---------
	
	private weak var tableView: UITableView!
	
	private let resourceCollectionId: String
	
	// Path id -> Note
	private var notes = [String : ParagraphNotes]()
	// Note id -> Threads
	private var threads = [String : [NotesThread]]()
	// Thread if -> posts
	private var posts = [String : [NotesPost]]()
	
	// Path ids, ordered
	private var pathIds = [String]()
	// Path id -> Paragraph name
	private var paragraphNames = [String : String]()
	
	// Instance id -> Custom visibility state
	private var threadVisibleState = [String : Bool]()
	
	private var indexStatus = IndexStatus(rowCount: 0, pathIndex: [:], orderedNotes: [], noteStartIndices: [])
	
	// Path id -> path contains unresolved threads
	private var pathStatus = [String: Bool]()
	
	private let notesQueryManager: LiveQueryManager<ParagraphNotesView>
	private let threadQueryManager: LiveQueryManager<NotesThreadView>
	private let postQueryManager: LiveQueryManager<NotesPostView>
	
	private var isActive = false
	
	private weak var openThreadListener: OpenThreadListener?
	
	
	// INIT	-----------------
	
	// TODO: Add chapter parameters after translation range is used
	init(tableView: UITableView, resourceCollectionId: String, threadListener: OpenThreadListener?)
	{
		self.resourceCollectionId = resourceCollectionId
		self.tableView = tableView
		self.openThreadListener = threadListener
		
		notesQueryManager = ParagraphNotesView.instance.notesQuery(collectionId: resourceCollectionId).liveQueryManager
		threadQueryManager = NotesThreadView.instance.threadQuery(collectionId: resourceCollectionId).liveQueryManager
		postQueryManager = NotesPostView.instance.postsQuery(collectionId: resourceCollectionId).liveQueryManager
		
		super.init()
		
		notesQueryManager.addListener(AnyLiveQueryListener(UpdateListener
		{
			notes in
			
			print("STATUS: Received input of \(notes.count) notes")
			self.notes = notes.toDictionary { ($0.pathId, $0) }
			self.update()
		}))
		
		threadQueryManager.addListener(AnyLiveQueryListener(UpdateListener
		{
			threads in
			
			print("STATUS: Received input of \(threads.count) threads")
			
			// Whenever a thread's resolved state changes, resets the custom visibility state for that thread
			for thread in threads
			{
				if let previousVersion = self.threads[thread.noteId]?.first(where: { oldThread in oldThread.idString == thread.idString })
				{
					if previousVersion.isResolved != thread.isResolved
					{
						self.threadVisibleState[thread.idString] = nil
					}
				}
			}
			
			self.threads = threads.toArrayDictionary { ($0.noteId, $0) }
			self.update()
		}))
		
		postQueryManager.addListener(AnyLiveQueryListener(UpdateListener
		{
			posts in
			
			print("STATUS: Received input of \(posts.count) posts")
			self.posts = posts.toArrayDictionary { ($0.threadId, $0) }
			self.update()
		}))
		
		// Starts the thread queries right away in order to update the paragraph flags
		// TODO: Should probably pause thread listening while the app is not active (may be implemented as a common feature for all listeners)
		notesQueryManager.start()
		threadQueryManager.start()
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
			if indexStatus.noteStartIndices.count <= i + 1 || indexStatus.noteStartIndices[i + 1] > indexPath.row
			{
				note = indexStatus.orderedNotes[i]
				remainingIndex = indexPath.row - indexStatus.noteStartIndices[i]
				
				break
			}
		}
		
		// In case the index is right on the note row, creates a row of that type
		if remainingIndex == 0
		{
			var cell: NotesCell! = tableView.dequeueReusableCell(withIdentifier: NotesCell.identifier, for: indexPath) as? NotesCell
			if cell == nil
			{
				cell = NotesCell()
			}
			
			cell.setContent(note: note, name: paragraphNames[note.pathId].or(""))
			
			return cell
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
					var cell: ThreadCell! = tableView.dequeueReusableCell(withIdentifier: ThreadCell.identifier, for: indexPath) as? ThreadCell
					if cell == nil
					{
						cell = ThreadCell()
					}
					
					cell.setContent(thread: thread, pathId: note.pathId, showsPosts: shouldDisplayPostsForThread(thread))
					
					return cell
				}
				else
				{
					let threadCellCount = cellsForThread(thread)
					
					// Checks if the displayed cell is within this thread
					if remainingIndex < threadCellCount
					{
						let post = posts[thread.idString]![remainingIndex - 1]
						
						var cell: PostCell! = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as? PostCell
						if cell == nil
						{
							cell = PostCell()
						}
						
						cell.setContent(post: post, pathId: note.pathId, isResolved: thread.isResolved)
						
						return cell
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
	
	// This method should be called each time the displayed paragraphs change
	// The notes will be ordered based on this path data
	func translationParagraphsUpdated(_ paragraphs: [Paragraph])
	{
		let pathIds = paragraphs.map { $0.pathId }
		
		if self.pathIds != pathIds
		{
			self.pathIds = pathIds
			
			// Sets the paragraph names
			for paragraph in paragraphs
			{
				// If the paragraph has a range, uses that
				if let range = paragraph.range
				{
					paragraphNames[paragraph.pathId] = "\(paragraph.chapterIndex): \(range.simpleName)"
				}
				// If the paragraph contains a section heading, tells that
				else if (paragraph.content.first?.style.isSectionHeadingStyle()).or(false)
				{
					let headingText = paragraph.text
					paragraphNames[paragraph.pathId] = "\(paragraph.chapterIndex) - \(headingText.isEmpty ? "Heading" : headingText)"
				}
				else
				{
					paragraphNames[paragraph.pathId] = "\(paragraph.chapterIndex) - ..."
				}
			}
			
			update()
		}
	}

	
	
	// OTHER METHDODS	-----
	
	/*
	func setThreadVisibility(thread: NotesThread, visibility: Bool)
	{
		if threadVisibleState[thread.idString] != visibility
		{
			threadVisibleState[thread.idString] = visibility
			update()
		}
	}*/
	
	// If thread contents were visible, hides them. If they were hidden, displays them
	func changeThreadVisibility(thread: NotesThread)
	{
		threadVisibleState[thread.idString] = !shouldDisplayPostsForThread(thread)
		update()
	}
	
	func activate()
	{
		isActive = true
		postQueryManager.start()
	}
	
	func pause()
	{
		isActive = false
		postQueryManager.pause()
		// Thread listening contiues while other resources may be paused
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
				
				// Updates the path status as well
				// (checks which path ids contain open threads)
				pathStatus[pathId] = (threads[note.idString]?.contains(where: { !$0.isResolved })).or(false)
			}
		}
		
		indexStatus = IndexStatus(rowCount: index, pathIndex: pathIndex, orderedNotes: orderedNotes, noteStartIndices: noteStartIndices)
		
		// Informs the thread listener about the new status
		openThreadListener?.onThreadStatusUpdated(forResouceId: self.resourceCollectionId, status: pathStatus)
		
		// Also updates the table contents (if currently in charge of that)
		if isActive
		{
			tableView.reloadData()
		}
	}
	
	private func shouldDisplayPostsForThread(_ thread: NotesThread) -> Bool
	{
		// If there is a custom visibility state, uses that. 
		// Otherwise only displays threads that are not resolved
		return threadVisibleState[thread.idString].or(!thread.isResolved)
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
		// Counts the number of cells displayed for each thread
		return threads[noteId].or([]).reduce(1, { $0 + cellsForThread($1) })
	}
}
