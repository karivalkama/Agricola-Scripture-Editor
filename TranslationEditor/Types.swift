//
//  Types.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A section is basically a collection of paragraphs
typealias Section = [Paragraph]
// A chapter is a collection of sections
typealias Chapter = [Section]


// These functions are used for finding existing book data for
// a project, a certain language, code and identifier
// Returns nil if no such book exists
typealias FindBook = (String, String, String, String) -> Book?

// This function / algorithm matches paragraphs with each other
// Multiple matches can be formed from / to a single paragraph
// Returns nil if the matching couldn't be done
// The left side is always an existing paragraph, while the right side is always a new paragraph
typealias MatchParagraphs = ([Paragraph], [Paragraph]) -> [(Paragraph, Paragraph)]?

// This function merges the properties of multiple conflicting revisions into a single revision
// Input: Document id string, Conflicting revision properties
// Output: Merged revision properties
// typealias Merge = (String, [PropertySet]) throws -> PropertySet
