//
//  Theme.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

protocol Theme
{
	var colour: UIColor {get}
	var textColour: UIColor {get}
}

enum Themes
{
	enum Primary: Theme
	{
		case normal
		case secondary
		case disabled
		
		var colour: UIColor
		{
			switch self
			{
			case .normal: return Colour.Primary.asColour
			case .secondary: return Colour.Primary.dark.asColour
			case .disabled: return Colour.Primary.light.asColour
			}
		}
		
		var textColour: UIColor
		{
			switch self
			{
			case .normal: return Colour.Text.Black.asColour
			case .secondary: return Colour.Text.White.asColour
			case .disabled: return Colour.Text.Black.disabled.asColour
			}
		}
	}
	enum Accessory: Theme
	{
		case normal
		case secondary
		case disabled
		
		var colour: UIColor
		{
			switch self
			{
			case .normal: return Colour.Secondary.asColour
			case .secondary: return Colour.Secondary.dark.asColour
			case .disabled: return Colour.Secondary.light.asColour
			}
		}
		
		var textColour: UIColor
		{
			switch self
			{
			case .normal: return Colour.Text.White.asColour
			case .secondary: return Colour.Text.White.asColour
			case .disabled: return Colour.Text.Black.disabled.asColour
			}
		}
	}
}
