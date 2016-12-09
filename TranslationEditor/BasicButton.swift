//
//  BasicButton.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This is the base class for basic UI buttons
// The class handles basic colour scheme for enabled and disabled buttons
class BasicButton: UIButton
{
	// PROPERTIES	-----------
	
	override var isEnabled: Bool
	{
		get {return super.isEnabled}
		set {super.isEnabled = newValue}
	}
	
	
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
