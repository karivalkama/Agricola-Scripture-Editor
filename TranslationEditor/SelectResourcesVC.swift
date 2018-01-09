//
//  SelectResourcesVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This view controller is used for determining, which resources are available to the user at which time
class SelectResourcesVC: UIViewController, UITableViewDataSource, UITableViewDelegate
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var resourceTableView: UITableView!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "SelectResourcesVC"
	
	var completionHandler: (() -> ())?
	
	private var booksResources = [(resource: ResourceCollection, state: Bool)]()
	private var notesResources = [(resource: ResourceCollection, state: Bool)]()
	// Language id -> language name
	private var languageNames = [String: String]()
	
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		resourceTableView.delegate = self
		resourceTableView.dataSource = self
		resourceTableView.isEditing = true
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		setup()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		booksResources = []
		notesResources = []
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		booksResources = []
		notesResources = []
		languageNames = [:]
	}

	
	// ACTIONS	---------------------
	
	@IBAction func closeButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: completionHandler)
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: completionHandler)
	}
	
	
	// IMPLEMENTED METHODS	--------
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		return 2
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == 0
		{
			return booksResources.count
		}
		else
		{
			return notesResources.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: ResourceSelectionCell.identifier, for: indexPath) as! ResourceSelectionCell
		let (resource, state) = indexPath.section == 0 ? booksResources[indexPath.row] : notesResources[indexPath.row]
		cell.configure(resourceName: resource.name, resourceLanguage: languageNames[resource.languageId] ?? "", resourceState: state, onResourceStateChange: resourceStateChanged)
		
		cell.showsReorderControl = true
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
	{
		return true
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
	{
		if sourceIndexPath.section == 0 && destinationIndexPath.section == 0
		{
			let movedElement = booksResources.remove(at: sourceIndexPath.row)
			booksResources.insert(movedElement, at: destinationIndexPath.row)
		}
		else if sourceIndexPath.section == 1 && destinationIndexPath.section == 1
		{
			let movedElement = notesResources.remove(at: sourceIndexPath.row)
			notesResources.insert(movedElement, at: destinationIndexPath.row)
		}
		
		save()
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if section == 0
		{
			return NSLocalizedString("Books", comment: "A section header for book / source translation resources")
		}
		else
		{
			return NSLocalizedString("Notes", comment: "A section header for notes resource(s)")
		}
	}
	
	func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath
	{
		if sourceIndexPath.section != proposedDestinationIndexPath.section
		{
			var row = 0
			if sourceIndexPath.section < proposedDestinationIndexPath.section
			{
				row = tableView.numberOfRows(inSection: sourceIndexPath.section) - 1
			}
			
			return IndexPath(row: row, section: sourceIndexPath.section)
		}
		else
		{
			return proposedDestinationIndexPath
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
	{
		return UITableViewCellEditingStyle.none
	}

	
	// OTHER METHODS	------------
	
	private func resourceStateChanged(forCell cell: UITableViewCell, newState: Bool)
	{
		guard let indexPath = resourceTableView.indexPath(for: cell) else
		{
			print("ERROR: Can't find indexpath for cell")
			return
		}
		
		if indexPath.section == 0
		{
			booksResources[indexPath.row] = (booksResources[indexPath.row].resource, newState)
		}
		else
		{
			notesResources[indexPath.row] = (notesResources[indexPath.row].resource, newState)
		}
		
		save()
	}
	
	private func setup()
	{
		// Doesn't need to reload resources if they are already loaded
		guard booksResources.isEmpty && notesResources.isEmpty else
		{
			return
		}
		
		guard let avatarId = Session.instance.avatarId, let bookId = Session.instance.bookId else
		{
			print("ERROR: Avatar and book need to be selected before resource customization")
			return
		}
		
		do
		{
			let allResources = try ResourceCollectionView.instance.collectionQuery(bookId: bookId).resultObjects()
			var filteredResources = [(ResourceCollection, Bool)]()
			
			// If there's an existing carousel, uses ordering and states from that one
			if let carousel = try Carousel.get(avatarId: avatarId, bookCode: Book.code(fromId: bookId))
			{
				filteredResources = carousel.resourceIds.flatMap { id in allResources.first(where: { $0.idString == id }).map { ($0, true) } } + allResources.filter { !carousel.resourceIds.contains($0.idString) }.map { ($0, false) }
			}
			else
			{
				// Otherwise enables all resources and uses the default order
				filteredResources = allResources.map { ($0, true) }
			}
			
			booksResources = filteredResources.filter { $0.0.category == ResourceCategory.sourceTranslation }
			notesResources = filteredResources.filter { $0.0.category == ResourceCategory.notes }
			
			// Reads language names to memory too
			for resource in allResources
			{
				if !languageNames.containsKey(resource.languageId)
				{
					if let language = try Language.get(resource.languageId)
					{
						languageNames[resource.languageId] = language.name
					}
				}
			}
		}
		catch
		{
			print("ERROR: Failed to read current resource data. \(error)")
		}
	}
	
	private func save()
	{
		guard let avatarId = Session.instance.avatarId, let bookId = Session.instance.bookId else
		{
			print("ERROR: Can't save changes without avatar and book selected")
			return
		}
		
		do
		{
			try Carousel.push(avatarId: avatarId, bookCode: Book.code(fromId: bookId), resourceIds: (booksResources + notesResources).flatMap { $0.state ? $0.resource.idString : nil } )
		}
		catch
		{
			print("ERROR: Failed to save changes to user carousel")
		}
	}
}
