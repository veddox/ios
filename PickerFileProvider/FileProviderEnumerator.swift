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

        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            observer.didEnumerate(items)
            observer.finishEnumerating(upTo: nil)
            return
        }
        
        if #available(iOSApplicationExtension 11.0, *) {
            
            let account = activeAccount.account
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
                observer.didEnumerate(items)
                observer.finishEnumerating(upTo: page)
                return
            }
            
            // Read Folder
            
            ocNetworking?.readFolder(withServerUrl: serverUrl, depth: "1", account: activeAccount.account, success: { (metadatas, metadataFolder, directoryID) in
                            
                NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "account = %@ AND directoryID = %@ AND session = ''", account, directoryID!), clearDateReadDirectoryID: directoryID!)
                
                var numRecord = 0
                for metadata in metadatas as! [tableMetadata] {
                    // Add record
                    if let metadata = NCManageDatabase.sharedInstance.addMetadata(metadata) {
                        if metadata.e2eEncrypted == false {
                            let item = FileProviderItem(metadata: metadata, serverUrl: serverUrl)
                            items.append(item)
                        }
                    }
                    numRecord = numRecord + 1
                    if (numRecord == 30) {
                        break
                    }
                }
                
                if (page == NSFileProviderPage.initialPageSortedByDate as NSFileProviderPage || page == NSFileProviderPage.initialPageSortedByName as NSFileProviderPage) {
                    print("INIT")
                } else {
                    
                }
                
                observer.didEnumerate(items)
                observer.finishEnumerating(upTo: page)
                
                            
            }, failure: { (message, errorCode) in
                
                // select item from database
                if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", account, serverUrl))  {
                    if let metadatas = NCManageDatabase.sharedInstance.getMetadatas(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", account, directory.directoryID), sorted: "fileName", ascending: true) {
                        for metadata in metadatas {
                            let item = FileProviderItem(metadata: metadata, serverUrl: serverUrl)
                            items.append(item)
                        }
                    }
                }
                
                observer.didEnumerate(items)
                observer.finishEnumerating(upTo: nil)
            })
            
        } else {
            // < iOS 11
            observer.didEnumerate(items)
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
