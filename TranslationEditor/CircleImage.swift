//
//  CircleImage.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 5.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// Circle images have completely rounded corners
class CircleImage: UIImageView
{
	override func layoutSubviews()
	{
		super.layoutSubviews()
		roundCorners(intensity: 1)
	}
}
