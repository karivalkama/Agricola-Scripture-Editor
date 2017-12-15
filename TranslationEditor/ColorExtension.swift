//
//  ColorUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

extension UIColor
{
	convenience init(hexString: String, alpha: CGFloat = 1.0)
	{
		var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		
		if (cString.hasPrefix("#"))
		{
			cString.remove(at: cString.startIndex)
		}
		
		if ((cString.count) != 6)
		{
			self.init(red: 0, green: 0, blue: 0, alpha: alpha)
		}
		else
		{
			var rgbValue:UInt32 = 0
			Scanner(string: cString).scanHexInt32(&rgbValue)
			
			self.init(
				red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
				green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
				blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
				alpha: alpha
			)
		}
	}
}
