//
//  AccountView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.3.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This view is used for retrieving user account data
final class AccountView: View
{
	// TYPES	----------------
	
	typealias Queried = AgricolaAccount
	typealias MyQuery = Query<AccountView>
	
	
	// ATTRIBUTES	------------
	
	static let instance = AccountView()
	
	static let KEY_NAME = "name"
	
	static let keyNames = [KEY_NAME]
	
	let view = DATABASE.viewNamed("account_view")
	
	
	// INIT	--------------------
	
	private init()
	{
		view.setMapBlock(createMapBlock
		{
			account, emit in
		
			// Key = key name version
			emit(account.username, nil)
			
		}, version: "3")
	}
	
	
	// OTHER METHODS	---------
	
	// Searches for an account with key name
	func accountQuery(name: String) -> MyQuery
	{
		return createQuery(withKeys: AccountView.makeKeys(from: [name]))
	}
}
