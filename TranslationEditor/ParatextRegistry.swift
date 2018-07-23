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
	static func authenticate(userName: String, registrationCode: String) -> Promise<String>
	{
		let promise = Promise<String>()
		
		Alamofire.request(address + "token", method: .post)
			.authenticate(user: userName, password: registrationCode)
			.validate()
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
						
						if let token = json["access_token"].string
						{
							promise.succeed(with: token)
						}
						else
						{
							promise.fail(with: DataNotFoundError(message: "No access token in response body"))
						}
					}
					catch
					{
						promise.fail(with: error)
					}
				}
				else if let error = response.error
				{
					promise.fail(with: error)
				}
				else
				{
					promise.fail(with: DataNotFoundError(message: "No data and no error in response"))
				}
			}
		
		return promise
	}
}
