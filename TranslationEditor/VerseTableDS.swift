//
//  VerseTableDS.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This class handles verse table content
class VerseTableDS: NSObject, UITableViewDataSource
{
	// ATTRIBUTES	---------------------
	
	// Language / section name -> Paragraph
	private let data: [(title: String, paragraph: Paragraph)]
	private var filteredData: [(title: String, paragraph: Paragraph)]
	
	// The specific verse index the context is limited to
	private var _targetVerseIndex: VerseIndex?
	var targetVerseIndex: VerseIndex?
	{
		get { return _targetVerseIndex }
		set
		{
			_targetVerseIndex = newValue
			filterData()
		}
	}
	
	
	// INIT	-----------------------------
	
	// Resource data is combination of a language name and a matching paragraph version
	init(originalParagraph: Paragraph, resourceData: [(String, Paragraph)])
	{
		var data = [(String, Paragraph)]()
		
		let originalTitle = NSLocalizedString("Original:", comment: "A title for the original version of a paragraph / paragraph portion in comment context")
		let currentTitle = NSLocalizedString("Current:", comment: "A title for the curent version of a paragraph / paragraph portion in comment context")
		
		// Adds the current (and original) version of the targeted paragraph first
		if originalParagraph.isMostRecent
		{
			data.append((originalTitle, originalParagraph))
		}
		else
		{
			data.append((originalTitle, originalParagraph))
			
			do
			{
				if let latestId = try ParagraphHistoryView.instance.mostRecentId(forParagraphWithId: originalParagraph.idString), let latestVersion = try Paragraph.get(latestId)
				{
					data.append((currentTitle, latestVersion))
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
		self.filteredData = self.data
	}
	
	
	// IMPLEMENTED METHODS	-------------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return filteredData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Finds a reusable cell first
		let cell = tableView.dequeueReusableCell(withIdentifier: VerseCell.identifier, for: indexPath) as! VerseCell
		
		let data = filteredData[indexPath.row]
		cell.configure(title: data.title, paragraph: data.paragraph)
		
		return cell
	}
	
	
	// OTHER METHODS	--------------
	
	func filterData()
	{
		if let targetVerseIndex = targetVerseIndex
		{
			filteredData = data.compactMap
			{
				let paragraph = $0.paragraph.copy()
				for para in paragraph.content
				{
					para.verses = para.verses.filter { $0.range.contains(index: targetVerseIndex) }
				}
				paragraph.content = paragraph.content.filter { !$0.verses.isEmpty }

				if paragraph.content.isEmpty
				{
					return nil
				}
				else
				{
					return ($0.title, paragraph)
				}
			}
		}
		else
		{
			filteredData = data
		}
	}
}
