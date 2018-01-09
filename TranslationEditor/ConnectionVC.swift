//
//  ConnectionVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This view controller is used for setting up peer to peer connection and for exporting USX files
class ConnectionVC: UIViewController
{
	// OUTLETS	----------------
	
	@IBOutlet weak var connectionView: ConnectionUIView!
	
	
	// ATTRIBUTES	------------
	
	static let identifier = "ConnectionVC"
	
	private var completionHandler: (() -> ())?
	
	
	// LOAD	--------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		connectionView.viewController = self
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		ConnectionManager.instance.registerListener(connectionView)
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		ConnectionManager.instance.removeListener(connectionView)
	}

	
	// ACTIONS	----------------
	
	@IBAction func closeButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: completionHandler)
	}
	
	@IBAction func backgroundButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: completionHandler)
	}
	
	
	// OTHER METHODS	-------
	
	func configure(completion: @escaping () -> ())
	{
		self.completionHandler = completion
	}
}
