//
//  PostThreadVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit
import HTagView

class PostThreadVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate
{
	// IB OUTLETS	-----------
	
	@IBOutlet weak var contentStackView: SquishableStackView!
	@IBOutlet weak var subjectTextField: UITextField!
	@IBOutlet weak var versePickerView: UIPickerView!
	@IBOutlet weak var commentTextView: UITextView!
	@IBOutlet weak var postButton: BasicButton!
	@IBOutlet weak var contextTableView: UITableView!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	-----------
	
	private var configured = false
	private var userId: String!
	private var noteId: String!
	private var originalParagraph: Paragraph!
	private var contextData: [(String, Paragraph)]!
	
	private var contextDS: VerseTableDS?
	
	// private let tags = ["These", "Are", "Just", "Placeholder", "Tags"]
	
	
	// COMPUTED PROPS	-------
	
	private var availableVerseRange: VerseRange? { return originalParagraph.range }
	
	private var selectedVerseIndex: VerseIndex?
	{
		guard let availableVerseRange = availableVerseRange else
		{
			return nil
		}
		
		let selectedRow = versePickerView.selectedRow(inComponent: 0) - 1
		
		guard selectedRow >= 0 else
		{
			return nil
		}
		
		return availableVerseRange.verses[selectedRow].start
	}
	
	
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
		commentTextView.delegate = self
		
		versePickerView.dataSource = self
		versePickerView.delegate = self
		
		/*
		tagView.dataSource = self
		tagView.tagMainTextColor = Colour.Text.Black.primary.asColour
		tagView.tagMainBackColor = Colour.Primary.asColour
		tagView.tagSecondTextColor = Colour.Text.Black.secondary.asColour
		tagView.tagSecondBackColor = Colour.Primary.light.asColour
		tagView.tagBorderColor = Colour.Text.Black.secondary.asColour.cgColor
		*/
		postButton.isEnabled = false
		
		contextTableView.estimatedRowHeight = 64
		contextTableView.rowHeight = UITableViewAutomaticDimension
		
		contextDS = VerseTableDS(originalParagraph: originalParagraph, resourceData: contextData)
		contextTableView.register(UINib(nibName: "VerseDataCell", bundle: nil), forCellReuseIdentifier: VerseCell.identifier)
		contextTableView.dataSource = contextDS
		
		contentView.configure(mainView: view, elements: [subjectTextField, versePickerView, commentTextView, postButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish, squishedElements: [contentStackView])
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		contentView.startKeyboardListening()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		contentView.endKeyboardListening()
	}

	
	// IB ACTIONS	-----------
	
	@IBAction func postButtonPressed(_ sender: Any)
	{
		// Creates a new thread (and post) instance, then dismisses the view
		// TODO: Add support for tags
		let thread = NotesThread(noteId: noteId, creatorId: userId, name: subjectTextField.text!, targetParagraphId: originalParagraph.idString, targetVerseIndex: selectedVerseIndex)
		
		// TODO: Comment text should be required
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
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
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
		updatePostButtonStatus()
	}
	
	@IBAction func commentLabelTapped(_ sender: Any)
	{
		commentTextView.becomeFirstResponder()
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func textViewDidChange(_ textView: UITextView)
	{
		updatePostButtonStatus()
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int
	{
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
	{
		// If there is only a single verse available, displays only a single option
		if let verses = availableVerseRange?.verses
		{
			if verses.count <= 1
			{
				return 1
			}
			else
			{
				return verses.count + 1
			}
		}
		else
		{
			return 1
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
	{
		return verseTitle(forRow: row)
	}
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString?
	{
		if let title = verseTitle(forRow: row)
		{
			return NSAttributedString(string: title, attributes: [NSAttributedStringKey.foregroundColor: Colour.Primary.dark.asColour])
		}
		else
		{
			return nil
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
	{
		// Updates the context table
		contextDS?.targetVerseIndex = selectedVerseIndex
		contextTableView.reloadData()
	}
	
	/*
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
	}*/
	
	
	// OTHER METHODS	------
	
	// Context paragraph data is language name (or other identifier) -> paragraph version
	func configure(userId: String, noteId: String, targetParagraph: Paragraph, contextParagraphData: [(String, Paragraph)])
	{
		self.userId = userId
		self.noteId = noteId
		self.originalParagraph = targetParagraph
		self.contextData = contextParagraphData
		
		self.configured = true
	}
	
	private func verseTitle(forRow row: Int) -> String?
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
	
	private func updatePostButtonStatus()
	{
		if subjectTextField.text == nil || subjectTextField.text!.isEmpty || commentTextView.text.isEmpty
		{
			postButton.isEnabled = false
		}
		else
		{
			postButton.isEnabled = true
		}
	}
}
