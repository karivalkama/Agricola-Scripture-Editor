//
//  ParatextProject.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.7.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These structs are used for describing projects on paratext side
struct ParatextProject
{
	// Paratext uid
	let id: String
	// Name in paratext
	let name: String
	// Shorter version of name
	let shortName: String
	// Descritption (may be empty)
	let description: String
}
