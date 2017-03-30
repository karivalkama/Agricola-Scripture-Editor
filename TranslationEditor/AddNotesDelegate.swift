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
	// Associated paragraph data contains both paragraph language name and the paragraph itself
	func insertThread(noteId: String, pathId: String, associatedParagraphData: [(String, Paragraph)])
	
	// Should create a new post for the provided thread
	func insertPost(thread: NotesThread, selectedComment: NotesPost, associatedParagraphData: [(String, Paragraph)])
}
