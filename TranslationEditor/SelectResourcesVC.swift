//
//  SelectResourcesVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for determining, which resources are available to the user at which time
class SelectResourcesVC: UIViewController, UITableViewDataSource
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var resourceTableView: UITableView!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "SelectResourcesVC"
	
	var completionHandler: (() -> ())?
	
	private var resources = [(resource: ResourceCollection, state: Bool)]()
	// Language id -> language name
	private var languageNames = [String: String]()
	
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

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
		resources = []
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		resources = []
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
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return resources.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: ResourceSelectionCell.identifier, for: indexPath) as! ResourceSelectionCell
		let (resource, state) = resources[indexPath.row]
		cell.configure(resourceId: resource.idString, resourceName: resource.name, resourceLanguage: languageNames[resource.languageId] ?? "", resourceState: state, onResourceStateChange: resourceStateChanged)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
	{
		return true
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
	{
		let movedElement = resources.remove(at: sourceIndexPath.row)
		resources.insert(movedElement, at: destinationIndexPath.row)
		
		save()
	}

	
	// OTHER METHODS	------------
	
	private func resourceStateChanged(resourceId: String, newState: Bool)
	{
		resources = resources.map { (resource, state) in resource.idString == resourceId ? (resource, newState) : (resource, state) }
		save()
	}
	
	private func setup()
	{
		// Doesn't need to reload resources if they are already loaded
		guard resources.isEmpty else
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
			
			// If there's an existing carousel, uses ordering and states from that one
			if let carousel = try Carousel.get(avatarId: avatarId, bookCode: Book.code(fromId: bookId))
			{
				resources = carousel.resourceIds.flatMap { id in allResources.first(where: { $0.idString == id }).map { ($0, true) } } + allResources.filter { !carousel.resourceIds.contains($0.idString) }.map { ($0, false) }
			}
			else
			{
				// Otherwise enables all resources and uses the default order
				resources = allResources.map { ($0, true) }
			}
			
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
			try Carousel.push(avatarId: avatarId, bookCode: Book.code(fromId: bookId), resourceIds: resources.flatMap { $0.state ? $0.resource.idString : nil } )
		}
		catch
		{
			print("ERROR: Failed to save changes to user carousel")
		}
	}
}
