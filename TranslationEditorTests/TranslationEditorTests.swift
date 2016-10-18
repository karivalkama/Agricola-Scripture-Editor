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
	
	func testUSXParsing()
	{
		guard let url = Bundle.main.url(forResource: "MAT", withExtension: "usx")
		else
		{
			XCTFail("Couldn't find url")
			return
		}
		
		/*
		guard let path = Bundle(for: type(of: self)).path(forResource: "040MAT", ofType: "usx", inDirectory: "TestResources")
		// Finds the test file
		//guard let path = Bundle.main.path(forResource: "040MAT", ofType: "usx")
		else
		{
			XCTFail("usx resource not found")
			return
		}
		
		guard let data = path.data(using: .utf8)
		else
		{
			XCTFail("Failed to get usx data in utf8")
			return
		}*/
		
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
