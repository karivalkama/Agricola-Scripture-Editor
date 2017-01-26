//
//  User.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 25.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class User
{
	// ATTRIBUTES	-----------
	
	static let type = "user"
	
	let userName: String
	var displayName: String
	
	
	// INIT	-------------------
	
	init(name: String)
	{
		self.displayName = name
		self.userName = "askdlaskdlkad"
	}
}
