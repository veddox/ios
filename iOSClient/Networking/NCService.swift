//
//  NCService.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/03/18.
//  Copyright © 2018 TWS. All rights reserved.
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

import Foundation

class NCService: NSObject, OCNetworkingDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @objc static let sharedInstance: NCService = {
        let instance = NCService()
        return instance
    }()
    
    //MARK: -
    //MARK: Start Services API NC
    
    @objc public func startRequestServicesServer() {
   
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        self.requestUserProfile()
        self.requestServerCapabilities()
        self.requestActivityServer()
        self.requestServerStatus()
    }

    //MARK: -
    //MARK: Internal request Service API NC
    
    private func requestServerCapabilities() {
        
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        guard let metadataNet = CCMetadataNet.init(account: appDelegate.activeAccount) else {
            return
        }
        
        metadataNet.action = actionGetCapabilities
        appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }
    
    private func requestUserProfile() {
        
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        guard let metadataNet = CCMetadataNet.init(account: appDelegate.activeAccount) else {
            return
        }
        
        metadataNet.action = actionGetUserProfile
        appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }
    
    private func requestActivityServer() {
        
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        guard let metadataNet = CCMetadataNet.init(account: appDelegate.activeAccount) else {
            return
        }
        
        metadataNet.action = actionGetActivityServer
        appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }
    
    @objc public func middlewarePing() {
        
        if (appDelegate.activeAccount == nil || appDelegate.activeAccount.count == 0 || appDelegate.maintenanceMode == true) {
            return
        }
        
        guard let metadataNet = CCMetadataNet.init(account: appDelegate.activeAccount) else {
            return
        }
        
        metadataNet.action = actionMiddlewarePing
        metadataNet.serverUrl = NCBrandOptions.sharedInstance.middlewarePingUrl
        
        //appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
    }
    
    private func requestServerStatus() {

        let ocNetworking = OCnetworking.init(delegate: self, metadataNet: nil, withUser: appDelegate.activeUser, withUserID: appDelegate.activeUserID, withPassword: appDelegate.activePassword, withUrl: appDelegate.activeUrl)
        ocNetworking?.serverStatus(appDelegate.activeUrl, success: { (serverProductName, versionMajor, versionMicro, versionMinor) in
            
            if serverProductName == "owncloud" {
                self.appDelegate.messageNotification("_warning_", description: "_warning_owncloud_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: Int(k_CCErrorInternalError))
            } else if versionMajor <= k_nextcloud_unsupported {
                self.appDelegate.messageNotification("_warning_", description: "_warning_unsupported_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: Int(k_CCErrorInternalError))
            }
            
        }, failure: { (message, errorCode) in
            //
        })
    }
    
    //MARK: -
    //MARK: Delegate Service API NC
    
    func getCapabilitiesOfServerSuccessFailure(_ metadataNet: CCMetadataNet!, capabilities: OCCapabilities?, message: String?, errorCode: Int) {
        
        // Check Active Account
        if (metadataNet.account != appDelegate.activeAccount) {
            return
        }
        
        if (errorCode == 0) {
            
            // Update capabilities db
            NCManageDatabase.sharedInstance.addCapabilities(capabilities!)
            
            // ------ THEMING -----------------------------------------------------------------------
            
            if (NCBrandOptions.sharedInstance.use_themingBackground && capabilities!.themingBackground != "") {
                
                // Download Theming Background & Change Theming color
                DispatchQueue.global().async {
                
                    let address = capabilities!.themingBackground!.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
                    let fileNamePath = CCUtility.getDirectoryUserData() + "/" + CCUtility.getStringUser(self.appDelegate.activeUser, activeUrl: self.appDelegate.activeUrl) + "-themingBackground.png"

                    guard let imageData = try? Data(contentsOf: URL(string: address)!) else {
                        DispatchQueue.main.async {
                            self.appDelegate.settingThemingColorBrand()
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        
                        guard let image = UIImage(data: imageData) else {
                            try? FileManager.default.removeItem(atPath: fileNamePath)
                            self.appDelegate.settingThemingColorBrand()
                            return
                        }
                    
                        if let data = UIImagePNGRepresentation(image) {
                            try? data.write(to: URL(fileURLWithPath: fileNamePath))
                        }
                    
                        self.appDelegate.settingThemingColorBrand()
                    }
                }
                
            } else {
                
                self.appDelegate.settingThemingColorBrand()
            }
            
            // ------ SEARCH ------------------------------------------------------------------------
            
            if (NCManageDatabase.sharedInstance.getServerVersion() != capabilities!.versionMajor && appDelegate.activeMain != nil) {
                appDelegate.activeMain.cancelSearchBar()
            }
            
            // ------ GET OTHER SERVICE -------------------------------------------------------------

            // Read Notification
            if (capabilities!.isNotificationServerEnabled) {
                
                metadataNet.action = actionGetNotificationServer
                appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
                
            } else {
                
                // Remove all Notification
                self.appDelegate.listOfNotifications.removeAllObjects()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationReloadData"), object: nil)
                // Update Main NavigationBar
                if (appDelegate.activeMain != nil && self.appDelegate.activeMain.isSelectedMode == false) {
                    self.appDelegate.activeMain.setUINavigationBarDefault()
                }
            }
            
            // Read External Sites
            if (capabilities!.isExternalSitesServerEnabled) {
                
                metadataNet.action = actionGetExternalSitesServer
                appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: self, metadataNet: metadataNet)
                
            } else {
                
                NCManageDatabase.sharedInstance.deleteExternalSites()
            }
            
            // Read Share
            if (capabilities!.isFilesSharingAPIEnabled && appDelegate.activeMain != nil) {
                
                appDelegate.sharesID.removeAllObjects()
                metadataNet.action = actionReadShareServer
                appDelegate.addNetworkingOperationQueue(appDelegate.netQueue, delegate: appDelegate.activeMain, metadataNet: metadataNet)
            }
            
        } else {
            
            // Change Theming color
            appDelegate.settingThemingColorBrand()
            
            var error = ""
            if let message = message {
                error = "Get Capabilities failure error \(errorCode) \(message)"
            } else {
                error = "Get Capabilities failure error \(errorCode)"
            }
                        
            NCManageDatabase.sharedInstance.addActivityClient("", fileID: "", action: k_activityDebugActionCapabilities, selector: "Get Capabilities of Server", note: error, type: k_activityTypeFailure, verbose: true, activeUrl: appDelegate.activeUrl)
        }
    }
    
   func getUserProfileSuccessFailure(_ metadataNet: CCMetadataNet!, userProfile: OCUserProfile?, message: String?, errorCode: Int) {
        
        // Check Active Account
        if (metadataNet.account != appDelegate.activeAccount) {
            return
        }
        
        if (errorCode == 0) {
            
            // Update User (+ userProfile.id) & active account & account network
            guard let tableAccount = NCManageDatabase.sharedInstance.setAccountUserProfile(userProfile!) else {
                appDelegate.messageNotification("Accopunt", description: "Internal error : account not found on DB", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: Int(k_CCErrorInternalError))
                return
            }
            
            let user = tableAccount.user
            let url = tableAccount.url
            
            CCNetworking.shared().settingAccount()
            appDelegate.settingActiveAccount(tableAccount.account, activeUrl: tableAccount.url, activeUser: tableAccount.user, activeUserID: tableAccount.userID, activePassword: tableAccount.password)
            
            // Call func thath required the userdID
            appDelegate.activeFavorites.listingFavorites()
            appDelegate.activeMedia.searchPhotoVideo()
            
            DispatchQueue.global(qos: .default).async {
                
                let address = "\(self.appDelegate.activeUrl!)/index.php/avatar/\(self.appDelegate.activeUser!)/128".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
                let fileNamePath = CCUtility.getDirectoryUserData() + "/" + CCUtility.getStringUser(user, activeUrl: url) + "-avatar.png"
                
                guard let imageData = try? Data(contentsOf: URL(string: address)!) else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeUserProfile"), object: nil)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    
                    guard let image = UIImage(data: imageData) else {
                        try? FileManager.default.removeItem(atPath: fileNamePath)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeUserProfile"), object: nil)
                        return
                    }
                
                    if let data = UIImagePNGRepresentation(image) {
                        try? data.write(to: URL(fileURLWithPath: fileNamePath))
                    }
                
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "changeUserProfile"), object: nil)
                }
            }
            
        } else {
            
            var error = ""
            if let message = message {
                error = "Get user profile failure error \(errorCode) \(message)"
            } else {
                error = "Get user profile failure error \(errorCode)"
            }
            
            NCManageDatabase.sharedInstance.addActivityClient("", fileID: "", action: k_activityDebugActionCapabilities, selector: "Get user profile Server", note: error, type: k_activityTypeFailure, verbose: true, activeUrl: appDelegate.activeUrl)
        }
    }
    
    func getExternalSitesServerSuccessFailure(_ metadataNet: CCMetadataNet!, listOfExternalSites: [Any]?, message: String?, errorCode: Int) {
        
        // Check Active Account
        if (metadataNet.account != appDelegate.activeAccount) {
            return
        }
        
        if (errorCode == 0) {
            
            NCManageDatabase.sharedInstance.deleteExternalSites()
            for externalSites in listOfExternalSites! {
                NCManageDatabase.sharedInstance.addExternalSites(externalSites as! OCExternalSites)
            }
            
        } else {
         
            var error = ""
            if let message = message {
                error = "Get external site failure error \(errorCode) \(message)"
            } else {
                error = "Get external site failure error \(errorCode)"
            }
            
            NCManageDatabase.sharedInstance.addActivityClient("", fileID: "", action: k_activityDebugActionCapabilities, selector: "Get external site Server", note: error, type: k_activityTypeFailure, verbose: true, activeUrl: appDelegate.activeUrl)
        }
    }
    
    func getActivityServerSuccessFailure(_ metadataNet: CCMetadataNet!, listOfActivity: [Any]?, message: String?, errorCode: Int) {
        
        // Check Active Account
        if (metadataNet.account != appDelegate.activeAccount) {
            return
        }
        
        if (errorCode == 0) {
            
            NCManageDatabase.sharedInstance.addActivityServer(listOfActivity as! [OCActivity])
            if (appDelegate.activeActivity != nil) {
                appDelegate.activeActivity.reloadDatasource()
            }
            
        } else {
            
            var error = ""
            if let message = message {
                error = "Get Activity Server failure error \(errorCode) \(message)"
            } else {
                error = "Get Activity Server failure error \(errorCode)"
            }
            
            NCManageDatabase.sharedInstance.addActivityClient("", fileID: "", action: k_activityDebugActionCapabilities, selector: "Get Activity Server", note: error, type: k_activityTypeFailure, verbose: true, activeUrl: appDelegate.activeUrl)
        }
    }
    
    func getNotificationServerSuccessFailure(_ metadataNet: CCMetadataNet!, listOfNotifications: [Any]?, message: String?, errorCode: Int) {
    
        // Check Active Account
        if (metadataNet.account != appDelegate.activeAccount) {
            return
        }
        
        if (errorCode == 0) {
            
            DispatchQueue.global(qos: .default).async {

                let sortedListOfNotifications = (listOfNotifications! as NSArray).sortedArray(using: [
                    NSSortDescriptor(key: "date", ascending: false)
                ])
                
                var old = ""
                var new = ""
                
                for notification in listOfNotifications! {
                    let id = (notification as AnyObject).idNotification!
                    new = new + String(describing: id)
                }
                for notification in self.appDelegate.listOfNotifications! {
                    let id = (notification as AnyObject).idNotification!
                    old = old + String(describing: id)
                }
                
                
                DispatchQueue.main.async {
                
                    if (new != old) {
                    
                        self.appDelegate.listOfNotifications = NSMutableArray.init(array: sortedListOfNotifications)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationReloadData"), object: nil)
                
                        // Update Main NavigationBar
                        if (self.appDelegate.activeMain.isSelectedMode == false && self.appDelegate.activeMain != nil) {
                            self.appDelegate.activeMain.setUINavigationBarDefault()
                        }
                    }
                }
            }
            
        } else {
            
            var error = ""
            if let message = message {
                error = "Get Notification Server failure error \(errorCode) \(message)"
            } else {
                error = "Get Notification Server failure error \(errorCode)"
            }
            
            NCManageDatabase.sharedInstance.addActivityClient("", fileID: "", action: k_activityDebugActionCapabilities, selector: "Get Notification Server", note: error, type: k_activityTypeFailure, verbose: true, activeUrl: appDelegate.activeUrl)
            
            // Update Main NavigationBar
            if (appDelegate.activeMain.isSelectedMode == false && self.appDelegate.activeMain != nil) {
                appDelegate.activeMain.setUINavigationBarDefault()
            }
        }
    }
}
