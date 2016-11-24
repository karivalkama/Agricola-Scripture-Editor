//
//  TranslationCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

class TranslationCell: UITableViewCell, UITextViewDelegate
{
	// Outlets ----------
	
	@IBOutlet weak var inputTextField: UITextView!
	
	
	// Vars	-------------
	
	// TODO: Replace with an implementatio where numerous listeners are supported
	// TODO: Make this better. There's no real need for a complex system like this
	var contentChangeListener: CellContentListener?
	
	
	// Overridden	-----
	
    override func awakeFromNib()
	{
        super.awakeFromNib()
		
		// Listens to changes in text view
		inputTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool)
	{
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	
	// Text view delegate
	
	func textViewDidChange(_ textView: UITextView)
	{
		// TODO: Update calculated height and inform table if necessary
		
		// Informs the listeners, if present
		if let listener = contentChangeListener
		{
			listener.cellContentChanged(in: self)
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
		inputTextField.typingAttributes = [:]
		return true
		
		// TODO: Implement uneditable verse markings here
		//return textView.text.occurences(of: TranslationCell.verseRegex, within: range) == text.occurences(of: TranslationCell.verseRegex)
		//return textView.text.occurrences(of: "#", within: range) == text.occurrences(of: "#")
	}
	
	
	// Other	---------
	
	func setContent(to text: NSAttributedString)
	{
		let newText = NSMutableAttributedString()
		newText.append(text)
		
		// Adds visual attributes based on the existing attribute data
		text.enumerateAttributes(in: NSMakeRange(0, text.length), options: [])
		{
			attributes, range, _ in
			
			for (attrName, value) in attributes
			{
				switch attrName
				{
				case ChapterMarkerAttributeName: newText.addAttribute(NSFontAttributeName, value: UIFont(name: "Arial", size: 32.0)!, range: range)
				case VerseIndexMarkerAttributeName, ParaMarkerAttributeName: newText.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray, range: range)
				case CharStyleAttributeName:
					if let style = value as? CharStyle
					{
						switch style
						{
							// TODO: This font is just for testing purposes
						case .quotation:
							newText.addAttribute(NSFontAttributeName, value: UIFont(name: "Chalkduster", size: 18.0)!, range: range)
							// TODO: Add exhaustive cases
						default: break
						}
					}
					// TODO: Add handling of paraStyle
				default: break
				}
			}
		}
		
		/*
		// Adds visual attributes to each verse and paragraph marker
		newText.enumerateAttribute(VerseIndexMarkerAttributeName, in: NSMakeRange(0, newText.length), options: [])
		{
			value, range, _ in
			
			// Makes each verse marker gray
			if value != nil
			{
				newText.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray, range: range)
			}
		}*/
		
		// Sets text content
		inputTextField.attributedText = newText
	}
}
