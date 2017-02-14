//
//  VerseTableDS.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class handles verse table content
class VerseTableDS: NSObject, UITableViewDataSource
{
	// ATTRIBUTES	---------------------
	
	private weak var tableView: UITableView!
	
	// Language / section name -> Paragraph
	private let data: [(String, Paragraph)]
	
	private var _targetVerseIndex: VerseIndex?
	var targetVerseIndex: VerseIndex?
	{
		get { return _targetVerseIndex }
		set
		{
			_targetVerseIndex = newValue
			tableView.reloadData()
		}
	}
	
	
	// INIT	-----------------------------
	
	// Resource data is combination of a language name and a matching paragraph version
	init(tableView: UITableView, originalParagraph: Paragraph, resourceData: [(String, Paragraph)])
	{
		self.tableView = tableView
		
		var data = [(String, Paragraph)]()
		
		// Adds the current (and original) version of the targeted paragraph first
		if originalParagraph.isMostRecent
		{
			data.append(("Current", originalParagraph))
		}
		else
		{
			data.append(("Original", originalParagraph))
			
			do
			{
				if let latestId = try ParagraphHistoryView.instance.mostRecentId(forParagraphWithId: originalParagraph.idString), let latestVersion = try Paragraph.get(latestId)
				{
					data.append(("Current", latestVersion))
				}
				else
				{
					print("ERROR: No latest version available for paragraph \(originalParagraph.idString)")
				}
			}
			catch
			{
				print("ERROR: Failed to find the latest paragraph version. \(error)")
			}
		}
		
		// Also includes other data
		self.data = data + resourceData
	}
	
	
	// IMPLEMENTED METHODS	-------------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return data.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Finds a reusable cell first
		let cell = tableView.dequeueReusableCell(withIdentifier: VerseCell.identifier, for: indexPath) as! VerseCell
		
		// Configures the cell with correct data
		let title = data[indexPath.row].0
		
		// If a specific range is specified, limits the content to that range
		if let targetVerseIndex = targetVerseIndex
		{
			var text = ""
			for verse in data[indexPath.row].1.content.flatMap({ $0.verses })
			{
				if verse.range.contains(index: targetVerseIndex)
				{
					text += verse.text
				}
			}
			
			cell.configure(languageName: title, textContent: text)
		}
		else
		{
			cell.configure(languageName: title, textContent: data[indexPath.row].1.text)
		}
		
		return cell
	}
}
