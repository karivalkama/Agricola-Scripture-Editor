//
//  TranslationCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

class TargetTranslationCell: UITableViewCell, ParagraphAssociated, UITextViewDelegate
{
	// OUTLETS	----------
	
	@IBOutlet weak var inputTextField: UITextView!
	@IBOutlet weak var notesFlagButton: UIButton!
	
	
	// ATTRIBUTES	------
	
	static let identifier = "TranslationCell"
	
	private var originalParagraph: Paragraph?
	
	private var action: TranslationCellAction?
	
	private weak var inputListener: CellInputListener?
	private weak var scrollManager: ScrollSyncManager?
	
	weak var delegate: TranslationCellDelegate?
	
	
	// COMPUTED PROPERTIES	---
	
	var pathId: String? { return originalParagraph?.pathId }
	
	
	// ACTIONS	-----------
	
	@IBAction func noteFlagButtonPressed(_ sender: Any)
	{
		if let action = action
		{
			delegate?.perform(action: action, for: self)
		}
	}
	
	
	// IMPLEMENTED METHODS	----
	
    override func awakeFromNib()
	{
        super.awakeFromNib()
		
		// Listens to changes in text view
		inputTextField.delegate = self
    }
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
	{
		// Scrolls the cell into visible area
		scrollManager?.scrollToAnchor(cell: self)
		
		// Adds a timed scroll too since the keyboard may pop up
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.33)
		{
			self.scrollManager?.scrollToAnchor(cell: self)
		}
		
		return true
	}
	
	func textViewDidChange(_ textView: UITextView)
	{
		// Informs the listeners, if present
		if let listener = inputListener, let originalParagraph = originalParagraph
		{
			listener.cellContentChanged(originalParagraph: originalParagraph, newContent: textView.attributedText)
		}
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
	{
		// The very start (before paragraph marker) of the string cannot be replaced
		if range.location == 0
		{
			return false
		}
		
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
		
		// TODO: Note markers shouldn't be edited either
		
		// TODO: Determine the attributes for the inserted text
		inputTextField.typingAttributes = [NSFontAttributeName: defaultParagraphFont, NSForegroundColorAttributeName: Colour.Primary.dark.asColour]
		return true
		
		// TODO: Implement uneditable verse markings here
		//return textView.text.occurences(of: TranslationCell.verseRegex, within: range) == text.occurences(of: TranslationCell.verseRegex)
		//return textView.text.occurrences(of: "#", within: range) == text.occurrences(of: "#")
	}
	
	
	// OTHER METHODS	-----
	
	func setContent(paragraph: Paragraph, attString: NSAttributedString? = nil)
	{
		originalParagraph = paragraph
		if let attString = attString
		{
			inputTextField.display(usxString: attString)
		}
		else
		{
			inputTextField.display(paragraph: paragraph)
		}
	}
	
	func configure(showsHistory: Bool, inputListener: CellInputListener, scrollManager: ScrollSyncManager, action: TranslationCellAction? = nil)
	{
		self.inputListener = inputListener
		self.scrollManager = scrollManager
		self.action = action
		
		// Notes flag is displayed only when there are pending notes (and not in history mode)
		notesFlagButton.isHidden = action == nil || showsHistory
		notesFlagButton.setImage(action?.icon, for: .normal)
		
		/*
		let menuItem = UIMenuItem(title: "Print To Console", action: #selector(printToConsole))
		UIMenuController.shared.menuItems = [menuItem]
		UIMenuController.shared.update()
		*/

		// When displays history, the background color is set to gray
		contentView.backgroundColor = showsHistory ? UIColor.lightGray : UIColor.white
	}
	
	func printToConsole() {
		if let range = inputTextField.selectedTextRange, let selectedText = inputTextField.text(in: range) {
			print(selectedText)
		}
	}
}
