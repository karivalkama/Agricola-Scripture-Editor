//
//  USXMarkerElement.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These are the USX elements used as "markers"
// Markers don't contain any text data and mark the start of a new text type / role
// Markers have certain hierarchy compared to each other (verses reside in paras which reside in chapters, etc.)
enum USXMarkerElement: String
{
	case book
	case chapter
	case verse
	
	static func > (left: USXMarkerElement, right: USXMarkerElement) -> Bool
	{
		return left.compare(to: right) > 0
	}
	
	static func >= (left: USXMarkerElement, right: USXMarkerElement) -> Bool
	{
		return left.compare(to: right) >= 0
	}
	
	static func < (left: USXMarkerElement, right: USXMarkerElement) -> Bool
	{
		return right >= left
	}
	
	static func <= (left: USXMarkerElement, right: USXMarkerElement) -> Bool
	{
		return right > left
	}
	
	private func compare(to other: USXMarkerElement) -> Int
	{
		// Compare is inverted so that higher elements (less depth) are larger than lower elements
		return other.depth() - self.depth()
	}
	
	private func depth() -> Int
	{
		switch self
		{
		case .book: return 0
		case .chapter: return 1
		case .verse: return 2
		}
	}
}
