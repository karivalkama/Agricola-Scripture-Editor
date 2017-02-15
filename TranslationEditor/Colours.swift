//
//  Colours.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These are the main colours used in the project
/*
enum MaterialColour
{
	enum Main: String
	{
		case test: "asd"
	}
}*/

protocol UIColorConvertible
{
	var asColour: UIColor {get}
}

enum Colour
{
	enum Primary: String, UIColorConvertible
	{
		case normal = "#FF9800"
		case dark = "#EF6C00"
		case light = "#FFCC80"
		
		var asColour: UIColor {return UIColor(hexString: rawValue)}
		static var asColour: UIColor {return normal.asColour}
	}
	enum Secondary: String, UIColorConvertible
	{
		case normal = "#FF1744"
		case dark = "#D50000"
		case light = "#FF8A80"
		
		var asColour: UIColor {return UIColor(hexString: rawValue)}
		static var asColour: UIColor {return normal.asColour}
	}
	enum Text
	{
		enum Black: CGFloat, UIColorConvertible
		{
			case primary = 0.87
			case secondary = 0.54
			case disabled = 0.38
			
			var asColour: UIColor {return UIColor(white: 0.0, alpha: rawValue)}
			static var asColour: UIColor {return primary.asColour}
		}
		enum White: CGFloat
		{
			case primary = 1.0
			case secondary = 0.7
			case disabled = 0.5
			
			var asColour: UIColor {return UIColor(white: 1.0, alpha: rawValue)}
			static var asColour: UIColor {return primary.asColour}
		}
	}
}
