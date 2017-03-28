//
//  P2PHostingSession.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate func randomAlphaNumericString(length: Int) -> String
{
	let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	let allowedCharsCount = UInt32(allowedChars.characters.count)
	var randomString = ""
	
	for _ in 0 ..< length
	{
		let randomNum = Int(arc4random_uniform(allowedCharsCount))
		let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
		let newCharacter = allowedChars[randomIndex]
		randomString += String(newCharacter)
	}
	
	return randomString
}

// This class provides an interface for hosting peer to peer sessions
// Only up to a single host session is active at any time
class P2PHostSession
{
	// ATTRIBUTES	-----------------
	
	private(set) static var instance: P2PHostSession?
	
	let projectId: String
	
	private let userName: String
	private let password: String
	private let listener: CBLListener
	
	
	// COMPUTED PROPERTIES	----------
	
	// A QR Code instance that represents basic hosting data
	var connectionInformation: P2PConnectionInformation?
	{
		guard let url = listener.url?.absoluteString else
		{
			print("ERROR: Failed to parse URL for P2P hosting")
			return nil
		}
		
		return P2PConnectionInformation(serverURL: url, userName: userName, password: password, projectId: projectId)
	}
	
	
	// INIT	--------------------------
	
	private init(projectId: String) throws
	{
		self.projectId = projectId
		
		userName = randomAlphaNumericString(length: 16)
		password = randomAlphaNumericString(length: 16)
		
		listener = CBLListener(manager: CBLManager.sharedInstance(), port: 7623)
		listener.requiresAuth = true
		listener.setPasswords([userName: password])
		
		try listener.start()
	}
	
	
	// OTHER METHODS	---------------
	
	// Starts a new hosting session
	// If there is already a session, may just continue that or replace it with a new one (depending on target project)
	static func start(projectId: String) throws -> P2PHostSession
	{
		if let instance = instance
		{
			if instance.projectId == projectId
			{
				return instance
			}
			else
			{
				instance.listener.stop()
			}
		}
		
		instance = try P2PHostSession(projectId: projectId)
		return instance!
	}
	
	// Stops the current P2P hosting session
	static func stop()
	{
		if let instance = instance
		{
			instance.listener.stop()
		}
		instance = nil
	}
}
