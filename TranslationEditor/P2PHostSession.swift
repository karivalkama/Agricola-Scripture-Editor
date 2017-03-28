//
//  P2PHostingSession.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class provides an interface for hosting peer to peer sessions
// Only up to a single host session is active at any time
class P2PHostSession
{
	// ATTRIBUTES	-----------------
	
	private(set) static var instance: P2PHostSession?
	
	let projectId: String
	
	private let userName: String
	private let password: String
	
	
	// INIT	--------------------------
	
	private init(projectId: String)
	{
		self.projectId = projectId
		
		userName = ""
		password = ""
	}
}
