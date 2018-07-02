//
//  DataNotFoundError.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.7.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These error are thrown when expected data is unavailable when reading from a source
struct DataNotFoundError: Error
{
	let message: String
}
