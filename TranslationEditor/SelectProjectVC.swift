//
//  SelectProjectVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TODO: Remove keyboard reactions if necessary, there's no input areas available

// This VC handles project selection (including accepting invitations to other people's projects)
class SelectProjectVC: UIViewController, LiveQueryListener, UITableViewDataSource, UITableViewDelegate, StackDismissable
{
	// TYPES	------------------
	
	typealias QueryTarget = ProjectView
	
	
	// OUTLETS	------------------
	
	@IBOutlet weak var projectTableView: UITableView!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var createProjectButton: BasicButton!
	@IBOutlet weak var topBar: TopBarUIView!
	
	
	// ATTRIBUTES	--------------
	
	private var queryManager: LiveQueryManager<QueryTarget>?
	private var projects = [Project]()
	// Language id -> language name
	private var languageNames = [String: String]()
	
	private var selectedWithSharedAccount = false
	
	
	// COMPUTED PROPERTIES	------
	
	var shouldDismissBelow: Bool { return selectedWithSharedAccount }
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		projectTableView.delegate = self
		projectTableView.dataSource = self
		
		topBar.configure(hostVC: self, title: "Select Project", leftButtonText: "Log Out")
		{
			Session.instance.logout()
			self.dismiss(animated: true, completion: nil)
		}
		topBar.connectionCompletionHandler = onConnectionDialogClose
		
		// If using a shared account, selects the project automatically
		guard let accountId = Session.instance.accountId else
		{
			print("ERROR: No logged account -> Cannot find any projects.")
			return
		}
		
		queryManager = ProjectView.instance.projectQuery(forContributorId: accountId).liveQueryManager
		queryManager?.addListener(AnyLiveQueryListener(self))
		
		contentView.configure(mainView: view, elements: [createProjectButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish)
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
		topBar.updateUserView()
		
		// If project is already selected, moves to the next view
		// Otherwise listens to project data changes
		if let projectId = Session.instance.projectId
		{
			// Checks whether this login should be considered shared
			do
			{
				selectedWithSharedAccount = try Project.get(projectId)?.sharedAccountId == Session.instance.accountId
			}
			catch
			{
				print("ERROR: Failed to read project data. \(error)")
			}
			
			performSegue(withIdentifier: "SelectAvatar", sender: nil)
		}
		else
		{
			queryManager?.start()
			contentView.startKeyboardListening()
		}
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		print("STATUS: Project view disappeared")
		
		contentView.endKeyboardListening()
		queryManager?.stop()
	}
    

	// ACTIONS	------------------
	
	@IBAction func createProjectPressed(_ sender: Any)
	{
		displayAlert(withIdentifier: "CreateProject", storyBoardId: "Login")
	}
	
	
	// IMPLEMENTED METHODS	------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return projects.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: ProjectCell.identifier, for: indexPath) as! ProjectCell
		
		let project = projects[indexPath.row]
		let languageName = languageNames[project.languageId].or("")
		
		cell.configure(name: project.name, languageName: languageName, created: Date(timeIntervalSince1970: project.created))
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Remembers the selected project and moves to the next view
		let project = projects[indexPath.row]
		Session.instance.projectId = project.idString
		performSegue(withIdentifier: "SelectAvatar", sender: nil)
	}
	
	func rowsUpdated(rows: [Row<ProjectView>])
	{
		// Updates the project data in the table
		do
		{
			projects = try rows.map { try $0.object() }
			
			for project in projects
			{
				if !languageNames.containsKey(project.languageId)
				{
					if let language = try Language.get(project.languageId)
					{
						languageNames[project.languageId] = language.name
					}
				}
			}
			
			projectTableView.reloadData()
		}
		catch
		{
			print("ERROR: Failed to read project data from DB. \(error)")
		}
		
		if let accountId = Session.instance.accountId
		{
			var selectedWithSharedAccount = false
			
			// Also checks if the user has logged in with a shared account for any of the projects
			// If so, proceeds with that project automatically
			for project in projects
			{
				if project.sharedAccountId == accountId
				{
					selectedWithSharedAccount = true
					Session.instance.projectId = project.idString
					performSegue(withIdentifier: "SelectAvatar", sender: nil)
					break
				}
			}
			
			self.selectedWithSharedAccount = selectedWithSharedAccount
		}
	}
	
	func willDissmissBelow()
	{
		print("STATUS: Project view will be dismissed from below")
		// Logs the user out before dimissing into login
		Session.instance.logout()
	}
	
	
	// OTHER METHODS	------------------
	
	private func onConnectionDialogClose()
	{
		if P2PClientSession.isConnected
		{
			do
			{
				guard let projectId = P2PClientSession.instance?.projectId, let project = try Project.get(projectId) else
				{
					return
				}
				
				// Makes sure the current user also has access to the project
				if let accountId = Session.instance.accountId
				{
					if !project.contributorIds.contains(accountId)
					{
						project.contributorIds.append(accountId)
						try project.push()
					}
				}
			}
			catch
			{
				print("ERROR: Failed to provide project access. \(error)")
			}
		}
	}
}
