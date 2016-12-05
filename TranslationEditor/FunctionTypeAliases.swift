//
//  FunctionTypeAliases.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 5.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

/*
private let findReplacedBook: (String, String, String) -> Book?
private let matchParagraphs: ([Paragraph], [Paragraph]) -> [(Paragraph, Paragraph)]?
*/

// These functions are used for finding existing book data for
// a certain language, code and identifier
// Returns nil if no such book exists
typealias FindBook = (String, String, String) -> Book?

// This function / algorithm matches paragraphs with each other
// Multiple matches can be formed from / to a single paragraph
// Returns nil if the matching couldn't be done
// The left side is always an existing paragraph, while the right side is always a new paragraph
typealias MatchParagraphs = ([Paragraph], [Paragraph]) -> [(Paragraph, Paragraph)]?
