//
//  USXImportAlertVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

final class USXImport
{
	// ATTRIBUTES	-----------------
	
	static let instance = USXImport()
	
	fileprivate var parseSuccesses = [BookData]()
	fileprivate var parseFailures = [(fileName: String, message: String)]()
	
	private var pendingURLs = [URL]()
	
	private weak var viewController: USXImportAlertVC?
	
	
	// INIT	-------------------------
	
	private init() {  } // Singular instance
	
	
	// OTHER METHODS	-------------
	
	func open(url: URL)
	{
		pendingURLs.add(url)
		processPendingURLs()
	}
	
	func processPendingURLs()
	{
		guard !pendingURLs.isEmpty, let projectId = Session.instance.projectId, let avatarId = Session.instance.avatarId else
		{
			return
		}
		
		for url in pendingURLs
		{
			do
			{
				if let parser = XMLParser(contentsOf: url)
				{
					let parsedBooks = try parseUSX(parser: parser, projectId: projectId, avatarId: avatarId).filter { !$0.paragraphs.isEmpty }
					
					if parsedBooks.isEmpty
					{
						parseFailures.add((fileName: url.lastPathComponent, message: "No paragraph data found!"))
					}
					else
					{
						parseSuccesses.append(contentsOf: parsedBooks)
					}
				}
				else
				{
					parseFailures.add((fileName: url.lastPathComponent, message: "Couldn't create xml parser for file"))
				}
			}
			catch
			{
				var message = "Internal Error"
				
				if let error = error as? USXParseError
				{
					switch error
					{
					case .verseIndexNotFound: message = "A verse number is missing"
					case .verseIndexParsingFailed: message = "Verse number parsing failed"
					case .verseRangeParsingFailed: message = "Verse range parsing failed"
					case .chapterIndexNotFound: message = "No chapter marker found"
					case .bookNameNotSpecified: message = "No book name found"
					case .bookCodeNotFound: message = "Book code is missing"
					case .attributeMissing: message = "Required usx-attribute is missing"
					case .unknownNoteStyle: message = "Unrecognized note style"
					}
				}
				
				parseFailures.add((fileName: url.lastPathComponent, message: message))
			}
		}
		
		// Either displays or updates the view controller to show the new data
		if let viewController = viewController, viewController.isBeingPresented
		{
			viewController.update()
		}
		else if let topVC = getTopmostVC()
		{
			topVC.displayAlert(withIdentifier: USXImportAlertVC.identifier, storyBoardId: "Common")
			{
				self.viewController = $0 as? USXImportAlertVC
			}
		}
	}
	
	fileprivate func discardData()
	{
		pendingURLs = []
		parseSuccesses = []
		parseFailures = []
	}
	
	fileprivate func close()
	{
		discardData()
		viewController?.dismiss(animated: true, completion: nil)
	}
	
	private func parseUSX(parser: XMLParser, projectId: String, avatarId: String) throws -> [BookData]
	{
		// Language is set afterwards
		let usxParserDelegate = USXParser(projectId: projectId, userId: avatarId, languageId: "")
		parser.delegate = usxParserDelegate
		parser.parse()
		
		guard usxParserDelegate.success else
		{
			throw usxParserDelegate.error!
		}
		
		return usxParserDelegate.parsedBooks
	}
	
	private func getTopmostVC() -> UIViewController?
	{
		guard let app = UIApplication.shared.delegate, let rootViewController = app.window??.rootViewController else
		{
			return nil
		}
		
		var currentController = rootViewController
		while let presentedController = currentController.presentedViewController
		{
			currentController = presentedController
		}
		
		return currentController
	}
}

// This view controller is used for parsing and presenting an overview of incoming usx file data
class USXImportAlertVC: UIViewController
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var fileAmountLabel: UILabel!
	@IBOutlet weak var dataTableView: UITableView!
	@IBOutlet weak var selectLanguageView: SimpleSingleSelectionView!
	@IBOutlet weak var selectNicknameField: SimpleSingleSelectionView!
	@IBOutlet weak var overwriteInfoLabel: UILabel!
	@IBOutlet weak var inputStackView: UIStackView!
	@IBOutlet weak var previewSwitch: UISwitch!
	@IBOutlet weak var okButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var previewSwitchStackView: UIStackView!
	@IBOutlet weak var selectionStackView: UIStackView!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "USXImportAlert"
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	
	// ACTIONS	---------------------
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		USXImport.instance.close()
	}
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		USXImport.instance.close()
	}
	
	@IBAction func okButtonPressed(_ sender: Any)
	{
		// TODO: Either insert books or go though preview for each
	}
	
	
	// OTHER METHODS	-------------
	
	fileprivate func update()
	{
		
	}
}

/*
fileprivate protocol LanguageSelectionDelegate: class
{
	func existingLanguageSelected(language: Language)
	
	func newLanguageSelected(languageName: String)
}*/
