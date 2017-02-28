//
//  FilteredMultiSelection.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit
import HTagView

// The multi selection data source provides the content for the user to select
protocol MultiSelectionDataSource
{
	// The number of options in total (not all of these are always displayed)
	var numberOfOptions: Int { get }
	
	// The displayed label for an option
	func labelForOption(atIndex: Int) -> String
	
	// Checks whether the item at the specified index should be included in the target group of the provided filter
	func indexIsIncludedInFilter(index: Int, filter: String) -> Bool
}

// This UI element allows the user to pick multiple elements from a table that also supports filtering
@IBDesignable class FilteredMultiSelection: CustomXibView
{
	// OUTLETS	-----------------
	
	@IBOutlet weak var searchField: UITextField!
	@IBOutlet weak var optionTable: UITableView!
	@IBOutlet weak var selectedTagView: HTagView!
	
	
	// INIT	---------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "FilteredMultiSelection")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "FilteredMultiSelection")
	}
	
	override func awakeFromNib()
	{
		optionTable.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
	}
	
	
	// IMPLEMENTED METHODS	----
	
	
}
