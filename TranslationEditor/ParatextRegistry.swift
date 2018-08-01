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
		return request(using: Alamofire.request(address + "token", method: .post).authenticate(user: userName, password: registrationCode), jsonParser:
		{
			if let token = $0["access_token"].string
			{
				return Try<String>.success(token)
			}
			else
			{
				return Try<String>.failure(DataNotFoundError(message: "No access token in response body"))
			}
		}, noDataResult: { Try<String>.failure(DataNotFoundError(message: "No data and no error in response")) })
	}
	
	// TODO: It is still unclear, whether to use registry projects (JSON) or paratext API projects (XML)
	static func readProjects(using token: String) -> Promise<[ParatextProject]>
	{
		return request(urlEnd: "projects", headers: tokenAuth(token), jsonParser:
		{
			json in
			
			let projects = json.arrayValue.compactMap
			{
				project -> ParatextProject? in
				
				guard let id = project["identification_systemId"].arrayValue.first?["id"].string else
				{
					return nil
				}
				
				guard let name = project["identification_name"].string else
				{
					return nil
				}
				
				return ParatextProject(id: id, name: name, shortName: project["identification_shortName"].stringValue, description: project["identification_description"].stringValue)
			}
			
			return Try<[ParatextProject]>.success(projects)
			
		}, noDataResult: { Try<[ParatextProject]>.success([]) })
	}
	
	private static func tokenAuth(_ token: String) -> HTTPHeaders
	{
		return ["Authorization" : "Bearer " + token]
	}
	
	private static func request<T>(urlEnd: String, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, jsonParser: @escaping (JSON) -> Try<T>, noDataResult: @escaping () -> Try<T>) -> Promise<T>
	{
		return request(using: Alamofire.request(address + urlEnd, method: method, headers: headers), jsonParser: jsonParser, noDataResult: noDataResult)
	}
	
	private static func request<T>(using request: DataRequest, jsonParser: @escaping (JSON) -> Try<T>, noDataResult: @escaping () -> Try<T>) -> Promise<T>
	{
		let promise = Promise<T>()
		
		request.validate().responseJSON(queue: DispatchQueue.global(), completionHandler:
		{
			response in
			
			if let data = response.data
			{
				do
				{
					promise.fulfill(with: jsonParser(try JSON(data: data)))
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
				promise.fulfill(with: noDataResult())
			}
		})
		
		return promise
	}
}
