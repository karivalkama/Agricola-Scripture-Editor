//
//  CellHistoryManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class handles (target) translation cell history management
// It can be used to provide alternative content for translationTableViewDS 
// and to keep track of history queries
class TranslationHistoryManager
{
	// ATTRIBUTES	---------------
	
	// Latest paragraph id -> Histoty paragraphs (new to old)
	private var history = [String: [Paragraph]]()
	
	
	// OTHER METHODS	-----------
	
	// Finds the currently 'displayed' / selected history version for the provided paragraph id
	func currentHistoryForParagraph(withId paragraphId: String) -> Paragraph?
	{
		return history[paragraphId]?.last
	}
	
	// Appends the history to the previous version for the provided paragraph
	// Returns whether a previous version was actually found
	func goToPreviousVersionOfParagraph(withId paragraphId: String) throws -> Bool
	{
		// Finds out the id of the displayed version for the paragraph
		let earliestId = (history[paragraphId]?.last?.idString).or(paragraphId)
		
		// Checks if there is an earlier version available
		if let previousVersion = try ParagraphHistoryView.instance.previousParagraphVersion(paragraphId: earliestId)
		{
			print("STATUS: Found history: \(paragraphId) -> \(previousVersion.idString)")
			
			history.append(key: paragraphId, value: previousVersion, empty: [])
			return true
		}
		else
		{
			return false
		}
	}
	
	func goToNextVersionOfParagraph(withId paragraphId: String) -> Bool
	{
		// If there is history, simply forgets the earliest version
		return history.popLast(at: paragraphId) != nil
	}
	
	// The 'depth' of currently displayed / selected history fo the specified paragraph
	// 0 If the history is not displayed / selected
	func currentDepthForParagraph(withId paragraphId: String) -> Int
	{
		return (history[paragraphId]?.count).or(0)
	}
	
	func updateStatus() throws
	{
		// Updates each id with history to see if the most recent id has changed
		// (also removes unnecessary keys)
		for (paragraphId, paragraphHistory) in history
		{
			if paragraphHistory.isEmpty
			{
				history[paragraphId] = nil
			}
			else
			{
				var newVersions = try ParagraphHistoryView.instance.historyOfParagraphQuery(paragraphId: paragraphId, goForward: true).resultObjects()
				if !newVersions.isEmpty
				{
					// If new versions have appeared, updates the key (to latest version) and extends the history
					let latestId = newVersions.popLast()!.idString
					history[paragraphId] = nil
					
					if let previousKeyParagraph = try Paragraph.get(paragraphId)
					{
						history[latestId] = newVersions.reversed() + previousKeyParagraph + paragraphHistory
					}
					else
					{
						print("ERROR: Paragraph History could not find a paragraph version upon update")
						history[latestId] = newVersions.reversed() + paragraphHistory
					}
				}
			}
		}
	}
}
