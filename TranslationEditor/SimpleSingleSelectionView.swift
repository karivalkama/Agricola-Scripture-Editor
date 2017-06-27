//
//  SimpleSingleSelectionView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation


// This delegate handles reactions to value selections for the view
protocol SimpleSingleSelectionViewDelegate: class
{
	// This function is called whenever a new item is selected
	func onValueChanged(_ newValue: String, selectedAt index: Int?)
}

// This view can be used for selecting a single element from a list that can be filtered
// The view also supports addition of new elements
@IBDesignable class SimpleSingleSelectionView: CustomXibView, UITableViewDataSource, UITableViewDelegate
{
	// OUTLETS	--------------
	
	@IBOutlet weak var selectionTableView: UITableView!
	@IBOutlet weak var insertField: UITextField!
	
	
	// ATTRIBUTES	----------
	
	weak var delegate: SimpleSingleSelectionViewDelegate?
	weak var datasource: FilteredSelectionDataSource?
	
	private var value = ""
	private(set) var selectedIndex: Int?
	private var displayedIndices = [Int]()
	
	private var intrinsicHeight = 228
	
	
	// COMPUTED PROPERTIES	---
	
	override var intrinsicContentSize: CGSize { return CGSize(width: 320, height: intrinsicHeight) }
	
	
	// INIT	------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "SimpleSingleSelection")
		invalidateIntrinsicContentSize()
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "SimpleSingleSelection")
		invalidateIntrinsicContentSize()
	}
	
	override func awakeFromNib()
	{
		selectionTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		
		selectionTableView.dataSource = self
		selectionTableView.delegate = self
	}
	
	
	// ACTIONS	--------------
	
	@IBAction func valueChanged(_ sender: Any)
	{
		value = insertField.trimmedText
		selectedIndex = nil
		
		selectionTableView.selectRow(at: nil, animated: false, scrollPosition: .none)
		reloadData()
	}
	
	@IBAction func valueEditingEnded(_ sender: Any)
	{
		if let matchingIndex = displayedIndices.first(where: { datasource?.labelForOption(atIndex: $0).lowercased().contains(value.lowercased()) ?? false })
		{
			selectedIndex = matchingIndex
		}
		
		informDelegate()
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
			print("ERROR:  SimpleSingleSelectionView doesn't have a datasource to use")
			return
		}
		
		// Updates the displayed indices
		if !value.isEmpty
		{
			displayedIndices = (0 ..< datasource.numberOfOptions).flatMap { ($0 == selectedIndex || datasource.indexIsIncludedInFilter(index: $0, filter: value)) ? $0 : nil }
		}
		else
		{
			displayedIndices = Array(0 ..< datasource.numberOfOptions)
		}
		
		selectionTableView.reloadData()
		
		if let newSelectedIndex = findMatchingIndex(for: value)
		{
			selectionTableView.selectRow(at: IndexPath(row: newSelectedIndex, section: 0), animated: false, scrollPosition: .top)
			selectedIndex = newSelectedIndex
			informDelegate()
		}
		else if selectedIndex != nil
		{
			selectionTableView.selectRow(at: nil, animated: false, scrollPosition: .none)
			selectedIndex = nil
			informDelegate()
		}
	}
	
	func setIntrinsicHeight(_ height: Int)
	{
		intrinsicHeight = height
		invalidateIntrinsicContentSize()
	}
	
	private func select(index: Int)
	{
		selectedIndex = index
		
		if let datasource = datasource
		{
			value = datasource.labelForOption(atIndex: index)
			insertField.text = value
			reloadData()
		}
		
		informDelegate()
	}
	
	private func informDelegate()
	{
		delegate?.onValueChanged(value, selectedAt: selectedIndex)
	}
	
	private func findMatchingIndex(for item: String) -> Int?
	{
		return displayedIndices.first(where: { datasource?.labelForOption(atIndex: $0).lowercased() == item.lowercased() })
	}
}
