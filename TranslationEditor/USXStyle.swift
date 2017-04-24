//
//  USXStyle.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 4.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is a common protocol between all USX style definitions.
// The style should be convertable to and from a string
protocol USXStyle
{
	var code: String {get}
	//static func value(of code: String) -> USXStyle?
}

// Should accept styles which are not recognised
enum CharStyle: String, USXStyle
{
	case quotation = "qt"
	case keyTerm = "k"
	
	// TODO: Keep updated and create a unit test
	static let values: [CharStyle] = [.quotation, .keyTerm]
	
	
	// USXStyle	------
	
	var code: String
	{
		return self.rawValue
	}
	
	static func value(of code: String) -> CharStyle?
	{
		for value in values
		{
			if value.code == code
			{
				return value
			}
		}
		
		return nil
	}
}

enum ParaStyle: USXStyle, Equatable
{
	// Paragraph styles
	case normal
	case margin
	case embeddedTextOpening
	case embeddedTextParagraph
	case embeddedTextClosing
	case embeddedTextRefrain
	case indented(Int)
	case indentedFlushLeft
	case closureOfLetter
	case listItem(Int)
	case centered
	case liturgicalNote
	
	// Heading and title styles
	case sectionHeading(Int)
	case sectionHeadingMajor(Int)
	case descriptiveTitle
	case speakerIdentification
	
	// Poetry
	case poeticLine(Int)
	case poeticLineRight
	case poeticLineCentered
	case acrosticHeading
	case embeddedTextPoeticLine(Int)
	case blank
	
	// Other
	case other(String)
	
	
	// Style collections
	private static let nonIndentedHeaderStyles: [ParaStyle] = [.descriptiveTitle, .speakerIdentification, .acrosticHeading]
	private static let nonIndentedParagraphStyles: [ParaStyle] = [.normal, .margin, .embeddedTextOpening, .embeddedTextParagraph, .embeddedTextClosing, .embeddedTextRefrain, .indentedFlushLeft, .closureOfLetter, .centered]
	private static let nonIndentedStyles: [ParaStyle] = [.liturgicalNote, .poeticLineRight, .poeticLineCentered, .blank] + nonIndentedHeaderStyles + nonIndentedParagraphStyles
	
	private static func indentedHeaderStyles(with indentation: Int) -> [ParaStyle]
	{
		return [.sectionHeading(indentation), sectionHeadingMajor(indentation)]
	}
	private static func indentedParagraphStyles(with indentation: Int) -> [ParaStyle]
	{
		return [.indented(indentation), .embeddedTextPoeticLine(indentation)]
	}
	private static func indentedStyles(with indentation: Int) -> [ParaStyle]
	{
		let otherIndented: [ParaStyle] = [.listItem(indentation), .poeticLine(indentation)]
		return otherIndented + (indentedHeaderStyles(with: indentation) + indentedParagraphStyles(with: indentation))
	}
	
	private static func styles(_ indentation: Int) -> [ParaStyle]
	{
		return nonIndentedStyles + indentedStyles(with: indentation)
	}
	
	
	// OPERATORS	-----
	
	static func == (left: ParaStyle, right: ParaStyle) -> Bool
	{
		return left.code == right.code
	}

	
	// USX STYLE	-----
	
	var code: String
	{
		switch self
		{
		case .normal: return "p"
		case .margin: return "m"
		case .embeddedTextOpening: return "pmo"
		case .embeddedTextParagraph: return "pm"
		case .embeddedTextClosing: return "pmc"
		case .embeddedTextRefrain: return "pmr"
		case .indented(let depth): return "pi\(depth)"
		case .indentedFlushLeft: return "mi"
		case .closureOfLetter: return "cls"
		case .listItem(let depth): return "li\(depth)"
		case .centered: return "pc"
		case .liturgicalNote: return "lit"
		case .sectionHeadingMajor(let depth): return "ms\(depth)"
		case .sectionHeading(let depth): return "s\(depth)"
		case .descriptiveTitle: return "d"
		case .speakerIdentification: return "sp"
		case .poeticLine(let depth): return "q\(depth)"
		case .poeticLineRight: return "qr"
		case .poeticLineCentered: return "qc"
		case .acrosticHeading: return "qa"
		case .embeddedTextPoeticLine(let depth): return "qm\(depth)"
		case .blank: return "b"
		case .other(let code): return code
		}
	}
	
	static func value(of code: String) -> ParaStyle
	{
		// Parses the possible indentation level from the code
		// First must find out how many digits there are at the end of the string
		var lastDigitIndex = -1
		let nsCode = code as NSString
		for index in stride(from: nsCode.length - 1, through: 0, by: -1)
		{
			if code.digit(at: index) == nil
			{
				break
			}
			else
			{
				lastDigitIndex = index
			}
		}
		
		// The process is a bit different if there is an indentation number at the end of the code
		if lastDigitIndex >= 0
		{
			guard let indentation = code.digit(at: NSMakeRange(lastDigitIndex, nsCode.length - lastDigitIndex))
				else
			{
				fatalError("failed to parse indentation from code: \(code)")
			}
			
			for indentedStyle in indentedStyles(with: indentation)
			{
				if indentedStyle.code == code
				{
					return indentedStyle
				}
			}
		}
		else
		{
			for nonIndentedStyle in nonIndentedStyles
			{
				if nonIndentedStyle.code == code
				{
					return nonIndentedStyle
				}
			}
			
			// A non-existing number may also be interpreted as 1
			for indentedStyle in indentedStyles(with: 1)
			{
				if indentedStyle.code == code + "1"
				{
					return indentedStyle
				}
			}
		}
		
		// If no other style could be parsed, the wild card 'other' is used
		return other(code)
	}
	
	
	// OTHER	-------
	
	// TODO: Keep these updated
	func isSectionHeadingStyle() -> Bool
	{
		switch self
		{
		case .sectionHeading, .sectionHeadingMajor: return true
		default: return false
		}
	}
	
	func isHeaderStyle() -> Bool
	{
		switch self
		{
		case .sectionHeading, .sectionHeadingMajor, .descriptiveTitle, .speakerIdentification, .acrosticHeading: return true
		default: return false
		}
	}
	
	func isParagraphStyle() -> Bool
	{
		switch self
		{
		case .normal, .margin, .embeddedTextOpening, .embeddedTextParagraph, .embeddedTextClosing, .embeddedTextRefrain, .indentedFlushLeft, .closureOfLetter, .centered, .indented, .embeddedTextPoeticLine: return true
		default: return false
		}
	}
}



