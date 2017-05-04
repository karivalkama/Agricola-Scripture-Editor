//
//  PostCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// Post cell display a notes post
class PostCell: UITableViewCell, ParagraphAssociated
{
	// OUTLETS	--------------
	
	@IBOutlet weak var postTextView: UITextView!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var userImageView: UIImageView!
	@IBOutlet weak var userNameLabel: UILabel!
	
	
	// ATTRIBUTES	----------
	
	static let identifier = "PostCell"
	
	private(set) var pathId: String?
	private(set) var post: NotesPost!
	private(set) var avatar: Avatar!
	private(set) var avatarInfo: AvatarInfo!
	
	
	// OTHER METHODS	------
	
	func setContent(post: NotesPost, pathId: String, isResolved: Bool, creator: Avatar, creatorInfo: AvatarInfo)
	{
		self.post = post
		self.pathId = pathId
		self.avatar = creator
		self.avatarInfo = creatorInfo
		postTextView.text = post.content
		
		let textColor = isResolved ? Colour.Text.Black.secondary.asColour : Colour.Text.Black.primary.asColour
		postTextView.textColor = textColor
		timeLabel.textColor = textColor
		
		let postCreated = Date(timeIntervalSince1970: post.created)
		
		// If the post was made today, only displays time. Otherwise only displays date.
		if postCreated.isWithinSameDay(with: Date())
		{
			let formatter = DateFormatter()
			formatter.timeStyle = .short
			
			timeLabel.text = formatter.string(from: postCreated)
		}
		else
		{
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			
			timeLabel.text = formatter.string(from: postCreated)
		}
		
		// Sets the user information
		userImageView.image = creatorInfo.image.or(#imageLiteral(resourceName: "userIcon"))
		userNameLabel.text = creator.name
	}
}
