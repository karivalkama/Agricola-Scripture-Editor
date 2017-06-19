//
//  ImportBookPreviewVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 14.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This vc is used for previewing a book before import
class ImportBookPreviewVC: UIViewController
{
	// OUTLETS	-----------------------
	
	@IBOutlet weak var previewTableView: UITableView!
	@IBOutlet weak var bookNameField: UITextField!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var importButton: BasicButton!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var topConstraint: NSLayoutConstraint!
	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var previewDataStackView: StatefulStackView!
	
	
	// ATTRIBUTES	-------------------
	
	static let identifier = "ImportBookPreviewVC"
	
	private var previewDS: TranslationTableViewDS!
	
	private var configured = false
	private var book: Book!
	private var completion: ((Bool) -> ())?
	
	
	// LOAD	---------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		if !configured
		{
			fatalError("ImportBookPreviewVC must be configured before use")
		}
		
		contentView.configure(mainView: view, elements: [bookNameField, errorLabel, importButton], topConstraint: topConstraint, bottomConstraint: bottomConstraint, style: .squish)
		
		previewDataStackView.register(previewTableView, for: .data)
		previewDataStackView.setState(.loading)
		
		previewTableView.register(UINib(nibName: "ParagraphCell", bundle: nil), forCellReuseIdentifier: ParagraphCell.identifier)
		previewTableView.rowHeight = UITableViewAutomaticDimension
		previewTableView.estimatedRowHeight = 160
		
		previewDS = TranslationTableViewDS(tableView: previewTableView, bookId: book.idString, stateView: previewDataStackView, configureCell: configureCell)
		previewTableView.dataSource = previewDS
		
		importButton.isEnabled = false
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		contentView.startKeyboardListening()
		previewDS.activate()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		contentView.endKeyboardListening()
		previewDS.pause()
	}

	
	// ACTIONS	-----------------------
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completion?(false) })
	}
	
	@IBAction func cancelPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completion?(false) })
	}
	
	@IBAction func importButtonPressed(_ sender: Any)
	{
		if importBook()
		{
			dismiss(animated: true, completion: { self.completion?(true) })
		}
	}
	
	@IBAction func bookNameChanged(_ sender: Any)
	{
		importButton.isEnabled = !bookNameField.trimmedText.isEmpty
	}
	
	
	// OTHER METHODS	---------------
	
	func configure(bookToImport book: Book, completion: ((Bool) -> ())? = nil)
	{
		configured = true
		self.book = book
		self.completion = completion
	}
	
	private func configureCell(_ tableView: UITableView, for indexPath: IndexPath, paragraph: Paragraph) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: ParagraphCell.identifier, for: indexPath) as! ParagraphCell
		cell.configure(paragraph: paragraph)
		return cell
	}
	
	private func importBook() -> Bool
	{
		let resourceName = bookNameField.trimmedText
		
		do
		{
			// The new book cannot contain any conflicts in order to be imported
			guard try !ParagraphHistoryView.instance.rangeContainsConflicts(bookId: book.idString) else
			{
				displayAlert(withIdentifier: "ErrorAlert", storyBoardId: "MainMenu")
				{
					vc in
					
					if let errorVC = vc as? ErrorAlertVC
					{
						errorVC.configure(heading: "Conflicts in Selected Book", text: "The selected book, \(self.book.code): \(self.book.identifier) contains conflicts and cannot be imported at this time.")
					}
				}
				return false
			}
			
			guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
			{
				print("ERROR: No project to insert a book into.")
				return false
			}
			
			let targetTranslations = try project.targetTranslationQuery(bookCode: book.code).resultObjects()
			
			// Makes sure there are no conflicts within the target translations
			guard try targetTranslations.forAll({ try !ParagraphHistoryView.instance.rangeContainsConflicts(bookId: $0.idString) }) else
			{
				displayAlert(withIdentifier: "ErrorAlert", storyBoardId: "MainMenu")
				{
					vc in
					
					if let errorVC = vc as? ErrorAlertVC
					{
						errorVC.configure(heading: "Conflicts in Target Translation", text: "Target translation of \(self.book.code) contains conflicts. Please resolve those conlicts first and then try again.")
					}
				}
				
				return false
			}
			
			guard let avatarId = Session.instance.avatarId else
			{
				errorLabel.text = NSLocalizedString("No user data available!", comment: "An error displayed when avatar was not selected in book import (which shouldn't ever happen if program is workin)")
				print("ERROR: Avatar must be selected before data can be saved")
				errorLabel.isHidden = false
				return false
			}
			
			// Updates bindings for each of the target translations
			var newResources = [ResourceCollection]()
			var newBindings = [ParagraphBinding]()
			
			for targetTranslation in targetTranslations
			{
				let resource = ResourceCollection(languageId: book.languageId, bookId: targetTranslation.idString, category: .sourceTranslation, name: resourceName)
				let bindings = match(try ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects(), and: try ParagraphView.instance.latestParagraphQuery(bookId: targetTranslation.idString).resultObjects()).map { ($0.source.idString, $0.target.idString) }
				
				newResources.add(resource)
				newBindings.add(ParagraphBinding(resourceCollectionId: resource.idString, sourceBookId: book.idString, targetBookId: targetTranslation.idString, bindings: bindings, creatorId: avatarId))
			}
			
			if !newResources.isEmpty
			{
				try DATABASE.tryTransaction
				{
					try newResources.forEach { try $0.push() }
					try newBindings.forEach { try $0.push() }
				}
			}
			
			// If there is no target translation for the book already, creates one by making an empty copy
			if targetTranslations.isEmpty
			{
				_ = try book.makeEmptyCopy(projectId: projectId, identifier: project.defaultBookIdentifier, languageId: project.languageId, userId: avatarId, resourceName: resourceName)
			}
			
			return true
		}
		catch
		{
			errorLabel.text = NSLocalizedString("Internal error occurred!", comment: "An error message when book import fails due to some unexpected error")
			errorLabel.isHidden = false
			print("ERROR: Book import failed. \(error)")
			return false
		}
	}
}
