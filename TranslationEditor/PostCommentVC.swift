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
	
	
	// ATTRIBUTES	--------
	
	private var configured = false
	private var threadId: String!
	private var userId: String!
	
	
	// INIT	----------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		// Sets up the components
		postButton.isEnabled = false
		commentTextView.delegate = self
    }
	
	
	// IB ACTIONS	-------

	@IBAction func postButtonPressed(_ sender: Any)
	{
		// Creates a new post instance and saves it to the database
		do
		{
			try NotesPost(threadId: threadId, creatorId: userId, content: commentTextView.text).push()
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
	
	func configure(userId: String, threadId: String)
	{
		self.configured = true
		self.userId = userId
		self.threadId = threadId
	}
}
