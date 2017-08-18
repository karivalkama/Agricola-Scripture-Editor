//
//  QueryType.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 15.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// These are the different general types of queries used
enum QueryType
{
	// Object queries are used for retrieving object data
	case object
	// Reduce queries use the redice function and don't have any associated object data
	// (only works with views that support reduce)
	case reduce
	// No objects query doesn't use the reduce function, but isn't used for retrieving object data either
	// This query type should be used when row key and value are the primary concern
	// (it is a bit faster than object query)
	case noObjects
}
