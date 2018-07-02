//
//  ParatextRegistry.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.6.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class ParatextRegistry
{
	private let address = "https://registry-dev.paratext.org/api8/"
	
	// Authenticates the user and returns an access token. May fail.
	func authenticate(userName: String, registrationCode: String) throws -> String
	{
		var token: String? = nil
		var readError: Error? = nil
		
		Alamofire.request(address + "token")
			.authenticate(user: userName, password: registrationCode)
			.responseJSON { response in
				
				if let data = response.data
				{
					do
					{
						let json = try JSON(data: data)
						token = json["access_token"].string
					}
					catch
					{
						readError = error
					}
				}
				else if let error = response.error
				{
					readError = error
				}
				
				debugPrint(response)
		}
		
		if let token = token
		{
			return token
		}
		else if let error = readError
		{
			throw error
		}
		else
		{
			throw DataNotFoundError(message: "Access token not provided in response")
		}
	}
}
