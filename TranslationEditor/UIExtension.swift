//
//  UIUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

extension UIButton
{
	// Adjusts the button's color theme
	func setVisualTheme(_ theme: Theme)
	{
		backgroundColor = theme.colour
		
		titleLabel?.textColor = theme.textColour
		tintColor = theme.textColour
		setTitleColor(theme.textColour, for: .normal)
		setTitleColor(theme.textColour, for: .disabled)
	}
}

extension UIViewController
{
	// Displays another view controller modally over this one
	// The configurer function is called before the new view controller is presented
	func displayAlert(withIdentifier alertId: String, storyBoardId: String, using configurer: ((UIViewController) -> ())? = nil)
	{
		let storyboard = UIStoryboard(name: storyBoardId, bundle: nil)
		let myAlert = storyboard.instantiateViewController(withIdentifier: alertId)
		myAlert.modalPresentationStyle = .overCurrentContext
		myAlert.modalTransitionStyle = .crossDissolve
		
		configurer?(myAlert)
		
		present(myAlert, animated: true, completion: nil)
	}
}

extension UITextView
{
	// Displays a usx string with the correct format
	func display(usxString: NSAttributedString)
	{
		let newText = NSMutableAttributedString()
		newText.append(usxString)
		
		// Adds visual attributes based on the existing attribute data
		usxString.enumerateAttributes(in: NSMakeRange(0, text.length), options: [])
		{
			attributes, range, _ in
			
			for (attrName, value) in attributes
			{
				switch attrName
				{
				case ChapterMarkerAttributeName: newText.addAttribute(NSFontAttributeName, value: chapterMarkerFont, range: range)
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
				default: newText.addAttribute(NSFontAttributeName, value: defaultParagraphFont, range: range)
				}
			}
		}
		
		// Sets text content
		attributedText = newText
	}
	
	// Displays a paragraph as a formatted usx string
	func display(paragraph: Paragraph)
	{
		display(usxString: paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange: false]))
	}
}
