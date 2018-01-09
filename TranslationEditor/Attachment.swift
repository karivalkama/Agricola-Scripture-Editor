//
//  Attachment.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.3.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Attachments can be added to stored models. They contain data like images or audio.
struct Attachment
{
	// ATTRIBUTES	--------------------
	
	var data: Data
	var contentType: String
	
	
	// COMPUTED PROPERTIES	------------
	
	// The contents of this attachment as an image
	var toImage: UIImage? { return UIImage(data: data) }
	
	
	// INIT	----------------------------
	
	init(data: Data, contentType: String)
	{
		self.data = data
		self.contentType = contentType
	}
	
	// Wraps an UIImage as an attachment
	static func parse(fromImage image: UIImage) -> Attachment?
	{
		if let data = UIImagePNGRepresentation(image)
		{
			return Attachment(data: data, contentType: "image/png")
		}
		else
		{
			return nil
		}
	}
}
