//
//  CollectionUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

extension Array
{
	// Arrays can be combined together to form a new array with both elements. The left side
	// elements will be placed before the right side elements
	static func + (left: Array<Element>, right: Array<Element>) -> Array<Element>
	{
		var combined = [Element]()
		combined.append(contentsOf: left)
		combined.append(contentsOf: right)
		return combined
	}
}
