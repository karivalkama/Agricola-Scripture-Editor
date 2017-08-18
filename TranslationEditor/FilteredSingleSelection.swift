//
//  FilteredSingleSelection.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This delegate handles the selections and inserts of the FilteredSingleSelection view
protocol FilteredSingleSelectionDelegate: class
{
	// This function is called whenever a new item is selected
	func onItemSelected(index: Int)
	
	// This function is called when the user intends to add a new element to the list
	// Should return the index for the new element
	// If the delegate returns nil, the insert is considered to be cancelled
	// Table data is reloaded afterwards
	func insertItem(named: String) -> Int?
}

// This view can be used for selecting a single element from a list that can be filtered
// The view also supports addition of new elements
@IBDesignable class FilteredSingleSelection: CustomXibView, UITableViewDataSource, UITableViewDelegate
{
	// OUTLETS	--------------
	
	@IBOutlet weak var filterField: UITextField!
	@IBOutlet weak var selectionTableView: UITableView!
	@IBOutlet weak var insertField: UITextField!
	
	
	// ATTRIBUTES	----------
	
	weak var delegate: FilteredSingleSelectionDelegate?
	weak var datasource: FilteredSelectionDataSource?
	
	private(set) var selectedIndex: Int?
	private var displayedIndices = [Int]()
	
	
	// INIT	------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "FilteredSingleSelection")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "FilteredSingleSelection")
	}
	
	override func awakeFromNib()
	{
		selectionTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		
		selectionTableView.dataSource = self
		selectionTableView.delegate = self
	}
	
	
	// ACTIONS	--------------
	
	@IBAction func filterChanged(_ sender: Any)
	{
		reloadData()
	}
	
	@IBAction func insertPressed(_ sender: Any)
	{
		// Only works when there's text in the insert field
		guard let insertText = insertField.text, !insertText.isEmpty else
		{
			return
		}
		
		// Checks whether the insert is a success
		if let newIndex = delegate?.insertItem(named: insertText)
		{
			// Removes any filters if the new index wouldn't be included
			if let filter = filterField.text, !filter.isEmpty
			{
				if !(datasource?.indexIsIncludedInFilter(index: newIndex, filter: filter) ?? false)
				{
					filterField.text = nil
				}
			}
			
			reloadData()
			
			// Selects the new index afterwards
			if let displayIndex = displayedIndices.first(where: { $0 == newIndex })
			{
				selectionTableView.selectRow(at: IndexPath(row: displayIndex, section: 0), animated: true, scrollPosition: .middle)
			}
			
			select(index: newIndex)
		}
		
		insertField.text = nil
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return displayedIndices.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
		
		if let datasource = datasource
		{
			cell.configure(text: datasource.labelForOption(atIndex: displayedIndices[indexPath.row]))
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		select(index: displayedIndices[indexPath.row])
	}
	
	
	// OTHER METHODS	-------
	
	func reloadData()
	{
		guard let datasource = datasource else
		{
			print("ERROR: FilteredSingleSelection view doesn't have a datasource to use")
			return
		}
		
		// Updates the displayed indices
		if let filter = filterField.text, !filter.isEmpty
		{
			displayedIndices = (0 ..< datasource.numberOfOptions).flatMap { datasource.indexIsIncludedInFilter(index: $0, filter: filter) ? $0 : nil }
		}
		else
		{
			displayedIndices = Array(0 ..< datasource.numberOfOptions)
		}
		
		selectionTableView.reloadData()
	}
	
	private func select(index: Int)
	{
		selectedIndex = index
		delegate?.onItemSelected(index: index)
	}
}
