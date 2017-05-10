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
	
	/*
	func testTextAndNotes()
	{
		func represent(_ element: TextWithFootnotes) -> String { return element.text }
		
		let filled = TextWithFootnotes(textElements: [TextElement(charData: ["Eka", CharData(text: "Toka", style: CharStyle.quotation)])], footNotes: [FootNote(caller: "+", style: .footNote, originReference: nil, charData: ["Kommentti"])])
		
		copyTest(TextWithFootnotes(), represent: represent)
		{
			
		}
	}
*/
	
	func testParagraph()
	{
		func makeText(text1: String, text2: String, note: String) -> TextWithNotes
		{
			let firstChar = CharData(text: text1)
			let secondChar = CharData(text: text2, style: .quotation)
			let noteChar = CharData(text: note)
			return TextWithNotes(textElements: [TextElement(charData: [firstChar]), TextElement(charData: [secondChar])], footNotes: [FootNote(caller: "+", style: .endNote, originReference: nil, charData: [noteChar])])
		}
		
		func represent(_ paragraph: Paragraph) -> String { return paragraph.text }
		
		let filled = Paragraph(bookId: "test", chapterIndex: 1, sectionIndex: 1, index: 1, content: [Para(content: makeText(text1: "Eka", text2: "Toka", note: "Note"), style: .sectionHeading(1)), Para(content: [Verse(range: VerseRange(1, 2), content: makeText(text1: "Verse1 alkaa ", text2: "verse 1 loppuu", note: "muistiinpano"))], style: .normal)], creatorId: "test")
		
		copyTest(filled, represent: represent, modify: { $0.content = Array($0.content.dropFirst()) })
		
		let empty = filled.emptyCopy(forBook: "test", creatorId: "test")
		
		print("Original: \(filled.text)")
		print("Empty Copy: \(empty.text)")
		
		let attString = filled.toAttributedString(options: [Paragraph.optionDisplayParagraphRange: false])
		copyTest(empty, represent: represent, modify: { $0.update(with: attString) })
		
		print("Attributed representation: \(attString)")
		empty.update(with: filled.toAttributedString(options: [Paragraph.optionDisplayParagraphRange: false]))
		print("Filled again: \(empty.text)")
		
		print(empty.toAttributedString(options: [Paragraph.optionDisplayParagraphRange: false]))
		
		filled.update(with: attString)
		let newAttString = filled.toAttributedString(options: [Paragraph.optionDisplayParagraphRange: false])
		
		print("Compare attributed strings: ")
		print()
		print(attString)
		print()
		print(newAttString)
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
