//
//  ParatextRegistry.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.6.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation
import Alamofire

class ParatextRegistry
{
	private let address = "https://registry-dev.paratext.org/api8/"
	
	func authenticate(userName: String, registrationCode: String)
	{
		Alamofire.request(address + "token")
			.authenticate(user: userName, password: registrationCode)
			.responseJSON { response in
				
				
				
				debugPrint(response)
		}
	}
}
