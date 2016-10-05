//
//  TranslationVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TranslationVC is the view controller used in the translation / review / work view
class TranslationVC: UIViewController, UITableViewDataSource, CellContentListener
{
	// Outlets	----------
	
	@IBOutlet weak var translationTableView: UITableView!
	
	
	// Vars	--------------
	
	private var testContent = [Para]()
	
	
	// Overridden	-----
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// Testing
		generateTestData()
		test()
		
		// (Epic hack which) Makes table view cells have automatic height
		translationTableView.rowHeight = UITableViewAutomaticDimension
		translationTableView.estimatedRowHeight = 160
		
		//translationTableView.delegate = self
		translationTableView.dataSource = self
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		
		// Dispose of any resources that can be recreated.
	}
	
	
	// Table view delegate	------------
	
	/*
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		// Scales the cell height based on the calculated content height (calculation made at cell)
		if let cell = translationTableView.cellForRow(at: indexPath)
		{
			return (cell as! TranslationCell).calculatedHeight
		}
		else
		{
			return 32
		}
	}
*/
	
	
	// Table View Data Source	------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		// TODO: Test implementation
		return testContent.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Finds a reusable cell
		let cell = translationTableView.dequeueReusableCell(withIdentifier: "TranslationCell", for: indexPath) as! TranslationCell
		
		// Updates cell content
		cell.setContent(to: testContent[indexPath.row].toAttributedString())
		cell.contentChangeListener = self
		return cell
	}
	
	
	// Cell Content Listener	-----------
	
	func cellContentChanged(in cell: UITableViewCell)
	{
		// Finds the cell index and updates it
		// Updates the data as well
		//let indexPath = translationTableView.indexPath(for: cell)!
		//testContent[indexPath.row] = content
		
		translationTableView.beginUpdates()
		translationTableView.endUpdates()
		//translationTableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
	}
	
	private func generateTestData()
	{
		let testString = "The first verse is here. #Followed by another.€A new paragraph starts. #asldkalsk dlka #asdjkkaj a#jasdkjadkj€ASdkkddkkdslkskd#asjddjddd€asdjdjdj"
		var paragraphs = [Para]()
		
		var index = 0
		for paraText in testString.components(separatedBy: "€")
		{
			index += 1
			
			var verses = [Verse]()
			for verseText in paraText.components(separatedBy: "#")
			{
				verses.append(Verse(range: VerseRange(start: VerseIndex(index), end: VerseIndex(index + 1)), contents: verseText))
				index += 1
			}
			
			paragraphs.append(Para(content: verses))
		}
		
		testContent = paragraphs
	}
	
	private func test()
	{
		let range = VerseRange(start: VerseIndex(1), end: VerseIndex(2))
		print("Range \(range.name) contains verses \(range.verses)")
	}
}



