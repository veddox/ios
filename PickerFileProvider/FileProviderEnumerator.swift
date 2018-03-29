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

        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            observer.didEnumerate(items)
            observer.finishEnumerating(upTo: nil)
            return
        }
        
        if #available(iOSApplicationExtension 11.0, *) {
            
            if (enumeratedItemIdentifier == .rootContainer) {
                
                if let serverUrl = CCUtility.getHomeServerUrlActiveUrl(activeAccount.url)  {
                    if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", activeAccount.account, serverUrl))  {
                        if let metadatas = NCManageDatabase.sharedInstance.getMetadatas(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", activeAccount.account, directory.directoryID), sorted: "fileName", ascending: true) {
                            for metadata in metadatas {
                                let item = FileProviderItem(metadata: metadata, root: false)
                                items.append(item)
                            }
                        }
                    }
                }
                
            } else {
                
                if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", activeAccount.account, enumeratedItemIdentifier.rawValue))  {
                    if let directorySource = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", activeAccount.account, metadata.directoryID))  {
                        let serverUrl = directorySource.serverUrl + "/" + metadata.fileName
                        if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", activeAccount.account, serverUrl))  {
                            if let metadatas = NCManageDatabase.sharedInstance.getMetadatas(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", activeAccount.account, directory.directoryID), sorted: "fileName", ascending: true) {
                                for metadata in metadatas {
                                    let item = FileProviderItem(metadata: metadata, root: false)
                                    items.append(item)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        observer.didEnumerate(items)
        observer.finishEnumerating(upTo: nil)
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
    }

}
