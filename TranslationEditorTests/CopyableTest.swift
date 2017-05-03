//
//  CopyableTest.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 3.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation


import XCTest
@testable import TranslationEditor
// import Pods_TranslationEditor


class CopyableTest: XCTestCase
{
	func testTextElement()
	{
		copyTest(TextElement(charData: [CharData(text: "Eka"), CharData(text: "Toka", style: CharStyle.quotation)]), represent: { return $0.text })
		{
			textElement in
			
			textElement.charData = textElement.charData.map { CharData(text: $0.text.lowercased(), style: $0.style) }
		}
		
		copyTest(TextElement.empty(), represent: { return $0.text })
		{
			$0.charData.add(CharData(text: "Lisätty"))
		}
	}
	
	func testFootNote()
	{
		func represent(_ note: FootNote) -> String
		{
			return "\(note.caller): \(note.text)"
		}
		
		copyTest(FootNote(caller: "+", style: .footNote), represent: represent)
		{
			$0.charData.add(CharData(text: "Lisätty"))
		}
		
		let charData = CharData(text: "Alkuperäinen")
		copyTest(FootNote(caller: "+", style: .endNote, originReference: nil, charData: [charData]), represent: represent)
		{
			footNote in
			
			footNote.charData = footNote.charData.map { CharData(text: $0.text + "Lisätty") }
		}
	}
	
	func testTextAndNotes()
	{
		func represent(_ element: TextWithFootnotes) -> String { return element.text }
		
		let filled = TextWithFootnotes(textElements: [TextElement(charData: ["Eka", "Toka"])], footNotes: [FootNote(caller: "+", style: .footNote, originReference: nil, charData: ["Kommentti"])])
	}
	
	func copyTest<T: Copyable>(_ original: T, represent: (T) -> String, modify: (T) -> ())
	{
		let originalRepresentation = represent(original)
		
		// Makes a copy of the original and makes sure they are considered equal
		let copy = original.copy()
		assert(original.contentEquals(with: copy), "Content doesn't equal after direct copy: \(represent(original)) vs. \(represent(copy))")
		modify(copy)
		assert(!original.contentEquals(with: copy), "Content equals even after the instance was modified: '\(represent(original))' was previously '\(originalRepresentation)'")
	}
}
