//
//  ColorUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

extension UIColor
{
	/*
	convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0)
	{
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")
		
		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
	}
	
	convenience init(netHex:Int)
	{
		self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
	}*/
	
	convenience init(hexString: String, alpha: CGFloat = 1.0)
	{
		var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		
		if (cString.hasPrefix("#"))
		{
			cString.remove(at: cString.startIndex)
		}
		
		if ((cString.characters.count) != 6)
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
