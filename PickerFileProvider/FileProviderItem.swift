//
//  FileProviderItem.swift
//  Files
//
//  Created by Marino Faggiana on 26/03/18.
//  Copyright © 2018 TWS. All rights reserved.
//

import FileProvider

class FileProviderItem: NSObject, NSFileProviderItem {

    // TODO: implement an initializer to create an item from your extension's backing model
    // TODO: implement the accessors to return the values from your extension's backing model

    var fileManager = FileManager()

    // Providing Required Properties
    var itemIdentifier: NSFileProviderItemIdentifier                // The item's persistent identifier
    var filename: String = ""                                       // The item's filename
    var typeIdentifier: String = ""                                 // The item's uniform type identifiers
    var capabilities: NSFileProviderItemCapabilities {              // The item's capabilities
        
        if (self.metadata.directory) {
            return [ .allowsAddingSubItems, .allowsContentEnumerating, .allowsReading ]
        } else {
            return [ .allowsReading ]
        }
    }
    
    // Managing Content
    var childItemCount: NSNumber?                                   // The number of items contained by this item
    var documentSize: NSNumber?                                     // The document's size, in bytes

    // Specifying Content Location
    var parentItemIdentifier: NSFileProviderItemIdentifier          // The persistent identifier of the item's parent folder
    var isTrashed: Bool = false                                     // A Boolean value that indicates whether an item is in the trash
   
    // Tracking Usage
    var contentModificationDate: Date?                              // The date the item was last modified
    var creationDate: Date?                                         // The date the item was created
    var lastUsedDate: Date?                                         // The date the item was last used

    // Tracking Versions
    var versionIdentifier: Data?                                    // A data value used to determine when the item changes
    var isMostRecentVersionDownloaded: Bool = false                 // A Boolean value that indicates whether the item is the most recent version downloaded from the server

    // Monitoring File Transfers
    var isUploading: Bool = false                                   // A Boolean value that indicates whether the item is currently uploading to your remote server
    var isUploaded: Bool = true                                     // A Boolean value that indicates whether the item has been uploaded to your remote server
    var uploadingError: Error?                                      // An error that occurred while uploading to your remote server
    
    var isDownloading: Bool = false                                 // A Boolean value that indicates whether the item is currently downloading from your remote server
    var isDownloaded: Bool = true                                   // A Boolean value that indicates whether the item has been downloaded from your remote server
    var downloadingError: Error?                                    // An error that occurred while downloading the item

    // Nextcloud metadata
    var metadata = tableMetadata()
    
    // isRoot
    var isRoot = false
    
    init(metadata: tableMetadata, serverUrl: String) {
        
        // Account
        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            itemIdentifier = NSFileProviderItemIdentifier("\(metadata.fileID)")
            parentItemIdentifier = NSFileProviderItemIdentifier("")
            return
        }
        
        // isRoot ?
        if (serverUrl == CCUtility.getHomeServerUrlActiveUrl(activeAccount.url)) {
            self.isRoot = true
        }

        self.childItemCount = 0
        self.contentModificationDate = metadata.date as Date
        self.creationDate = metadata.date as Date
        self.documentSize = NSNumber(value: metadata.size)
        self.filename = metadata.fileNameView
        self.itemIdentifier = NSFileProviderItemIdentifier("\(metadata.fileID)")
        self.metadata = metadata

        // parentItemIdentifier
        if #available(iOSApplicationExtension 11.0, *) {
            
            self.parentItemIdentifier = NSFileProviderItemIdentifier.rootContainer
            
            // NOT .rootContainer
            if (!isRoot) {
                if let directoryParent = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", metadata.account, metadata.directoryID))  {
                    if let metadataParent = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", metadata.account, directoryParent.fileID))  {
                        self.parentItemIdentifier = NSFileProviderItemIdentifier(metadataParent.fileID)
                    }
                }
            }
            
        } else {
            // < iOS 11
            self.parentItemIdentifier = NSFileProviderItemIdentifier("")
        }
        
        // typeIdentifier
        if let fileType = CCUtility.insertTypeFileIconName(metadata.fileNameView, metadata: metadata) {
            self.typeIdentifier = fileType 
        }
        self.versionIdentifier = metadata.etag.data(using: .utf8)
        
        // Calculate number of children
        if (metadata.directory) {
    
            var serverUrlForChild: String?
            
            if (self.isRoot) {
                serverUrlForChild = serverUrl
            } else {
                serverUrlForChild = serverUrl + "/" + metadata.fileName
            }
            
            if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", metadata.account, serverUrlForChild!)) {
                if let metadatas = NCManageDatabase.sharedInstance.getMetadatas(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", metadata.account, directory.directoryID), sorted: "fileName", ascending: true) {
                    self.childItemCount = metadatas.count as NSNumber
                }
            }
        }
        
        // Verify file exists on cache
        if (!metadata.directory) {
            
            let directoryUser = CCUtility.getDirectoryActiveUser(activeAccount.user, activeUrl: activeAccount.url)
            let filePath = "\(directoryUser!)/\(metadata.fileID)"
                
            if fileManager.fileExists(atPath: filePath) {
                self.isDownloaded = true
                self.isMostRecentVersionDownloaded = true;
            } else {
                self.isDownloaded = false
                self.isMostRecentVersionDownloaded = false;
            }
        }
    }
}
