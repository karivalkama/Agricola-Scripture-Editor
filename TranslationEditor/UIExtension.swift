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

extension UIView
{
	// Returns the view's frame inside another view's coordinate system
	func frame(in view: UIView) -> CGRect
	{
		return view.convert(frame, from: superview)
	}
}

extension UITextView
{
	// Displays a usx string with the correct format
	func display(usxString: NSAttributedString)
	{
		let newText = NSMutableAttributedString()
		newText.append(usxString)
		let wholeTextRange = NSMakeRange(0, newText.length)
		
		// Adds different fonts / etc. based on attribute values
		newText.addAttribute(NSFontAttributeName, value: defaultParagraphFont, range: wholeTextRange)
		usxString.enumerateAttribute(ParaStyleAttributeName, in: wholeTextRange, options: [])
		{
			style, range, _ in
			
			if let style = style as? ParaStyle
			{
				if style.isHeaderStyle()
				{
					newText.addAttribute(NSFontAttributeName, value: headingFont, range: range)
				}
				
				var paragraphStyling: ParagraphStyling?
				switch style
				{
				case .embeddedTextOpening, .embeddedTextClosing, .embeddedTextParagraph:
					paragraphStyling = .indented(level: 1)
				case .embeddedTextRefrain, .closureOfLetter, .liturgicalNote, .poeticLineRight: paragraphStyling = .rightAlignment
				case .centered, .poeticLineCentered: paragraphStyling = .centered
				case .indented(let level): paragraphStyling = .indented(level: level)
				case .indentedFlushLeft: paragraphStyling = .thin
				case .listItem(let level): paragraphStyling = .list(level: level)
				case .poeticLine(let level): paragraphStyling = .indented(level: level)
				case .embeddedTextPoeticLine(let level): paragraphStyling = .indented(level: level)
				default: break
				}
				
				if let paragraphStyling = paragraphStyling
				{
					newText.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyling.style, range: range)
				}
			}
		}
		usxString.enumerateAttribute(IsNoteAttributeName, in: wholeTextRange, options: [])
		{
			isNote, range, _ in
			
			if isNote as? Bool ?? false
			{
				newText.addAttribute(NSFontAttributeName, value: notesFont, range: range)
			}
		}
		usxString.enumerateAttribute(CharStyleAttributeName, in: wholeTextRange, options: [])
		{
			style, range, _ in
			
			if let style = style as? CharStyle
			{
				if style == .quotation
				{
					newText.addAttribute(NSFontAttributeName, value: quotationFont, range: range)
				}
			}
		}
		usxString.enumerateAttribute(ChapterMarkerAttributeName, in: wholeTextRange, options: [])
		{
			marker, range, _ in
			
			if marker != nil
			{
				newText.addAttribute(NSFontAttributeName, value: chapterMarkerFont, range: range)
			}
		}
		
		// All marker attrites are greyed
		usxString.enumerateAttributes(in: wholeTextRange, options: [])
		{
			attributes, range, _ in
			
			if attributes.containsKey(VerseIndexMarkerAttributeName) || attributes.containsKey(ParaMarkerAttributeName) || attributes.containsKey(NoteMarkerAttributeName) || attributes.containsKey(ChapterMarkerAttributeName)
			{
				newText.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray, range: range)
			}
		}
		
		/*
		// Adds visual attributes based on the existing attribute data
		usxString.enumerateAttributes(in: NSMakeRange(0, newText.length), options: [])
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
						case .quotation: newText.addAttribute(NSFontAttributeName, value: quotationFont, range: range)
						// TODO: Add exhaustive cases
						default: break
						}
					}
				// TODO: Add handling of paraStyle
				default: newText.addAttribute(NSFontAttributeName, value: defaultParagraphFont, range: range)
				}
			}
		}*/
		
		// Sets text content
		attributedText = newText
	}
	
	// Displays a paragraph as a formatted usx string
	func display(paragraph: Paragraph)
	{
		display(usxString: paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange: false]))
	}
}

extension UITextField
{
	// Whether the text field is still empty
	var isEmpty: Bool { return trimmedText.isEmpty }
	
	// A trimmed version of the text field contents
	// An empty string is returned for empty fields
	var trimmedText: String { return (text ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
}

extension UIFont
{
	var isBold: Bool { return hasTrait(.traitBold) }
	
	var withBold: UIFont? { return withTrait(.traitBold) }
	
	var isItalic: Bool { return hasTrait(.traitItalic) }
	
	var withItalic: UIFont? { return withTrait(.traitItalic) }
	
	func hasTrait(_ trait: UIFontDescriptorSymbolicTraits) -> Bool
	{
		return fontDescriptor.symbolicTraits.contains(trait)
	}
	
	func withTrait(_ trait: UIFontDescriptorSymbolicTraits) -> UIFont?
	{
		if hasTrait(trait)
		{
			return self
		}
		else
		{
			var symTraits = fontDescriptor.symbolicTraits
			symTraits.insert([trait])
			if let fontDescriptorVar = fontDescriptor.withSymbolicTraits(symTraits)
			{
				return UIFont(descriptor: fontDescriptorVar, size: pointSize)
			}
			else
			{
				return nil
			}
		}
	}
}
