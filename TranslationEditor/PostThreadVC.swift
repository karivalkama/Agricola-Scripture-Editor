//
//  PostThreadVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit
import HTagView

class PostThreadVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, HTagViewDataSource
{
	// IB OUTLETS	-----------
	
	@IBOutlet weak var subjectTextField: UITextField!
	@IBOutlet weak var versePickerView: UIPickerView!
	@IBOutlet weak var commentTextView: UITextView!
	@IBOutlet weak var tagView: HTagView!
	@IBOutlet weak var postButton: BasicButton!
	
	
	// ATTRIBUTES	-----------
	
	private var configured = false
	private var userId: String!
	private var availableVerseRange: VerseRange?
	private var noteId: String!
	
	private let tags = ["These", "Are", "Just", "Placeholder", "Tags"]
	
	
	// INIT	-------------------
	
	// dismissViewControllerAnimated(true, completion: nil)
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		guard configured else
		{
			fatalError("PostThreadVC Must be configured before use!")
		}
		
		// Configures UI elements
		versePickerView.dataSource = self
		versePickerView.delegate = self
		
		tagView.dataSource = self
		tagView.tagMainTextColor = Colour.Text.Black.primary.asColour
		tagView.tagMainBackColor = Colour.Primary.asColour
		tagView.tagSecondTextColor = Colour.Text.Black.secondary.asColour
		tagView.tagSecondBackColor = Colour.Primary.light.asColour
		tagView.tagBorderColor = Colour.Text.Black.secondary.asColour.cgColor
		
		postButton.isEnabled = false
    }

	
	// IB ACTIONS	-----------
	
	@IBAction func postButtonPressed(_ sender: Any)
	{
		let verseIndex = availableVerseRange?.verses[versePickerView.selectedRow(inComponent: 0) - 1].start
		
		// Creates a new thread (and post) instance, then dismisses the view
		// TODO: Add support for tags
		// TODO: Use the real target paragraph id here
		let thread = NotesThread(noteId: noteId, creatorId: userId, name: subjectTextField.text!, targetParagraphId: "", targetVerseIndex: verseIndex)
		let post = commentTextView.text.isEmpty ? nil : NotesPost(threadId: thread.idString, creatorId: userId, content: commentTextView.text)
		
		do
		{
			try DATABASE.tryTransaction
			{
				try thread.push()
				try post?.push()
			}
			
			// Dismisses the view afterwards
			dismiss(animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Failed to save the thread / post to database \(error)")
		}
	}
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		// Just dismisses the view
		dismiss(animated: true, completion: nil)
	}
	
	/*
	// Post button is enabled only when there is a subject
	if subjectTextField.text == nil || subjectTextField.text!.isEmpty
	{
	postButton.isEnabled = false
	}
	else
	{
	postButton.isEnabled = true
	}
	*/
	
	@IBAction func subjectChanged(_ sender: Any)
	{
		if subjectTextField.text == nil || subjectTextField.text!.isEmpty
		{
			postButton.isEnabled = false
		}
		else
		{
			postButton.isEnabled = true
		}
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int
	{
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
	{
		return 1 + (availableVerseRange?.verses.count).or(0)
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
	{
		if row == 0
		{
			return "All"
		}
		else
		{
			return availableVerseRange?.verses[row - 1].name
		}
	}
	
	func numberOfTags(_ tagView: HTagView) -> Int
	{
		return tags.count
	}
	
	func tagView(_ tagView: HTagView, titleOfTagAtIndex index: Int) -> String
	{
		return tags[index]
	}
	
	func tagView(_ tagView: HTagView, tagTypeAtIndex index: Int) -> HTagType
	{
		return .select
	}
	
	
	// OTHER METHODS	------
	
	func configure(userId: String, noteId: String, paragraphRange: VerseRange?)
	{
		self.userId = userId
		self.availableVerseRange = paragraphRange
		self.noteId = noteId
		
		self.configured = true
	}
}
