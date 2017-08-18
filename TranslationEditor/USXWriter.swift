//
//  USXWriter.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 5.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This class handles USX writing for translation elements
class USXWriter
{
	// Creates a string representing an usx document
	// The paragraphs should be ordered correctly (chapter, section, index)
	func writeUSXDocument(book: Book, paragraphs: [Paragraph]) -> String
	{
		return "<?xml version=\"1.0\" encoding=\"utf-8\"?><usx version=\"2.5\">\(write(book: book))\(write(paragraphs: paragraphs))</usx>"
	}
	
	// Creates a string representing book introduction elements
	func write(book: Book) -> String
	{
		return "<book code=\"\(book.code.code)\" style=\"id\">\(book.identifier)</book>\(book.introduction.reduce("", { $0 + $1.toUSX }))"
	}
	
	// Creates a string representing paragraph data
	// Chapter markers are added in between the elements
	func write(paragraphs: [Paragraph]) -> String
	{
		guard !paragraphs.isEmpty else
		{
			return ""
		}
		
		var lastChapterIndex = paragraphs.first!.chapterIndex
		var s = "\n" + chapterMarker(withIndex: lastChapterIndex)
		
		for paragraph in paragraphs
		{
			if paragraph.chapterIndex != lastChapterIndex
			{
				s += "\n"
				s += chapterMarker(withIndex: paragraph.chapterIndex)
				lastChapterIndex = paragraph.chapterIndex
			}
			
			s += paragraph.toUSX
		}
		
		return s
	}
	
	/*
	func write(verse: Verse, nextStartsMidVerse: Bool = false) -> String
	{
		// The context determines, whether the verse ends are left open or not
		var range = verse.range
		if nextStartsMidVerse
		{
			if !verse.range.end.midVerse
			{
				range = VerseRange(verse.range.start, VerseIndex(verse.range.end.index - 1, midVerse: true))
			}
		}
		else
		{
			if verse.range.end.midVerse
			{
				range = VerseRange(verse.range.start, VerseIndex(verse.range.end.index))
			}
		}
		
		return "<verse number=\"\(range)\" style=\"v\"/>\(verse.content.toUSX)"
	}
	*/
	
	// Creates a string representing a USX chapter marker
	func chapterMarker(withIndex index: Int) -> String
	{
		return "<chapter number=\"\(index)\" style=\"c\"/>"
	}
	
	/*
	// Creates a string representing paragraph contents in USX format
	func write(paragraph: Paragraph) -> String
	{
		return write(paras: paragraph.content)
	}
	
	// Creates a string representing para data in USX format
	func write(paras: [Para]) -> String
	{
		return writeMany(paras, using: write(para:))
	}
	
	// Converts a para element to USX format
	func write(para: Para) -> String
	{
		return "<para style=\"\(para.style.code)\">\(para.verses.isEmpty ? write(charData: para.ambiguousContent) : write(verses: para.verses))</para>"
	}
	
	// Creates a string representing verse data in USX format
	func write(verses: [Verse]) -> String
	{
		return writeMany(verses, using: write(verse:))
	}
	
	func write(verse: Verse) -> String
	{
		return "<verse number=\"\(verse.range)\" style=\"v\"/>\(write(charData: verse.content))"
	}
	
	func write(charData: [CharData]) -> String
	{
		return writeMany(charData, using: write(charData:))
	}
	
	func write(charData: CharData) -> String
	{
		if let style = charData.style
		{
			if charData.text.isEmpty
			{
				return "<char style=\"\(style)\"/>"
			}
			else
			{
				return "<char style=\"\(style)\">\(charData.text)</char>"
			}
		}
		else
		{
			return charData.text
		}
	}
	
	private func writeMany<T>(_ elements: [T], using writer: (T) -> String) -> String
	{
		var s = String()
		elements.forEach { s += writer($0) }
		return s
	}
	*/
}
