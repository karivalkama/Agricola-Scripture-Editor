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
	private static let address = "https://registry-dev.paratext.org/api8/"
	
	// Authenticates the user and returns an access token. May fail.
	static func authenticate(userName: String, registrationCode: String) throws -> String
	{
		var token: String? = nil
		var readError: Error? = nil
		
		Alamofire.request(address + "token")
			.authenticate(user: userName, password: registrationCode)
			.responseJSON
			{ response in
				
				print("Response found")
				print(response)
				
				if let data = response.data
				{
					print("Found data")
					do
					{
						let json = try JSON(data: data)
						
						print(json)
						
						token = json["access_token"].string
					}
					catch
					{
						readError = error
					}
				}
				else if let error = response.error
				{
					print("Read error")
					readError = error
				}
				else
				{
					print("No data and no error")
				}
				
				debugPrint(response)
		}
		
		if let token = token
		{
			print("Returns token")
			return token
		}
		else if let error = readError
		{
			print("Throws error")
			throw error
		}
		else
		{
			print("No data was found")
			throw DataNotFoundError(message: "Access token not provided in response")
		}
	}
}
