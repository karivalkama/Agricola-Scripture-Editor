//
//  PostCommentVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 25.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class PostCommentVC: UIViewController, UITextViewDelegate
{
	// OUTLETS	------------
	
	@IBOutlet weak var allContentStackView: SquishableStackView!
	@IBOutlet weak var commentTextView: UITextView!
	@IBOutlet weak var postButton: BasicButton!
	@IBOutlet weak var originalCommentTextView: UITextView!
	@IBOutlet weak var originalCommentLabel: UILabel!
	@IBOutlet weak var verseTable: UITableView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var originalCommentTitleLabel: UILabel!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	--------
	
	private var configured = false
	private var selectedComment: NotesPost!
	private var targetThread: NotesThread!
	// Title (eg. English:) + paragraph
	private var associatedParagraphData: [(String, Paragraph)]!
	
	private var verseTableDS: VerseTableDS?
	
	
	// INIT	----------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		// Sets up the components
		postButton.isEnabled = false
		commentTextView.delegate = self
		
		titleLabel.text = targetThread.name
		
		// Sets up the verse table
		verseTable.register(UINib(nibName: "VerseDataCell", bundle: nil), forCellReuseIdentifier: VerseCell.identifier)
		verseTable.estimatedRowHeight = 240
		verseTable.rowHeight = UITableViewAutomaticDimension
		
		do
		{
			guard let targetParagraph = try Paragraph.get(targetThread.originalTargetParagraphId) else
			{
				print("ERROR: Could not find the targeted paragraph for the comment")
				return
			}
			
			verseTableDS = VerseTableDS(originalParagraph: targetParagraph, resourceData: associatedParagraphData)
			verseTableDS?.targetVerseIndex = targetThread.targetVerseIndex
			verseTable.dataSource = verseTableDS
		}
		catch
		{
			print("ERROR: Failed to read paragraph data from the database. \(error)")
		}
		
		// The contents are slightly different when editing an existing comment
		let isEditing = selectedComment.creatorId == Session.instance.avatarId
		
		do
		{
			var originalComment: NotesPost?
			
			if isEditing
			{
				if let originalCommentId = selectedComment.originalCommentId
				{
					originalComment = try NotesPost.get(originalCommentId)
				}
				
				commentTextView.text = selectedComment.content
			}
			else
			{
				originalComment = selectedComment
			}
			
			var originalCommentWriter = NSLocalizedString("Someone", comment: "A placeholder for comment author title. Used when no user name is available")
			
			if let originalCommentCreatorId = originalComment?.creatorId, let originalCreator = try Avatar.get(originalCommentCreatorId)
			{
				originalCommentWriter = originalCreator.name
			}
			
			originalCommentTitleLabel.text = "\(originalCommentWriter) \(NSLocalizedString("wrote", comment: "a portion of a comment's title. Something like 'this and this wrote:'")):"
			originalCommentTextView.text = originalComment?.content
		}
		catch
		{
			print("ERROR: Failed to read database data. \(error)")
		}
		
		contentView.configure(mainView: view, elements: [commentTextView, postButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish, squishedElements: [allContentStackView])
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		contentView.startKeyboardListening()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		contentView.endKeyboardListening()
	}
	
	
	// IB ACTIONS	---------

	@IBAction func postButtonPressed(_ sender: Any)
	{
		// Creates a new post instance and saves it to the database
		do
		{
			// Again, the functionality is slightly different when editing
			let avatarId = Session.instance.avatarId!
			let isEditing = avatarId == selectedComment.creatorId
			
			let newText: String = commentTextView.text
			
			if isEditing
			{
				// Modifies the existing comment
				if newText != selectedComment.content
				{
					selectedComment.content = newText
					try selectedComment.push()
				}
			}
			else
			{
				try NotesPost(threadId: targetThread.idString, creatorId: avatarId, content: newText, originalCommentId: selectedComment.idString).push()
			}
			
			// If the thread was already marked as resolved, it is reopened
			if targetThread.isResolved
			{
				try targetThread.setResolved(false)
			}
			
			dismiss(animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Failed to save the post to the database \(error)")
		}
	}
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func textViewDidChange(_ textView: UITextView)
	{
		postButton.isEnabled = !textView.text.isEmpty
	}
	
	
	// OTHER METHODS	---------
	
	func configure(thread: NotesThread, selectedComment: NotesPost, associatedParagraphData: [(String, Paragraph)])
	{
		self.configured = true
		self.targetThread = thread
		self.selectedComment = selectedComment
		self.associatedParagraphData = associatedParagraphData
	}
}
