//
//  CCMore.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 03/04/17.
//  Copyright © 2017 TWS. All rights reserved.
//
//  Author Marino Faggiana <m.faggiana@twsweb.it>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


import UIKit

class CCMore: UIViewController, UITableViewDelegate, UITableViewDataSource, CCLoginDelegate, CCLoginDelegateWeb {

    @IBOutlet weak var themingBackground: UIImageView!
    @IBOutlet weak var themingAvatar: UIImageView!
    @IBOutlet weak var labelUsername: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var labelQuota: UILabel!
    @IBOutlet weak var labelQuotaExternalSite: UILabel!
    @IBOutlet weak var progressQuota: UIProgressView!

    var functionMenu = [OCExternalSites]()
    var externalSiteMenu = [OCExternalSites]()
    var settingsMenu = [OCExternalSites]()
    var quotaMenu = [OCExternalSites]()

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var listExternalSite: [tableExternalSites]?
    var tabAccount : tableAccount?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        appDelegate.activeMore = self
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.separatorColor = NCBrandColor.sharedInstance.seperator
        
        if #available(iOS 11, *) {
            //tableView.contentInsetAdjustmentBehavior = .never
        }
        
        themingBackground.image = #imageLiteral(resourceName: "themingBackground")
        
        // create tap gesture recognizer
        let tapQuota = UITapGestureRecognizer(target: self, action: #selector(tapLabelQuotaExternalSite))
        labelQuotaExternalSite.isUserInteractionEnabled = true
        labelQuotaExternalSite.addGestureRecognizer(tapQuota)
        
        let tapImageLogo = UITapGestureRecognizer(target: self, action: #selector(tapImageLogoManageAccount))
        themingBackground.isUserInteractionEnabled = true
        themingBackground.addGestureRecognizer(tapImageLogo)
        
        // Notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeTheming), name: NSNotification.Name(rawValue: "changeTheming"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeUserProfile), name: NSNotification.Name(rawValue: "changeUserProfile"), object: nil)
    }
    
    // Apparirà
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Clear
        functionMenu.removeAll()
        externalSiteMenu.removeAll()
        settingsMenu.removeAll()
        quotaMenu.removeAll()
        labelQuotaExternalSite.text = ""
        
        var item = OCExternalSites.init()

        // ITEM : Transfer
        item = OCExternalSites.init()
        item.name = "_transfers_"
        item.icon = "load"
        item.url = "segueTransfers"
        functionMenu.append(item)
        
        // ITEM : Activity
        item = OCExternalSites.init()
        item.name = "_activity_"
        item.icon = "activity"
        item.url = "segueActivity"
        functionMenu.append(item)
        
        // ITEM : Shares
        item = OCExternalSites.init()
        item.name = "_list_shares_"
        item.icon = "share"
        item.url = "segueShares"
        functionMenu.append(item)

        // ITEM : Scan
        if #available(iOS 11.0, *) {
            item = OCExternalSites.init()
            item.name = "_scanned_images_"
            item.icon = "scan"
            item.url = "Scanopen"
            functionMenu.append(item)
        }
        
        // ITEM : External
        
        if NCBrandOptions.sharedInstance.disable_more_external_site == false {
        
            listExternalSite = NCManageDatabase.sharedInstance.getAllExternalSites()
            
            if listExternalSite != nil {
                
                for table in listExternalSite! {
            
                    item = OCExternalSites.init()
            
                    item.name = table.name
                    item.url = table.url
                    item.icon = table.icon
            
                    if (table.type == "link") {
                        item.icon = "world"
                        externalSiteMenu.append(item)
                    }
                    if (table.type == "settings") {
                        item.icon = "settings"
                        settingsMenu.append(item)
                    }
                    if (table.type == "quota") {
                        quotaMenu.append(item)
                    }
                }
            }
        }
        
        // ITEM : Settings
        item = OCExternalSites.init()
        item.name = "_settings_"
        item.icon = "settings"
        item.url = "segueSettings"
        settingsMenu.append(item)
        
        if (quotaMenu.count > 0) {
            
            let item = quotaMenu[0]
            labelQuotaExternalSite.text = item.name
        }
        
        // User data & Theming
        changeUserProfile()
        changeTheming()
        
        // Title
        self.navigationItem.title = NSLocalizedString("_more_", comment: "")
        
        // Aspect
        appDelegate.aspectNavigationControllerBar(self.navigationController?.navigationBar, online: appDelegate.reachability.isReachable(), hidden: false)
        appDelegate.aspectTabBar(self.tabBarController?.tabBar, hidden: false)

        // +
        appDelegate.plusButtonVisibile(true)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @objc func changeTheming() {
        
        self.view.backgroundColor = NCBrandColor.sharedInstance.brand
        
        let fileNamePath = CCUtility.getDirectoryUserData() + "/" + CCUtility.getStringUser(appDelegate.activeUser, activeUrl: appDelegate.activeUrl) + "-themingBackground.png"
        
        if let theminBackgroundFile = UIImage.init(contentsOfFile: fileNamePath) {
            themingBackground.image = theminBackgroundFile
        } else {
            themingBackground.image = #imageLiteral(resourceName: "themingBackground")
        }
        
        if (self.isViewLoaded && (self.view.window != nil)) {
            appDelegate.changeTheming(self)
        }
    }
    
    @objc func changeUserProfile() {
     
        let fileNamePath = CCUtility.getDirectoryUserData() + "/" + CCUtility.getStringUser(appDelegate.activeUser, activeUrl: appDelegate.activeUrl) + "-avatar.png"
        var quota: String = ""
        
        if let themingAvatarFile = UIImage.init(contentsOfFile: fileNamePath) {
            themingAvatar.image = themingAvatarFile
        } else {
            themingAvatar.image = UIImage.init(named: "moreAvatar")
        }
        
        // Display Name user & Quota
        guard let tabAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            return
        }
        
        if tabAccount.displayName.isEmpty {
            labelUsername.text = tabAccount.user
        }
        else{
            labelUsername.text = tabAccount.displayName
        }
        
        // Shadow labelUsername TEST BLUR
        /*
        labelUsername.layer.shadowColor = UIColor.black.cgColor
        labelUsername.layer.shadowRadius = 4
        labelUsername.layer.shadowOpacity = 0.8
        labelUsername.layer.shadowOffset = CGSize(width: 0, height: 0)
        labelUsername.layer.masksToBounds = false
        */
        
        if (tabAccount.quotaRelative > 0) {
            progressQuota.progress = Float(tabAccount.quotaRelative) / 100
        } else {
            progressQuota.progress = 0
        }

        progressQuota.progressTintColor = NCBrandColor.sharedInstance.brandElement
        
        switch Double(tabAccount.quotaTotal) {
        case Double(k_quota_space_not_computed):
            quota = "0"
        case Double(k_quota_space_unknown):
            quota = NSLocalizedString("_quota_space_unknown_", comment: "")
        case Double(k_quota_space_unlimited):
            quota = NSLocalizedString("_quota_space_unlimited_", comment: "")
        default:
            quota = CCUtility.transformedSize(Double(tabAccount.quotaTotal))
        }
        
        let quotaUsed : String = CCUtility.transformedSize(Double(tabAccount.quotaUsed))
                
        labelQuota.text = String.localizedStringWithFormat(NSLocalizedString("_quota_using_", comment: ""), quotaUsed, quota)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if (externalSiteMenu.count == 0) {
            return 2
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if (section == 0) {
            return 0.1
        } else {
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var cont = 0
        
        // Menu Normal
        if (section == 0) {
            cont = functionMenu.count
        } else {
            switch (numberOfSections(in: tableView)) {
            case 2:
                // Menu Settings
                if (section == 1) {
                    cont = settingsMenu.count
                }
            case 3:
                // Menu External Site
                if (section == 1) {
                    cont = externalSiteMenu.count
                }
                // Menu Settings
                if (section == 2) {
                    cont = settingsMenu.count
                }
            default:
                cont = 0
            }
        }
        
        return cont
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CCCellMore
        var item: OCExternalSites = OCExternalSites.init()

        // change color selection and disclosure indicator
        let selectionColor : UIView = UIView.init()
        selectionColor.backgroundColor = NCBrandColor.sharedInstance.getColorSelectBackgrond()
        cell.selectedBackgroundView = selectionColor
        
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        
        // Menu Normal
        if (indexPath.section == 0) {
            
            item = functionMenu[indexPath.row]
            
        } else {
            
            // Menu External Site
            if (numberOfSections(in: tableView) == 3 && indexPath.section == 1) {
                
                item = externalSiteMenu[indexPath.row]
            }
            
            // Menu Settings
            if ((numberOfSections(in: tableView) == 2 && indexPath.section == 1) || (numberOfSections(in: tableView) == 3 && indexPath.section == 2)) {
                
                item = settingsMenu[indexPath.row]
            }
        }
        
        cell.imageIcon?.image = CCGraphics.changeThemingColorImage(UIImage.init(named: item.icon), multiplier: 2, color: NCBrandColor.sharedInstance.icon)
        cell.labelText?.text = NSLocalizedString(item.name, comment: "")
        cell.labelText.textColor = NCBrandColor.sharedInstance.textView
        
        return cell
    }

    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var item: OCExternalSites = OCExternalSites.init()
        
        // Menu Function
        if indexPath.section == 0 {
            item = functionMenu[indexPath.row]
        }
        
        // Menu External Site
        if (numberOfSections(in: tableView) == 3 && indexPath.section == 1) {
            item = externalSiteMenu[indexPath.row]
        }
        
        // Menu Settings
        if ((numberOfSections(in: tableView) == 2 && indexPath.section == 1) || (numberOfSections(in: tableView) == 3 && indexPath.section == 2)) {
            item = settingsMenu[indexPath.row]
        }
        
        // Action
        if item.url.contains("segue") && !item.url.contains("//") {
            
            self.navigationController?.performSegue(withIdentifier: item.url, sender: self)
        
        } else if item.url.contains("open") && !item.url.contains("//") {
            
            let nameStoryboard = String(item.url[..<item.url.index(item.url.startIndex, offsetBy: 4)])
            
            //let nameStoryboard = item.url.substring(from: item.url.index(item.url.startIndex, offsetBy: 4))
            
            let storyboard = UIStoryboard(name: nameStoryboard, bundle: nil)
            let controller = storyboard.instantiateInitialViewController()! //instantiateViewController(withIdentifier: nameStoryboard)
            self.present(controller, animated: true, completion: nil)
            
        } else if item.url.contains("//") {
            
            if (self.splitViewController?.isCollapsed)! {
                
                let webVC = SwiftWebVC(urlString: item.url, hideToolbar: false)
                webVC.delegate = self
                self.navigationController?.pushViewController(webVC, animated: true)
                self.navigationController?.navigationBar.isHidden = false
                
            } else {
                
                let webVC = SwiftModalWebVC(urlString: item.url, theme: .dark, color: UIColor.clear, colorText: UIColor.black, doneButtonVisible: true)
                webVC.delegateWeb = self
                self.present(webVC, animated: true, completion: nil)
            }
            
        } else if item.url == "logout" {
            
            let alertController = UIAlertController(title: "", message: NSLocalizedString("_want_delete_", comment: ""), preferredStyle: .alert)
            
            let actionYes = UIAlertAction(title: NSLocalizedString("_yes_delete_", comment: ""), style: .default) { (action:UIAlertAction) in
                
                let manageAccount = CCManageAccount()
                manageAccount.delete(self.appDelegate.activeAccount)
                
                self.appDelegate.openLoginView(self, loginType: Int(k_login_Add_Forced), selector: Int(k_intro_login))
            }
            
            let actionNo = UIAlertAction(title: NSLocalizedString("_no_delete_", comment: ""), style: .default) { (action:UIAlertAction) in
                print("You've pressed No button");
            }
            
            alertController.addAction(actionYes)
            alertController.addAction(actionNo)
            self.present(alertController, animated: true, completion:nil)
        }
    }
    
    @objc func tapLabelQuotaExternalSite() {
        
        if (quotaMenu.count > 0) {
            
            let item = quotaMenu[0]
            
            if (self.splitViewController?.isCollapsed)! {
                
                let webVC = SwiftWebVC(urlString: item.url, hideToolbar: true)
                webVC.delegate = self
                self.navigationController?.pushViewController(webVC, animated: true)
                self.navigationController?.navigationBar.isHidden = false
                
            } else {
                
                let webVC = SwiftModalWebVC(urlString: item.url)
                webVC.delegateWeb = self
                self.present(webVC, animated: true, completion: nil)
            }
        }
    }
    
    @objc func tapImageLogoManageAccount() {
        
        let controller = CCManageAccount.init()
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func loginSuccess(_ loginType: NSInteger) {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "initializeMain"), object: nil, userInfo: nil)
        
        appDelegate.selectedTabBarController(Int(k_tabBarApplicationIndexFile))
        
        appDelegate.subscribingNextcloudServerPushNotification()
    }
}

extension CCMore: SwiftModalWebVCDelegate, SwiftWebVCDelegate{
    
    public func didStartLoading() {
        print("Started loading.")
    }
    
    public func didReceiveServerRedirectForProvisionalNavigation(url: URL) {
        
        let urlString: String = url.absoluteString.lowercased()
        
        // Protocol close webVC
        if (urlString.contains(NCBrandOptions.sharedInstance.webCloseViewProtocolPersonalized) == true) {
            
            if (self.presentingViewController != nil) {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    public func didFinishLoading(success: Bool) {
        print("Finished loading. Success: \(success).")
    }
    
    public func didFinishLoading(success: Bool, url: URL) {
        print("Finished loading. Success: \(success).")
    }
    
    public func decidePolicyForNavigationAction(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    public func webDismiss() {
        print("Web dismiss.")
    }
}

class CCCellMore: UITableViewCell {
    
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var imageIcon: UIImageView!
}
