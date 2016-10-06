//
//  PotentialVerseRangeable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Objects conforming to this protocol can, in some cases calculate the range (in verses) over which they apply
protocol PotentialVerseRangeable
{
	var range: VerseRange? {get}
}

extension PotentialVerseRangeable
{
	static func range(of elements: [PotentialVerseRangeable]) -> VerseRange?
	{
		var start: VerseIndex?
		var end: VerseIndex?
		
		// Iterates through all elements and finds the min and max indices
		// this way the collection doesn't have to be ordered
		for element in elements
		{
			if let range = element.range
			{
				if let previousStart = start
				{
					start = min(previousStart, range.start)
				}
				else
				{
					start = range.start
				}
				
				if let previousEnd = end
				{
					end = max(previousEnd, range.end)
				}
				else
				{
					end = range.end
				}
			}
		}
		
		if let start = start, let end = end
		{
			return VerseRange(start, end)
		}
		else
		{
			return nil
		}
	}
}
