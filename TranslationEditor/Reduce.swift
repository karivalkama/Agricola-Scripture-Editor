//
//  Reduce.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is a collection of common reduce functions

func countRowsReduce(keys: [Any], values: [Any], rereduce: Bool) -> Any
{
	// Simply counts the rows
	if rereduce
	{
		if let values = values as? [Int]
		{
			var total = 0
			values.forEach { total += $0 }
			return total
		}
		else
		{
			return 0
		}
	}
	else
	{
		return values.count
	}

}
