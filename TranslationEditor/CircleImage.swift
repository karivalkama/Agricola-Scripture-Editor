//
//  CircleImage.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 5.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// Circle images have completely rounded corners
class CircleImage: UIImageView
{
	override func layoutSubviews()
	{
		super.layoutSubviews()
		layer.cornerRadius = (self.frame.width + self.frame.height) / 4
		clipsToBounds = true
	}
}
