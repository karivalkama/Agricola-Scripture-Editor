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
	
	@IBOutlet weak var commentTextView: UITextView!
	@IBOutlet weak var postButton: BasicButton!
	@IBOutlet weak var originalCommentTextView: UITextView!
	@IBOutlet weak var originalCommentLabel: UILabel!
	@IBOutlet weak var verseTable: UITableView!
	@IBOutlet weak var titleLabel: UILabel!
	
	
	// ATTRIBUTES	--------
	
	private var configured = false
	private var originalComment: NotesPost!
	private var userId: String!
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
		originalCommentTextView.text = originalComment.content
		
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
    }
	
	
	// IB ACTIONS	-------

	@IBAction func postButtonPressed(_ sender: Any)
	{
		// Creates a new post instance and saves it to the database
		do
		{
			try NotesPost(threadId: targetThread.idString, creatorId: userId, content: commentTextView.text).push()
			
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
	
	
	// IMPLEMENTED METHODS	----
	
	func textViewDidChange(_ textView: UITextView)
	{
		postButton.isEnabled = !textView.text.isEmpty
	}
	
	
	// OTHER METHODS	---
	
	func configure(thread: NotesThread, originalComment: NotesPost, userId: String, associatedParagraphData: [(String, Paragraph)])
	{
		self.configured = true
		self.userId = userId
		self.targetThread = thread
		self.originalComment = originalComment
		self.associatedParagraphData = associatedParagraphData
	}
}
