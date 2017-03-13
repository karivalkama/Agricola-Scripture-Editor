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
class CellHistoryManager
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
		return history.dropLast(at: paragraphId) != nil
	}
}
