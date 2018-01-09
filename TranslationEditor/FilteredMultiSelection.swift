//
//  FilteredMultiSelection.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit
import HTagView

protocol FilteredMultiSelectionDelegate: class
{
	// This function will be called whether the selection status in the multi selection changes
	func onSelectionChange(selectedIndices: [Int])
}

// This UI element allows the user to pick multiple elements from a table that also supports filtering
@IBDesignable class FilteredMultiSelection: CustomXibView, UITableViewDataSource, UITableViewDelegate, HTagViewDataSource, HTagViewDelegate, UITextFieldDelegate
{
	// OUTLETS	-----------------
	
	@IBOutlet weak var searchField: UITextField!
	@IBOutlet weak var optionTable: UITableView!
	@IBOutlet weak var selectedTagView: HTagView!
	
	
	// ATTRIBUTES	-------------
	
	weak var dataSource: FilteredSelectionDataSource?
	weak var delegate: FilteredMultiSelectionDelegate?
	
	private(set) var selectedIndices = [Int]()
	private var displayedIndices = [Int]()
	
	
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
		
		optionTable.dataSource = self
		optionTable.delegate = self
		selectedTagView.dataSource = self
		selectedTagView.delegate = self
	}
	
	
	// ACTIONS	----------------
	
	@IBAction func filterChanged(_ sender: Any)
	{
		reloadData()
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return displayedIndices.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		//return UITableViewCell()
		
		// Finds and configures the cell
		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
		
		if let dataSouce = dataSource
		{
			cell.configure(text: dataSouce.labelForOption(atIndex: displayedIndices[indexPath.row]))
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Moves the element to selected indices, updates data
		selectedIndices.append(displayedIndices[indexPath.row])
		reloadData()
		
		delegate?.onSelectionChange(selectedIndices: selectedIndices)
	}
	
	func numberOfTags(_ tagView: HTagView) -> Int
	{
		return selectedIndices.count
	}
	
	func tagView(_ tagView: HTagView, titleOfTagAtIndex index: Int) -> String
	{
		guard let dataSouce = dataSource else
		{
			print("ERROR: No data source available for multi selection view")
			return "???"
		}
		
		return dataSouce.labelForOption(atIndex: selectedIndices[index])
	}
	
	func tagView(_ tagView: HTagView, tagTypeAtIndex index: Int) -> HTagType
	{
		return .cancel
	}
	
	func tagView(_ tagView: HTagView, didCancelTagAtIndex index: Int)
	{
		// Deselects the element and refreshes data
		selectedIndices.remove(at: index)
		reloadData()
		
		delegate?.onSelectionChange(selectedIndices: selectedIndices)
	}
	
	
	// OTHER METHODS	--------
	
	func reset()
	{
		selectedIndices = []
		reloadData()
	}
	
	func reloadData()
	{
		guard let dataSouce = dataSource else
		{
			return
		}
		
		if let filter = searchField.text, !filter.isEmpty
		{
			displayedIndices = (0 ..< dataSouce.numberOfOptions).flatMap { dataSouce.indexIsIncludedInFilter(index: $0, filter: filter) ? $0 : nil }
		}
		else
		{
			displayedIndices = Array(0 ..< dataSouce.numberOfOptions)
		}
		
		// Does not display the indices that are already selected
		displayedIndices = displayedIndices.filter { !selectedIndices.contains($0) }
		
		optionTable.reloadData()
		selectedTagView.reloadData(false)
	}
}
