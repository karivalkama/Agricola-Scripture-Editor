//
//  ParagraphCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is the superclass for different translation cells (source and target)
class TranslationCell: UITableViewCell
{
	// ATTRIBUTES	-----------------
	
	weak var textView: UITextView?
	var contentPathId: String?
	
	
	// IMPLEMENTED METHODS	---------
	
	// TODO: Test override to implement simultaneous scrolling
	/*
	override func setSelected(_ selected: Bool, animated: Bool)
	{
		super.setSelected(selected, animated: animated)
		
		if let contentPathId = contentPathId
		{
			print("STATUS: CELL \(contentPathId) SELECTED")
		}
		// Configure the view for the selected state
	}*/
	
	
	// OTHER METHODS	-------------
	
	func setContent(_ text: NSAttributedString, withId pathId: String)
	{
		contentPathId = pathId
		
		guard let textView = textView else
		{
			print("ERROR: Text view hasn't been defined for new content")
			return
		}
		
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
		textView.attributedText = newText
	}
}
