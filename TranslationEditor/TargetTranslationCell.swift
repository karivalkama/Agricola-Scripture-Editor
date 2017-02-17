//
//  TranslationCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

class TargetTranslationCell: TranslationCell, UITextViewDelegate
{
	// OUTLETS	----------
	
	@IBOutlet weak var inputTextField: UITextView!
	@IBOutlet weak var notesFlagButton: UIButton!
	
	
	// ATTRIBUTES	------
	
	private var notesIndex: Int?
	private var inputListener: CellInputListener?
	private weak var scrollManager: ScrollSyncManager?
	
	// Opens a resource category at certain index
	private var openResource: ((Int) -> ())?
	
	
	// ACTIONS	-----------
	
	@IBAction func noteFlagButtonPressed(_ sender: Any)
	{
		guard let notesIndex = notesIndex else
		{
			return
		}
		
		// Changes the selected resource to notes
		openResource?(notesIndex)
		
		// Then scrolls to highlight this cell
		scrollManager?.scrollToAnchor(cell: self)
	}
	
	// IMPLEMENTED METHODS	----
	
    override func awakeFromNib()
	{
        super.awakeFromNib()
		
		textView = inputTextField
		
		// Listens to changes in text view
		inputTextField.delegate = self
    }
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
	{
		// Scrolls the cell into visible area
		scrollManager?.scrollToAnchor(cell: self)
		return true
	}
	
	func textViewDidChange(_ textView: UITextView)
	{
		// Informs the listeners, if present
		if let listener = inputListener, let contentPathId = pathId
		{
			listener.cellContentChanged(id: contentPathId, newContent: textView.attributedText)
		}
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
	{
		// The new string can't remove verse markings
		if textView.attributedText.containsAttribute(VerseIndexMarkerAttributeName, in: range) || textView.attributedText.containsAttribute(ParaMarkerAttributeName, in: range)
		{
			return false
		}
		// The verse markins can't be split either
		else if textView.attributedText.attribute(VerseIndexMarkerAttributeName, surrounding: range) != nil || textView.attributedText.attribute(ParaMarkerAttributeName, surrounding: range) != nil
		{
			return false
		}
		
		// TODO: Determine the attributes for the inserted text
		inputTextField.typingAttributes = [NSFontAttributeName: TranslationCell.defaultFont]
		return true
		
		// TODO: Implement uneditable verse markings here
		//return textView.text.occurences(of: TranslationCell.verseRegex, within: range) == text.occurences(of: TranslationCell.verseRegex)
		//return textView.text.occurrences(of: "#", within: range) == text.occurrences(of: "#")
	}
	
	
	// OTHER METHODS	-----
	
	func configure(inputListener: CellInputListener, scrollManager: ScrollSyncManager, withNotesAtIndex notesIndex: Int?, openResource: @escaping (Int) -> ())
	{
		self.inputListener = inputListener
		self.scrollManager = scrollManager
		self.notesIndex = notesIndex
		self.openResource = openResource
		
		// Notes flag is displayed only when there are pending notes
		notesFlagButton.isHidden = notesIndex == nil
	}
}
