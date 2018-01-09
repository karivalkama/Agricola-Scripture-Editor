//
//  ParagraphCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This is the superclass for different translation cells (source and target)
@available(*, deprecated)
class TranslationCell: UITableViewCell, ParagraphAssociated
{
	// ATTRIBUTES	-----------------
	
	weak var textView: UITextView?
	var pathId: String?
	
	private static let chapterMarkerFont = UIFont(name: "Arial", size: 32.0)!
	static let defaultFont = UIFont(name: "Arial", size: 16.0)!
	
	
	// OTHER METHODS	-------------
	
	func setContent(_ text: NSAttributedString, withId pathId: String)
	{
		self.pathId = pathId
		
		guard let textView = textView else
		{
			print("ERROR: Text view hasn't been defined for new content")
			return
		}
		
		textView.scrollsToTop = false
		
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
				case ChapterMarkerAttributeName: newText.addAttribute(NSAttributedStringKey.font, value: TranslationCell.chapterMarkerFont, range: range)
				case VerseIndexMarkerAttributeName, ParaMarkerAttributeName: newText.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.gray, range: range)
				case CharStyleAttributeName:
					if let style = value as? CharStyle
					{
						switch style
						{
						// TODO: This font is just for testing purposes
						case .quotation:
							newText.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "Chalkduster", size: 18.0)!, range: range)
						// TODO: Add exhaustive cases
						default: break
						}
					}
				// TODO: Add handling of paraStyle
				default: newText.addAttribute(NSAttributedStringKey.font, value: TranslationCell.defaultFont, range: range)
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
