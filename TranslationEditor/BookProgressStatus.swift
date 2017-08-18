//
//  BookProgressStatus.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This is a simple struct for storing book completion status
struct BookProgressStatus: Comparable
{
	// ATTRIBUTES	---------------
	
	// How many verses / elements does the book contain in total (size)
	var totalElementAmount: Int
	// How many of the elements are filled
	var filledElementAmount: Int
	// How many filled history versions there are in total
	var filledHistoryElementAmount: Int
	
	
	// COMPUTED PROPERTIES	-------
	
	// The 'completion rate' of the book
	// This reflects the quantity of the translation
	var fullness: Double
	{
		if totalElementAmount == 0
		{
			return 0
		}
		else
		{
			return Double(filledElementAmount) / Double(totalElementAmount)
		}
	}
	
	// How many commits there are per single filled verse on average
	// This reflects the quality of the translation
	var averageCommitsPerVerse: Double
	{
		if filledElementAmount == 0
		{
			return 0
		}
		else
		{
			return 1 + Double(filledHistoryElementAmount) / Double(filledElementAmount)
		}
	}
	
	
	// OPERATORS	---------------
	
	static func ==(_ left: BookProgressStatus, _ right: BookProgressStatus) -> Bool
	{
		return left.totalElementAmount == right.totalElementAmount && left.filledElementAmount == right.filledElementAmount && left.filledHistoryElementAmount == right.filledHistoryElementAmount
	}
	
	static func <(_ left: BookProgressStatus, _ right: BookProgressStatus) -> Bool
	{
		return left.fullness.compare(with: right.fullness) ?? left.averageCommitsPerVerse.compare(with: right.averageCommitsPerVerse) ?? (left.filledElementAmount + left.filledHistoryElementAmount).compare(with: (right.filledElementAmount + right.filledHistoryElementAmount)) ?? (left.totalElementAmount < right.totalElementAmount)
	}
}
