//
//  OpenThreadStatusListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes conforming to this protocol are interested to receive changes in open thread status
protocol OpenThreadListener: class
{
	// This method will be called when thread contents are updated
	// The status is as follows: path id -> path contains open threads for the resource (specified by resourceId)
	func onThreadStatusUpdated(forResouceId resourceId: String, status: [String: Bool])
}
