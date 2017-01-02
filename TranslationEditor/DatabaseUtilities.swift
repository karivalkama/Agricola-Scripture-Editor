//
//  DatabaseUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate var _database: CBLDatabase?
// The database used in the project
var DATABASE: CBLDatabase
{
	if _database == nil
	{
		_database = try! CBLManager.sharedInstance().databaseNamed("agricola")
	}
	
	return _database!
}

let ID_SEPARATOR = "/"

let PROPERTY_TYPE = "type"

func parseId(from array: [Any]) -> String
{
	if (array.isEmpty)
	{
		return ""
	}
	else
	{
		return array.dropFirst().reduce("\(array.first!)".lowercased()) {(current, part) in return current + ID_SEPARATOR + "\(part)".lowercased()}
	}
}
