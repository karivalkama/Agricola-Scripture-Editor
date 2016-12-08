//
//  CellContentListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation
import UIKit

// TODO: Refactor
@available(*, deprecated) // Please use cellInputListener instead
protocol CellContentListener
{
	// This function is called each time cell content is changed but not when cell content is initialised for the first time
	func cellContentChanged(in cell: UITableViewCell)
}
