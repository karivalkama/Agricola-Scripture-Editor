//
//  AccountView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
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
	
	static let KEY_DISPLAYNAME = "display_name"
	static let KEY_KEYNAME = "name_key"
	
	static let keyNames = [KEY_KEYNAME, KEY_DISPLAYNAME]
	
	let view = DATABASE.viewNamed("account_view")
	
	
	// INIT	--------------------
	
	private init()
	{
		view.setMapBlock(createMapBlock
		{
			account, emit in
		
			// Key = key name version + display name
			emit([account.cbUserName, account.displayName], nil)
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	---------
	
	// Creates a query for retrieving account data (should return a single account only)
	func accountQuery(displayName: String) -> MyQuery
	{
		return createQuery(withKeys: [AccountView.KEY_KEYNAME: Key(displayName.toKey), AccountView.KEY_DISPLAYNAME: Key(displayName)])
	}
	
	// Searches for an account with key name only (may return multiple accounts)
	func accountQuery(nameKey: String) -> MyQuery
	{
		return createQuery(withKeys: [AccountView.KEY_KEYNAME: Key(nameKey), AccountView.KEY_DISPLAYNAME: Key.undefined])
	}
}
