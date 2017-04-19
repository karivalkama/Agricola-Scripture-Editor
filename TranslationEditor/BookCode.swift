//
//  BookCode.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 19.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These are the different book codes available in the editor
enum BookCode: Comparable, CustomStringConvertible
{
	// OPTIONS	------------------
	
	case genesis, exodus, leviticus, numbers, deuteronomy, joshua, judges, ruth, samuel1, samuel2, kings1, kings2, chronicles1, chronicles2, ezra, nehemiah, ester, job, psalms, proverbs, ecclesiastes, songOfSongs, isaiah, jeremiah, lamentations, ezekiel, daniel, hosea, joel, amos, obadiah, jonah, micah, nahum, habakkuk, zephaniah, haggai, zechariah, malachi, matthew, mark, luke, john, acts, romans, corinthians1, corinthians2, galatians, ephesians, philippians, colossians, thessalonians1, thessalonians2, timothy1, timothy2, titus, philemon, hebrews, james, peter1, peter2, john1, john2, john3, jude, revelation, other(code: String)
	
	
	// ATTRIBUTES	--------------
	
	static let oldTestamentBooks = [genesis, exodus, leviticus, numbers, deuteronomy, joshua, judges, ruth, samuel1, samuel2, kings1, kings2, chronicles1, chronicles2, ezra, nehemiah, ester, job, psalms, proverbs, ecclesiastes, songOfSongs, isaiah, jeremiah, lamentations, ezekiel, daniel, hosea, joel, amos, obadiah, jonah, micah, nahum, habakkuk, zephaniah, haggai, zechariah, malachi]
	
	static let newTestamentBooks = [matthew, mark, luke, john, acts, romans, corinthians1, corinthians2, galatians, ephesians, philippians, colossians, thessalonians1, thessalonians2, timothy1, timothy2, titus, philemon, hebrews, james, peter1, peter2, john1, john2, john3, jude, revelation]
	
	private static let codeMap = makeCodeMap()
	
	
	// COMPUTED PROPERTIES	------
	
	var description: String { return name }
	
	var code: String
	{
		switch self
		{
		case .genesis: return "GEN"
		case .exodus: return "EXO"
		case .leviticus: return "LEV"
		case .numbers: return "NUM"
		case .deuteronomy: return "DEU"
		case .joshua: return "JOS"
		case .judges: return "JDG"
		case .ruth: return "RUT"
		case .samuel1: return "1SA"
		case .samuel2: return "2SA"
		case .kings1: return "1KI"
		case .kings2: return "2KI"
		case .chronicles1: return "1CH"
		case .chronicles2: return "2CH"
		case .ezra: return "EZR"
		case .nehemiah: return "NEH"
		case .ester: return "EST"
		case .job: return "JOB"
		case .psalms: return "PSA"
		case .proverbs: return "PRO"
		case .ecclesiastes: return "ECC"
		case .songOfSongs: return "SNG"
		case .isaiah: return "ISA"
		case .jeremiah: return "JER"
		case .lamentations: return "LAM"
		case .ezekiel: return "EZK"
		case .daniel: return "DAN"
		case .hosea: return "HOS"
		case .joel: return "JOL"
		case .amos: return "AMO"
		case .obadiah: return "OBA"
		case .jonah: return "JON"
		case .micah: return "MIC"
		case .nahum: return "NAM"
		case .habakkuk: return "HAB"
		case .zephaniah: return "ZEP"
		case .haggai: return "HAG"
		case .zechariah: return "ZEC"
		case .malachi: return "MAL"
		case .matthew: return "MAT"
		case .mark: return "MRK"
		case .luke: return "LUK"
		case .john: return "JHN"
		case .acts: return "ACT"
		case .romans: return "ROM"
		case .corinthians1: return "1CO"
		case .corinthians2: return "2CO"
		case .galatians: return "GAL"
		case .ephesians: return "EPH"
		case .philippians: return "PHP"
		case .colossians: return "COL"
		case .thessalonians1: return "1TH"
		case .thessalonians2: return "2TH"
		case .timothy1: return "1TI"
		case .timothy2: return "2TI"
		case .titus: return "TIT"
		case .philemon: return "PHM"
		case .hebrews: return "HEB"
		case .james: return "JAS"
		case .peter1: return "1PE"
		case .peter2: return "2PE"
		case .john1: return "1JN"
		case .john2: return "2JN"
		case .john3: return "3JN"
		case .jude: return "JUD"
		case .revelation: return "REV"
		case .other(let code): return code
		}
	}
	
	var name: String
	{
		switch self
		{
		case .genesis: return "Genesis"
		case .exodus: return "Exodus"
		case .leviticus: return "Leviticus"
		case .numbers: return "Numbers"
		case .deuteronomy: return "Deuteronomy"
		case .joshua: return "Joshua"
		case .judges: return "Judges"
		case .ruth: return "Ruth"
		case .samuel1: return "1. Samuel"
		case .samuel2: return "2. Samuel"
		case .kings1: return "1. Kings"
		case .kings2: return "2. Kings"
		case .chronicles1: return "1. Chornicles"
		case .chronicles2: return "2. Chronicles"
		case .ezra: return "Ezra"
		case .nehemiah: return "Nehemiah"
		case .ester: return "Ester"
		case .job: return "Job"
		case .psalms: return "Psalms"
		case .proverbs: return "Proverbs"
		case .ecclesiastes: return "Ecclesiastes"
		case .songOfSongs: return "Song of Songs"
		case .isaiah: return "Isaiah"
		case .jeremiah: return "Jeremiah"
		case .lamentations: return "Lamentations"
		case .ezekiel: return "Ezekiel"
		case .daniel: return "Daniel"
		case .hosea: return "Hosea"
		case .joel: return "Joel"
		case .amos: return "Amos"
		case .obadiah: return "Obadiah"
		case .jonah: return "Jonah"
		case .micah: return "Micah"
		case .nahum: return "Nahum"
		case .habakkuk: return "Habakkuk"
		case .zephaniah: return "Zephaniah"
		case .haggai: return "Haggai"
		case .zechariah: return "Zechariah"
		case .malachi: return "Malachi"
		case .matthew: return "Matthew"
		case .mark: return "Mark"
		case .luke: return "Luke"
		case .john: return "John"
		case .acts: return "Acts"
		case .romans: return "Romans"
		case .corinthians1: return "1. Corinthians"
		case .corinthians2: return "2. Corinthians"
		case .galatians: return "Galatians"
		case .ephesians: return "Ephesians"
		case .philippians: return "Philippians"
		case .colossians: return "Colossians"
		case .thessalonians1: return "1. Thessalonians"
		case .thessalonians2: return "2. Thessalonians"
		case .timothy1: return "1. Timothy"
		case .timothy2: return "2. Timothy"
		case .titus: return "Titus"
		case .philemon: return "Philemon"
		case .hebrews: return "Hebrew"
		case .james: return "James"
		case .peter1: return "1. Peter"
		case .peter2: return "2. Peter"
		case .john1: return "1. John"
		case .john2: return "2. John"
		case .john3: return "3. John"
		case .jude: return "Jude"
		case .revelation: return "Revelation"
		case .other(let code): return "Other (\(code))"
		}
	}
	
	// Whether this book is part of the old testament
	var isOldTestamentBook: Bool { return BookCode.oldTestamentBooks.contains(self) }
	
	// Whether this book is part of the new testament
	var isNewTestamentBook: Bool { return BookCode.newTestamentBooks.contains(self) }
	
	// The index of the book which determines the ordering of the books
	var index: Int
	{
		if let oldTestamentIndex = BookCode.oldTestamentBooks.index(of: self)
		{
			return oldTestamentIndex
		}
		else if let newTestamentIndex = BookCode.newTestamentBooks.index(of: self)
		{
			return BookCode.oldTestamentBooks.count + newTestamentIndex
		}
		else
		{
			return BookCode.oldTestamentBooks.count + BookCode.newTestamentBooks.count
		}
	}
	
	
	// IMPLEMENTED METHODS	--------
	
	static func ==(_ left: BookCode, _ right: BookCode) -> Bool
	{
		return left.code == right.code
	}
	
	static func <(_ left: BookCode, _ right: BookCode) -> Bool
	{
		switch left
		{
		case other(let code):
			let leftIndex = left.index
			let rightIndex = right.index
			
			if leftIndex == rightIndex
			{
				return code < right.code
			}
			else
			{
				return leftIndex < rightIndex
			}
		default: return left.index < right.index
		}
	}
	
	
	// OTHER METHODS	------------
	
	static func of(code: String) -> BookCode
	{
		return codeMap[code.lowercased()].or(.other(code: code.uppercased()))
	}
	
	private static func makeCodeMap() -> [String: BookCode]
	{
		var codes = [String: BookCode]()
		oldTestamentBooks.forEach { codes[$0.code.lowercased()] = $0 }
		newTestamentBooks.forEach { codes[$0.code.lowercased()] = $0 }
		
		return codes
	}
}
