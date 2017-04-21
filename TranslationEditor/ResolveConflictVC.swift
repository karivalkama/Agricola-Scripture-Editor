//
//  ResolveConflictVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class ResolveConflictVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
{
	// OUTLETS	-----------------
	
	@IBOutlet weak var versionCollectionView: UICollectionView!
	
	
	// ATTRIBUTES	-------------
	
	private var configured = false
	private var versionIds = [String]()
	
	private var cellWidth: CGFloat!
	
	private var versions = [Paragraph]()
	// Avatar id -> Displayed name
	private var authors = [String: String]()
	
	
	// LOAD	---------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		if !configured
		{
			fatalError("ResolveConflictVC must be configured before use")
		}
		
		cellWidth = versionCollectionView.frame.width / 2 - CGFloat(32)
		print("STATUS: Estimated cell withd: \(cellWidth)")
		
		if let flowLayout = versionCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
		{
			//let size = CGSize(width: cellWidth, height: versionCollectionView.frame.height - 16)
			flowLayout.estimatedItemSize = CGSize(width: cellWidth, height: versionCollectionView.frame.height - 128)
			//flowLayout.itemSize = size
		}
		
		// Loads the data for the collection view
		do
		{
			versions = try versionIds.flatMap { try Paragraph.get($0) }
			
			for version in versions
			{
				if !authors.containsKey(version.creatorId)
				{
					authors[version.creatorId] = try AvatarInfo.get(avatarId: version.creatorId)?.displayName()
				}
			}
		}
		catch
		{
			print("ERROR: Failed to setup version data. \(error)")
		}
		
		print("STATUS: Found \(versions.count) versions")
		
		versionCollectionView.dataSource = self
		versionCollectionView.delegate = self
    }
    

    // ACTIONS	-----------------
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		// Deprecates the other versions, leaving only the selected version in use
		do
		{
			// TODO: If there is no common ancestor, just deprecate the whole path
			guard let commonAncestor = try ParagraphHistoryView.instance.commonAncestorOf(paragraphIds: versions.map { $0.idString }) else
			{
				print("ERROR: Failed to find common ancestor for the specified paragraphs")
				return
			}
			
			for i in 0 ..< versions.count
			{
				if i != indexPath.row
				{
					// deprecates all the way until the common ancestor
					try versions[i].deprecateWithHistory(until: commonAncestor.idString)
				}
			}
		}
		catch
		{
			print("ERROR: Failed to deprecate paragraph data. \(error)")
		}
		
		dismiss(animated: true, completion: nil)
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return versions.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VersionCell.identifier, for: indexPath) as! VersionCell
		
		let version = versions[indexPath.row]
		cell.configure(author: authors[version.creatorId].or("Someone"), created: Date(timeIntervalSince1970: version.created), content: version)
		
		return cell
	}
	
	
	// OTHER METHODS	-------
	
	func configure(versionIds: [String])
	{
		self.versionIds = versionIds
		configured = true
	}
}
