//
//  FileProviderEnumerator.swift
//  Files
//
//  Created by Marino Faggiana on 26/03/18.
//  Copyright © 2018 TWS. All rights reserved.
//

import FileProvider

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    var enumeratedItemIdentifier: NSFileProviderItemIdentifier
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }

    func invalidate() {
        // TODO: perform invalidation of server connection if necessary
    }

    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        
        var items: [NSFileProviderItemProtocol] = []
        var serverUrl: String?
        var metadatas: [tableMetadata]?
        var numRecord = 0

        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            observer.finishEnumerating(upTo: nil)
            return
        }
        let account = activeAccount.account

        if #available(iOSApplicationExtension 11.0, *) {
            
            let ocNetworking = OCnetworking.init(delegate: nil, metadataNet: nil, withUser: activeAccount.user, withUserID: activeAccount.userID, withPassword: activeAccount.password, withUrl: activeAccount.url)
            
            // Select ServerUrl
            
            if (enumeratedItemIdentifier == .rootContainer) {
                    
                serverUrl = CCUtility.getHomeServerUrlActiveUrl(activeAccount.url)
                    
            } else {
                    
                if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", activeAccount.account, enumeratedItemIdentifier.rawValue))  {
                    if let directorySource = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", activeAccount.account, metadata.directoryID))  {
                        serverUrl = directorySource.serverUrl + "/" + metadata.fileName
                    }
                }
            }
            
            guard let serverUrl = serverUrl else {
                observer.finishEnumerating(upTo: nil)
                return
            }
            
            // select item from database
            if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", account, serverUrl))  {
                metadatas = NCManageDatabase.sharedInstance.getMetadatas(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", account, directory.directoryID), sorted: "fileName", ascending: true)
            }
            
            // Calculate Page
            if (page != NSFileProviderPage.initialPageSortedByDate as NSFileProviderPage && page != NSFileProviderPage.initialPageSortedByName as NSFileProviderPage) {
                
                let stringPrevPage = Int(String(data: page.rawValue, encoding: .utf8)!)
                if (metadatas != nil) {
                    observer.didEnumerate(items)
                } else {
                    observer.finishEnumerating(upTo: nil)
                }
            }
            
            // Read Folder
            
            ocNetworking?.readFolder(withServerUrl: serverUrl, depth: "1", account: activeAccount.account, success: { (metadatas, metadataFolder, directoryID) in
                            
                NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "account = %@ AND directoryID = %@ AND session = ''", account, directoryID!), clearDateReadDirectoryID: directoryID!)
                
                for metadata in metadatas as! [tableMetadata] {
                    // Add record
                    if let metadata = NCManageDatabase.sharedInstance.addMetadata(metadata) {
                        if metadata.e2eEncrypted == false {
                            if numRecord <= 10 {
                                let item = FileProviderItem(metadata: metadata, serverUrl: serverUrl)
                                items.append(item)
                                numRecord += 1
                            }
                        }
                    }
                }
                
                let providerPage = NSFileProviderPage("1".data(using: .utf8)!)
                
                observer.didEnumerate(items)
                observer.finishEnumerating(upTo: providerPage)
                
            }, failure: { (message, errorCode) in
                
                // select item from database
                if (metadatas != nil) {
                    for metadata in metadatas! {
                        let item = FileProviderItem(metadata: metadata, serverUrl: serverUrl)
                        items.append(item)
                    }
                }
               
                observer.didEnumerate(items)
                observer.finishEnumerating(upTo: nil)
            })
            
        } else {
            // < iOS 11
            observer.finishEnumerating(upTo: nil)
        }
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
        
        print("enumerateChanges")
    }
    
    //func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
    //}

}
