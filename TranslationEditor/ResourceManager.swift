//
//  ResourceManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate struct BookResourceData
{
	let resource: ResourceCollection
	let binding: ParagraphBinding
	let datasource: TranslationTableViewDS
}

fileprivate struct NotesData
{
	let resource: ResourceCollection
	let datasource: NotesTableDS
}

// TODO: Terminate resource listening once done

// This class handles the functions concerning the resource table
class ResourceManager: TranslationParagraphListener, TableCellSelectionListener, LiveQueryListener
{
	// TYPES	---------------
	
	typealias QueryTarget = ResourceCollectionView
	
	
	// ATTRIBUTES	-----------
	
	private weak var resourceTableView: UITableView!
	private weak var addNotesDelegate: AddNotesDelegate!
	private weak var threadStatusListener: OpenThreadListener?
	private weak var updateListener: ResourceUpdateListener?
	
	private let targetBookId: String
	
	private var allSourceBooks = [BookResourceData]()
	private var allNotes = [NotesData]()
	private var carousel: Carousel?
	
	private var displayedSourceBooks = [BookResourceData]()
	private var displayedNotes = [NotesData]()
	
	private var currentLiveResource: LiveResource?
	private var currentResourceIndex: Int?
	
	private var queryManager: LiveQueryManager<QueryTarget>!
	
	
	// COMPUTED PROPERTIES	---
	
	let targetedCellIds = [NotesCell.identifier, ThreadCell.identifier, PostCell.identifier]
	
	var resourceTitles: [String]
	{
		return displayedSourceBooks.map { $0.resource.name } + displayedNotes.map { $0.resource.name }
	}
	
	// Currently selected book data, if one is selected
	private var currentSourceBookData: BookResourceData?
	{
		if let currentResourceIndex = currentResourceIndex, currentResourceIndex < displayedSourceBooks.count
		{
			return displayedSourceBooks[currentResourceIndex]
		}
		else
		{
			return nil
		}
	}
	
	// Currently selected notes data, if one is selected
	private var currentNotesData: NotesData?
	{
		if let currentResourceIndex = currentResourceIndex, currentResourceIndex >= displayedSourceBooks.count
		{
			return displayedNotes[currentResourceIndex - displayedSourceBooks.count]
		}
		else
		{
			return nil
		}
	}
	
	
	// INIT	-------------------
	
	init(resourceTableView: UITableView, targetBookId: String, addNotesDelegate: AddNotesDelegate, threadStatusListener: OpenThreadListener?, updateListener: ResourceUpdateListener?)
	{
		self.targetBookId = targetBookId
		self.updateListener = updateListener
		self.resourceTableView = resourceTableView
		self.addNotesDelegate = addNotesDelegate
		self.threadStatusListener = threadStatusListener
		
		if let avatarId = Session.instance.avatarId
		{
			do
			{
				self.carousel = try Carousel.get(avatarId: avatarId, bookCode: Book.code(fromId: targetBookId))
			}
			catch
			{
				print("ERROR: Failed to read user carousel data. \(error)")
			}
		}
		
		queryManager = ResourceCollectionView.instance.collectionQuery(bookId: targetBookId).liveQueryManager
		queryManager.addListener(AnyLiveQueryListener(self))
		queryManager.start()
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func rowsUpdated(rows: [Row<ResourceCollectionView>])
	{
		// Deactivates the old resources
		// TODO: One might completely remove the data here
		allSourceBooks.forEach { $0.datasource.pause() }
		allNotes.forEach { $0.datasource.pause() }
		
		do
		{
			let resources = try rows.map { try $0.object() }
			let bookResources = resources.filter { $0.category == .sourceTranslation }
			let notesResources = resources.filter { $0.category == .notes }
			
			try allSourceBooks = bookResources.flatMap
			{
				resource in
				
				if let binding = try ParagraphBinding.get(resourceCollectionId: resource.idString)
				{
					return BookResourceData(resource: resource, binding: binding, datasource: TranslationTableViewDS(tableView: resourceTableView!, bookId: binding.sourceBookId, configureCell: configureSourceCell))
				}
				else
				{
					return nil
				}
			}
			
			allNotes = notesResources.map { NotesData(resource: $0, datasource: NotesTableDS(tableView: resourceTableView!, resourceCollectionId: $0.idString, threadListener: self.threadStatusListener)) }
		}
		catch
		{
			print("ERROR: Failed to update resource data. \(error)")
		}
		
		print("STATUS: Updating resources. Found \(allSourceBooks.count) source books and \(allNotes.count) notes")
		updateDisplayedResources()
	}
	
	// This method should be called whenever the paragraph data on the translation side is updated
	// Makes sure right notes resources are displayed
	func translationParagraphsUpdated(_ paragraphs: [Paragraph])
	{
		for noteData in displayedNotes
		{
			noteData.datasource.translationParagraphsUpdated(paragraphs)
		}
	}
	
	func onTableCellSelected(_ cell: UITableViewCell, identifier: String)
	{
		// When a paragraph-notes -cell is selected, adds a new thread
		if identifier == NotesCell.identifier, let cell = cell as? NotesCell
		{
			addNotesDelegate.insertThread(noteId: cell.note.idString, pathId: cell.note.pathId, associatedParagraphData: collectAssociatedParagraphData(pathId: cell.note.pathId, chapterIndex: cell.note.chapterIndex))
		}
		// When a thread cell is selected, hides / shows the thread contents
		else if identifier == ThreadCell.identifier, let cell = cell as? ThreadCell
		{
			currentNotesData?.datasource.changeThreadVisibility(thread: cell.thread)
		}
		// When a post is tapped, creates a response to that post
		else if identifier == PostCell.identifier, let cell = cell as? PostCell
		{
			do
			{
				guard let targetThread = try NotesThread.get(cell.post.threadId), let pathId = cell.pathId else
				{
					print("ERROR: Could not find requred associated data for new comment")
					return
				}
				
				addNotesDelegate.insertPost(thread: targetThread, selectedComment: cell.post, associatedParagraphData: collectAssociatedParagraphData(pathId: pathId, chapterIndex: targetThread.chapterIndex))
			}
			catch
			{
				print("ERROR: Failed to read a target thread for the new comment. \(error)")
			}
		}
	}
	
	
	// OTHER METHODS	-------
	
	func indexPathsForTargetPathId(_ targetPathId: String) -> [IndexPath]
	{
		// Uses bindings to find source index paths from book data
		if let currentSourceBookData = currentSourceBookData
		{
			return currentSourceBookData.binding.sourcesForTarget(targetPathId).flatMap { currentSourceBookData.datasource.indexForPath($0) }
		}
		// Notes table data sources keep track of path indices
		else if let currentNotesData = currentNotesData
		{
			return currentNotesData.datasource.indexesForPath(targetPathId)
		}
		else
		{
			return []
		}
	}
	
	func targetPathsForSourcePath(_ sourcePathId: String) -> [String]
	{
		// In source translation data, bindings are used for path to path connections
		if let currentSourceBookData = currentSourceBookData
		{
			return currentSourceBookData.binding.targetsForSource(sourcePathId)
		}
		// Other data is already using the same path ids
		else
		{
			return [sourcePathId]
		}
	}
	
	func selectResource(atIndex index: Int)
	{
		guard index != currentResourceIndex else
		{
			return
		}
		
		guard index >= 0 && index < displayedSourceBooks.count + displayedNotes.count else
		{
			print("ERROR: Trying to activate a resource at non-existing index")
			return
		}
		
		// Stops the listening for the current resource
		currentLiveResource?.pause()
		
		// Finds the new resource and activates it
		if index < displayedSourceBooks.count
		{
			let datasource = displayedSourceBooks[index].datasource
			currentLiveResource = datasource
			resourceTableView.dataSource = datasource
		}
		else
		{
			let datasource = displayedNotes[index - displayedSourceBooks.count].datasource
			currentLiveResource = datasource
			resourceTableView.dataSource = datasource
		}
		
		currentResourceIndex = index
		currentLiveResource?.activate()
		
		resourceTableView.reloadData()
	}
	
	// Retrieves the index of a resource (collection) with the specified id
	func indexForResource(withId resourceId: String) -> Int?
	{
		return displayedSourceBooks.index(where: { $0.resource.idString == resourceId }) ?? displayedNotes.index(where: { $0.resource.idString == resourceId }).map { $0 + displayedSourceBooks.count }
	}
	
	func pause()
	{
		currentLiveResource?.pause()
		queryManager.pause()
	}
	
	func activate()
	{
		currentLiveResource?.activate()
		queryManager.start()
	}
	
	func updateCarousel()
	{
		if let avatarId = Session.instance.avatarId
		{
			do
			{
				carousel = try Carousel.get(avatarId: avatarId, bookCode: Book.code(fromId: targetBookId))
				updateDisplayedResources()
			}
			catch
			{
				print("Failed to read carousel data. \(error)")
			}
		}
	}
	
	private func updateDisplayedResources()
	{
		if let carousel = carousel
		{
			displayedSourceBooks = carousel.resourceIds.flatMap { id in self.allSourceBooks.first(where: { $0.resource.idString == id }) }
			displayedNotes = carousel.resourceIds.flatMap { id in self.allNotes.first(where: { $0.resource.idString == id }) }
		}
		else
		{
			displayedSourceBooks = allSourceBooks
			displayedNotes = allNotes
		}
		
		selectResource(atIndex: 0)
		updateListener?.onResourcesUpdated(optionLabels: resourceTitles)
	}
	
	private func configureSourceCell(tableView: UITableView, indexPath: IndexPath, paragraph: Paragraph) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: SourceTranslationCell.identifier, for: indexPath) as! SourceTranslationCell
		cell.configure(paragraph: paragraph)
		
		return cell
	}
	
	// Finds the associated paragraphs from the resource data
	private func collectAssociatedParagraphData(pathId: String, chapterIndex: Int) -> [(String, Paragraph)]
	{
		var data = [(String, Paragraph)]()
		
		do
		{
			for bookData in displayedSourceBooks
			{
				let sourcePathIds = bookData.binding.sourcesForTarget(pathId)
				
				if !sourcePathIds.isEmpty//, let languageName = try Language.get(bookData.resource.languageId)?.name
				{
					for i in 0 ..< sourcePathIds.count
					{
						if let paragraphId = try ParagraphHistoryView.instance.mostRecentId(bookId: bookData.binding.sourceBookId, chapterIndex: chapterIndex, pathId: sourcePathIds[i]), let paragraph = try Paragraph.get(paragraphId)
						{
							let title = bookData.resource.name + (sourcePathIds.count == 1 ? ":" : " (\(i + 1)):")
							data.append((title, paragraph))
						}
						else
						{
							print("ERROR: Failed to find the latest version of associated paragraph in \(bookData.resource.name) with path: \(sourcePathIds[i])")
						}
					}
				}
			}
		}
		catch
		{
			print("ERROR: Failed to prepare associated paragraph data. \(error)")
		}
		
		return data
	}
}
