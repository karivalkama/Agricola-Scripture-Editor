//
//  AppDelegate.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
	{
		// Chooses the database to use
		useDatabase(named: "agricola")
		
		// Starts synchronization process (test)
		ConnectionManager.instance.registerListener(ConnectionStatusLogger())
		//ConnectionManager.instance.connect(serverURL: "http://192.168.1.107:4984")
		
		// Updates navigation bar visuals
		let navigationBarAppearance = UINavigationBar.appearance()
		let barTheme = Themes.Primary.secondary
		
		navigationBarAppearance.tintColor = barTheme.textColour
		navigationBarAppearance.barTintColor = barTheme.colour
        navigationBarAppearance.titleTextAttributes = [NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue) : barTheme.textColour]
		
		// Sets up the conflict handler
		ConflictResolver.instance.addMerger
		{
			paragraphs -> Paragraph in
			
			// If any of the paragraphs is the most recent, the merged is too
			let isMostRecent = paragraphs.contains(where: { $0.isMostRecent })
			
			// If any of the paragraphs is not deprecated, the merged isn't either
			let isDeprecated = paragraphs.forAll { $0.isDeprecated }
			
			// Other properties should stay the same (taken from the first paragraph)
			let merged = paragraphs.first!
			merged.isDeprecated = isDeprecated
			merged.isMostRecent = isMostRecent
			
			return merged
		}
		
		print("STATUS: Solved \(ConflictResolver.instance.run()) conflicts")
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication)
	{
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication)
	{
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		AppStatusHandler.instance.appWillClose()
	}

	func applicationWillEnterForeground(_ application: UIApplication)
	{
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
		AppStatusHandler.instance.appWillContinue()
	}

	func applicationDidBecomeActive(_ application: UIApplication)
	{
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication)
	{
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		AppStatusHandler.instance.appWillClose()
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
	{
//		print("STATUS: Received URL: \(url)")
//		USXImport.instance.open(url: url)
		
		// If a session is open, displays the USX import view
		/*
		var didPresentController = false
		if Session.instance.avatarId != nil && Session.instance.projectId != nil
		{
			if let controller = UIStoryboard(name: "MainMenu", bundle: nil).instantiateViewController(withIdentifier: "ImportUSX") as? ImportUSXVC
			{
				if let window = self.window, let rootViewController = window.rootViewController
				{
					var currentController = rootViewController
					while let presentedController = currentController.presentedViewController
					{
						currentController = presentedController
					}
					
					didPresentController = true
					controller.configure(usxFileURL: url)
					currentController.present(controller, animated: true, completion: nil)
				}
			}
		}
		
		// Otherwise stores the url until user has logged in
		if (!didPresentController)
		{
			USXImportStack.instance.push(url)
		}
		*/
		
		return true
	}
}

class AppStatusHandler
{
	// PROPERTIES	-------
	
	static let instance = AppStatusHandler()
	
	private var listeners = [AppStatusListener]()
	
	
	// INIT	---------------
	
	private init() {}
	
	
	// OTHER METHODS	---
	
	func registerListener(_ listener: AppStatusListener)
	{
		if !listeners.contains(where: { $0 === listener })
		{
			listeners.append(listener)
		}
	}
	
	func removeListener(_ listener: AppStatusListener)
	{
		listeners = listeners.filter({ $0 === listener })
	}
	
	fileprivate func appWillContinue()
	{
		listeners.forEach { $0.appWillContinue() }
	}
	
	fileprivate func appWillClose()
	{
		listeners.forEach { $0.appWillClose() }
	}
}
