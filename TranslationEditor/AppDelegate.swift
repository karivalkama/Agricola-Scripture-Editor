//
//  AppDelegate.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
	{
		// Override point for customization after application launch.
		// TODO: Setup database and start replication process
		
		let navigationBarAppearance = UINavigationBar.appearance()
		let barTheme = Themes.Primary.secondary
		
		navigationBarAppearance.tintColor = barTheme.textColour
		navigationBarAppearance.barTintColor = barTheme.colour
		navigationBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName : barTheme.textColour]
		
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
