//
//  SelectProjectVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This VC handles project selection (including accepting invitations to other people's projects)
class SelectProjectVC: UIViewController, LiveQueryListener, UITableViewDataSource
{
	// TYPES	------------------
	
	typealias QueryTarget = ProjectView
	
	
	// OUTLETS	------------------
	
	@IBOutlet weak var projectTableView: UITableView!
	
	
	// ATTRIBUTES	--------------
	
	private let queryManager = ProjectView.instance.projectQuery(forContributorId: Session.instance.accountId!).liveQueryManager
	private var projects = [Project]()
	private var listening = false
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
		// If project is already selected, moves to the next view
		// Otherwise listens to project data changes
		if Session.instance.projectId == nil
		{
			if !listening
			{
				queryManager.addListener(AnyLiveQueryListener(self))
				queryManager.start()
				listening = true
			}
		}
		else
		{
			if listening
			{
				queryManager.removeListeners()
				queryManager.stop()
				listening = false
			}
			
			performSegue(withIdentifier: "SelectAvatar", sender: nil)
		}
	}
    

	// ACTIONS	------------------
	
	@IBAction func logoutButtonPressed(_ sender: Any)
	{
		// Ends the session and returns to login
		Session.instance.logout()
		dismiss(animated: true, completion: nil)
	}
	
	
	// IMPLEMENTED METHODS	------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return projects.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: ProjectCell.identifier, for: indexPath) as! ProjectCell
		
		do
		{
			let project = projects[indexPath.row]
			let languageName = try Language.get(project.languageId)?.name
			
			if languageName == nil
			{
				print("ERROR: No language data for project \(project.toPropertySet)")
			}
			
			cell.configure(name: project.name, languageName: languageName.or(""), created: Date(timeIntervalSince1970: project.created))
		}
		catch
		{
			print("ERROR: Failed to set up a project cell. \(error)")
		}
			
		return cell
	}
	
	func rowsUpdated(rows: [Row<ProjectView>])
	{
		do
		{
			projects = try rows.map { try $0.object() }
			projectTableView.reloadData()
		}
		catch
		{
			print("ERROR: Failed to read project data from DB. \(error)")
		}
	}
}
