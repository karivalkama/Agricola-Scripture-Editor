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
	private static let copiedAttributeNames = [NSAttributedStringKey.font, IsNoteAttributeName, CharStyleAttributeName, ParaStyleAttributeName, NSAttributedStringKey.paragraphStyle]
	
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
		
		// The new string can't remove verse markers, paragraph markers or notes markers
		if textView.attributedText.containsAttribute(VerseIndexMarkerAttributeName, in: range) || textView.attributedText.containsAttribute(ParaMarkerAttributeName, in: range) || textView.attributedText.containsAttribute(NoteMarkerAttributeName, in: range)
		{
			return false
		}
		// The verse markers can't be split either
		else if textView.attributedText.attribute(VerseIndexMarkerAttributeName, surrounding: range) != nil || textView.attributedText.attribute(ParaMarkerAttributeName, surrounding: range) != nil || textView.attributedText.attribute(NoteMarkerAttributeName, surrounding: range) != nil
		{
			return false
		}
		
		var newAttributes = [NSAttributedStringKey: Any]()
		
		// In case of replacing text, just copies the attributes from the original
		// Otherwise copies from the left of the replaced text
		let copyFromRange = range.length > 0 ? range : NSMakeRange(range.location - 1, 1)
		textView.attributedText.enumerateAttributes(in: copyFromRange, options: [])
		{
			attributes, range, _ in
			
			let meaningfulAttributes = attributes.filter { TargetTranslationCell.copiedAttributeNames.contains($0.key) }.toDictionary { ($0.key, $0.value) }
			newAttributes = newAttributes + meaningfulAttributes
		}
		
		// Is note attribute is always determined by the surrounding area
		newAttributes[IsNoteAttributeName] = textView.attributedText.attribute(IsNoteAttributeName, surrounding: range)
		
		// The color attribute is always overwritten
		newAttributes[NSAttributedStringKey.foregroundColor] = Colour.Primary.dark.asColour
		inputTextField.typingAttributes = newAttributes.mapKeys { $0.rawValue }
		return true
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
