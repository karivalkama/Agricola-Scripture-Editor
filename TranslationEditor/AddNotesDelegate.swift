//
//  AddNotesDelegate.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This delegate handles the functionality for inserting new threads and posts to notes
protocol AddNotesDelegate: class
{
	// Should finalise thread creation for the provided note and paragraph
	func insertThread(noteId: String, pathId: String)
}
