//
//  ConnectionTest.swift
//  TranslationEditorTests
//
//  Created by Mikko Hilpinen on 26.6.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation
import XCTest
import Alamofire
@testable import TranslationEditor

class ConnectionTest: XCTestCase
{
	func connect()
	{
		let user = "user"
		let password = "password"
		
		// Alamofire.request("https://httpbin.org/get")
		
		Alamofire.request("https://httpbin.org/basic-auth/\(user)/\(password)")
		.authenticate(user: user, password: password)
		.responseJSON { response in
		debugPrint(response)
		}
	}
}
