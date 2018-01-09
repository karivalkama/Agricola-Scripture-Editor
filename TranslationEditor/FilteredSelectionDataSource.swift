//
//  SelectionDataSource.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// The selection data source provides the content for the user to select
protocol FilteredSelectionDataSource: class
{
	// The number of options in total (not all of these are always displayed)
	var numberOfOptions: Int { get }
	
	// The displayed label for an option
	func labelForOption(atIndex index: Int) -> String
	
	// Checks whether the item at the specified index should be included in the target group of the provided filter
	func indexIsIncludedInFilter(index: Int, filter: String) -> Bool
}

extension FilteredSelectionDataSource
{
	// By default, the filter is used with the labels
	func indexIsIncludedInFilter(index: Int, filter: String) -> Bool
	{
		return labelForOption(atIndex: index).lowercased().contains(filter.lowercased())
	}
}
