//
//  USXContainerElement.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.10.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// USX Container elements are USX elements which may contain text data or other USX elements (like more traditional XML elements do)
enum USXContainerElement: String
{
	case usx
	case para
	case char
	case note
	
	// TODO: WET WET
	
	static func > (left: USXContainerElement, right: USXContainerElement) -> Bool
	{
		return left.compare(to: right) > 0
	}
	
	static func >= (left: USXContainerElement, right: USXContainerElement) -> Bool
	{
		return left.compare(to: right) >= 0
	}
	
	static func < (left: USXContainerElement, right: USXContainerElement) -> Bool
	{
		return right >= left
	}
	
	static func <= (left: USXContainerElement, right: USXContainerElement) -> Bool
	{
		return right > left
	}
	
	private func compare(to other: USXContainerElement) -> Int
	{
		// Compare is inverted so that higher elements (less depth) are larger than lower elements
		return other.depth() - self.depth()
	}
	
	private func depth() -> Int
	{
		switch self
		{
		case .usx: return 0
		case .para: return 1
		case .char: return 2
		case .note: return 3
		}
	}
}
