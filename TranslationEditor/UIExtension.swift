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
	
	// Intensity should be between 0 and 1
	func roundCorners(intensity: CGFloat = 0.5)
	{
		layer.cornerRadius = (min(frame.width, frame.height) / 2) * intensity
		clipsToBounds = true
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
		newText.addAttribute(NSAttributedStringKey.font, value: defaultParagraphFont, range: wholeTextRange)
		usxString.enumerateAttribute(ParaStyleAttributeName, in: wholeTextRange, options: [])
		{
			style, range, _ in
			
			if let style = style as? ParaStyle
			{
				if style.isHeaderStyle()
				{
					newText.addAttribute(NSAttributedStringKey.font, value: headingFont, range: range)
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
					newText.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyling.style, range: range)
				}
			}
		}
		usxString.enumerateAttribute(IsNoteAttributeName, in: wholeTextRange, options: [])
		{
			isNote, range, _ in
			
			if isNote as? Bool ?? false
			{
				newText.addAttribute(NSAttributedStringKey.font, value: notesFont, range: range)
			}
		}
		usxString.enumerateAttribute(CharStyleAttributeName, in: wholeTextRange, options: [])
		{
			style, range, _ in
			
			if let style = style as? CharStyle
			{
				if style == .quotation
				{
					newText.addAttribute(NSAttributedStringKey.font, value: quotationFont, range: range)
				}
			}
		}
		usxString.enumerateAttribute(ChapterMarkerAttributeName, in: wholeTextRange, options: [])
		{
			marker, range, _ in
			
			if marker != nil
			{
				newText.addAttribute(NSAttributedStringKey.font, value: chapterMarkerFont, range: range)
			}
		}
		
		// All marker attrites are greyed
		usxString.enumerateAttributes(in: wholeTextRange, options: [])
		{
			attributes, range, _ in
			
			if attributes.containsKey(VerseIndexMarkerAttributeName) || attributes.containsKey(ParaMarkerAttributeName) || attributes.containsKey(NoteMarkerAttributeName) || attributes.containsKey(ChapterMarkerAttributeName)
			{
				newText.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.gray, range: range)
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

extension UIStackView
{
	func switchAxis()
	{
		if axis == .horizontal
		{
			axis = .vertical
		}
		else
		{
			axis = .horizontal
		}
	}
}

extension CGSize
{
	static func *(size: CGSize, scaling: CGFloat) -> CGSize
	{
		return CGSize(width: size.width * scaling, height: size.height * scaling)
	}
}

extension UIImage
{
	func downscaled(maxWidth: CGFloat) -> UIImage?
	{
		if size.width <= maxWidth
		{
			return self
		}
		else
		{
			return scaled(maxWidth / size.width)
		}
	}
	
	func downscaled(maxHeight: CGFloat) -> UIImage?
	{
		if size.height <= maxHeight
		{
			return self
		}
		else
		{
			return scaled(maxHeight / size.height)
		}
	}
	
	func scaledToFit(_ maxSize: CGSize) -> UIImage?
	{
		if size.width <= maxSize.width && size.height <= maxSize.height
		{
			return self
		}
		else
		{
			return scaled(min(maxSize.width / size.width, maxSize.height / size.height))
		}
	}
	
	func scaled(_ scaling: CGFloat) -> UIImage?
	{
		return scaled(toSize: size * scaling)
	}
	
	// See: https://stackoverflow.com/questions/31966885/ios-swift-resize-image-to-200x200pt-px
	func scaled(toSize newSize: CGSize) -> UIImage?
	{
		let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
		if let context = UIGraphicsGetCurrentContext()
		{
			context.interpolationQuality = .high
			let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
			context.concatenate(flipVertical)
			context.draw(self.cgImage!, in: newRect)
			let newImage = UIImage(cgImage: context.makeImage()!)
			UIGraphicsEndImageContext()
			return newImage
		}
		return nil
	}
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
