//
//  TranslationEditorTests.swift
//  TranslationEditorTests
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import XCTest
@testable import TranslationEditor

class TranslationEditorTests: XCTestCase
{
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testParaStyleParsing()
	{
		let paraStyles: [ParaStyle] = [.normal, .other("ip"), .poeticLine(1), .poeticLine(2), .sectionHeading(1), .sectionHeading(2)]
		
		for style in paraStyles
		{
			let code = style.code
			let parsed = ParaStyle.value(of: code)
			
			print("\(style) -> \(code) -> \(parsed)")
			
			assert(style.isHeaderStyle() == parsed.isHeaderStyle())
			assert(style.isParagraphStyle() == parsed.isParagraphStyle())
			assert(style.isSectionHeadingStyle() == parsed.isSectionHeadingStyle())
			
			if style.isHeaderStyle()
			{
				print("\t- Heading")
			}
			if style.isSectionHeadingStyle()
			{
				print("\t- Section heading")
			}
			if style.isParagraphStyle()
			{
				print("\t- Paragraph")
			}
		}
	}
	
	func testUSXParsing()
	{
		guard let url = Bundle.main.url(forResource: "GAL", withExtension: "usx")
		else
		{
			XCTFail("Couldn't find url")
			return
		}
		
		// Creates the parser first
		let parser = XMLParser(contentsOf: url)!
		let usxParserDelegate = USXParser()
		parser.delegate = usxParserDelegate
		
		// Parses the xml
		// Counts the performance as well
		self.measure{ parser.parse() }
		
		// Checks the results
		XCTAssertTrue(usxParserDelegate.success, "\(usxParserDelegate.error)")
		
		// Prints the results
		for book in usxParserDelegate.parsedBooks
		{
			print()
			print("\(book.code): \(book.name) (\(book.chapters.count) chapters)")
			
			for chapter in book.chapters
			{
				print("\tChapter \(chapter.index) (\(chapter.sections.count) sections)")
				
				for section in chapter.sections
				{
					var sectionName = "First section"
					if let heading = section.name
					{
						sectionName = heading
					}
					
					var rangeString = "---"
					if let range = section.range
					{
						rangeString = range.name
					}
					
					print("\t\t\(rangeString): \(sectionName)")
				}
			}
		}
		
		// Prints the contents of the first paragraph
		if let firstParagraph = usxParserDelegate.parsedBooks.first?.chapters.first?.sections.first?.content.first
		{
			print("\nThe first paragraph:")
			for para in firstParagraph.content
			{
				if para.verses.isEmpty
				{
					print("\t- \(para.text)")
				}
				else
				{
					print("\t- \(para.range!.name)")
					for verse in para.verses
					{
						print("\t\t- \(verse.range.name): \(verse.text)")
					}
				}
			}
		}
	}
	
	/*
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }*/
}
