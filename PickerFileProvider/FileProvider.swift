//
//  FileProviderExtension.swift
//  Files
//
//  Created by Marino Faggiana on 26/03/18.
//  Copyright © 2018 TWS. All rights reserved.
//

import FileProvider
import UIKit
import MobileCoreServices

var ocNetworking: OCnetworking?
var account = ""
var accountUrl = ""
var homeServerUrl = ""
var directoryUser = ""

@available(iOSApplicationExtension 11.0, *)

class FileProvider: NSFileProviderExtension {
    
    var fileManager = FileManager()

    override init() {
        
        super.init()
        
        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            return
        }
        
        account = activeAccount.account
        accountUrl = activeAccount.url
        homeServerUrl = CCUtility.getHomeServerUrlActiveUrl(activeAccount.url)
        directoryUser = CCUtility.getDirectoryActiveUser(activeAccount.user, activeUrl: activeAccount.url)

        ocNetworking = OCnetworking.init(delegate: nil, metadataNet: nil, withUser: activeAccount.user, withUserID: activeAccount.userID, withPassword: activeAccount.password, withUrl: activeAccount.url)
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        
        if identifier == .rootContainer {
            
            if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", account, homeServerUrl)) {
                    
                let metadata = tableMetadata()
                    
                metadata.account = account
                metadata.directory = true
                metadata.directoryID = directory.directoryID
                metadata.fileID = identifier.rawValue
                metadata.fileName = "."
                metadata.fileNameView = "."
                metadata.typeFile = k_metadataTypeFile_directory
                    
                return FileProviderItem(metadata: metadata, serverUrl: homeServerUrl)
            }
            
        } else {
        
            if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", account, identifier.rawValue))  {
                if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", account, metadata.directoryID)) {
                    
                    if (!metadata.directory) {
                        let fromFileNamePath = "\(directoryUser)/\(identifier.rawValue)"
                        createFileProviderItem(identifier.rawValue, fromFileNamePath: fromFileNamePath, fileName: metadata.fileNameView)
                    }
                
                    return FileProviderItem(metadata: metadata, serverUrl: directory.serverUrl)
                }
            }
        }
        // TODO: implement the actual lookup
        throw NSFileProviderError(.noSuchItem)
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        
        // resolve the given identifier to a file on disk
                
        guard let item = try? item(for: identifier) else {
            return nil
        }
        
        // in this implementation, all paths are structured as <base storage directory>/<item identifier>/<item file name>
        let manager = NSFileProviderManager.default
        var url = manager.documentStorageURL.appendingPathComponent(identifier.rawValue, isDirectory: true)
        
        if item.typeIdentifier == (kUTTypeFolder as String) {
            url = url.appendingPathComponent(item.filename, isDirectory:true)
        } else {
            url = url.appendingPathComponent(item.filename, isDirectory:false)
        }
        
        return url
    }
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        // resolve the given URL to a persistent identifier using a database
        let pathComponents = url.pathComponents
        
        // exploit the fact that the path structure has been defined as
        // <base storage directory>/<item identifier>/<item file name> above
        assert(pathComponents.count > 2)
        
        let itemIdentifier = NSFileProviderItemIdentifier(pathComponents[pathComponents.count - 2])
        return itemIdentifier
    }
    
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        do {
            let fileProviderItem = try item(for: identifier)
            let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
            try NSFileProviderManager.writePlaceholder(at: placeholderURL,withMetadata: fileProviderItem)
            completionHandler(nil)
        } catch let error {
            completionHandler(error)
        }
    }

    override func startProvidingItem(at url: URL, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
        
        /* TODO:
         This is one of the main entry points of the file provider. We need to check whether the file already exists on disk,
         whether we know of a more recent version of the file, and implement a policy for these cases. Pseudocode:
         
         if !fileOnDisk {
             downloadRemoteFile()
             callCompletion(downloadErrorOrNil)
         } else if fileIsCurrent {
             callCompletion(nil)
         } else {
             if localFileHasChanges {
                 // in this case, a version of the file is on disk, but we know of a more recent version
                 // we need to implement a strategy to resolve this conflict
                 moveLocalFileAside()
                 scheduleUploadOfLocalFile()
                 downloadRemoteFile()
                 callCompletion(downloadErrorOrNil)
             } else {
                 downloadRemoteFile()
                 callCompletion(downloadErrorOrNil)
             }
         }
         */
        
        var fileSize : UInt64 = 0
        
        do {
            let attr = try fileManager.attributesOfItem(atPath: url.path)
            fileSize = attr[FileAttributeKey.size] as! UInt64
        } catch {
            print("Error: \(error)")
            completionHandler(NSFileProviderError(.noSuchItem))
        }
            
        // Do not exists
        if fileSize == 0 {
                
            let pathComponents = url.pathComponents
            let itemIdentifier = pathComponents[pathComponents.count - 2]
            
            guard let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", account, itemIdentifier)) else {
                completionHandler(NSFileProviderError(.noSuchItem))
                return
            }
                
            guard let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND directoryID = %@", account, metadata.directoryID)) else {
                completionHandler(NSFileProviderError(.noSuchItem))
                return
            }

            ocNetworking?.downloadFileNameServerUrl("\(directory.serverUrl)/\(metadata.fileName)", fileNameLocalPath: "\(directoryUser)/\(itemIdentifier)", success: {
                
                NCManageDatabase.sharedInstance.addLocalFile(metadata: metadata)
                if (metadata.typeFile == k_metadataTypeFile_image) {
                    CCExifGeo.sharedInstance().setExifLocalTableEtag(metadata, directoryUser: directoryUser, activeAccount: account)
                }
                completionHandler(nil)
                    
            }, failure: { (message, errorCode) in
                completionHandler(NSFileProviderError(.serverUnreachable))
            })
                
        } else {
                
            // Exists
            completionHandler(nil)
        }
    }
    
    override func itemChanged(at url: URL) {
        // Called at some point after the file has changed; the provider may then trigger an upload
        
        /* TODO:
         - mark file at <url> as needing an update in the model
         - if there are existing NSURLSessionTasks uploading this file, cancel them
         - create a fresh background NSURLSessionTask and schedule it to upload the current modifications
         - register the NSURLSessionTask with NSFileProviderManager to provide progress updates
         */
    }
    
    override func stopProvidingItem(at url: URL) {
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.
        
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        
        // TODO: look up whether the file has local changes
        let fileHasLocalChanges = false
        
        if !fileHasLocalChanges {
            // remove the existing file to free up space
            do {
                _ = try FileManager.default.removeItem(at: url)
            } catch {
                // Handle error
            }
            
            // write out a placeholder to facilitate future property lookups
            self.providePlaceholder(at: url, completionHandler: { error in
                // TODO: handle any error, do any necessary cleanup
            })
        }
    }
    
    // MARK: - Actions
    
    /* TODO: implement the actions for items here
     each of the actions follows the same pattern:
     - make a note of the change in the local model
     - schedule a server request as a background task to inform the server of the change
     - call the completion block with the modified item in its post-modification state
     */
    
    // MARK: - Enumeration
    
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
        
        let maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
        
        return maybeEnumerator
    }
    
    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void, completionHandler: @escaping (Error?) -> Void) -> Progress {
        
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        var counterProgress: Int64 = 0
        
        for item in itemIdentifiers {
            
            if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", account, item.rawValue))  {
                
                if (metadata.typeFile == k_metadataTypeFile_image || metadata.typeFile == k_metadataTypeFile_video) {
                    
                    let serverUrl = NCManageDatabase.sharedInstance.getServerUrl(metadata.directoryID)
                    let fileName = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: serverUrl, activeUrl: accountUrl)
                    let fileNameLocal = metadata.fileID

                    ocNetworking?.downloadThumbnail(withDimOfThumbnail: "m", fileName: fileName, fileNameLocal: fileNameLocal, success: {

                        do {
                            let url = URL.init(fileURLWithPath: "\(directoryUser)/\(item.rawValue).ico")
                            let data = try Data.init(contentsOf: url)
                            perThumbnailCompletionHandler(item, data, nil)
                        } catch {
                            perThumbnailCompletionHandler(item, nil, NSFileProviderError(.noSuchItem))
                        }
                        
                        counterProgress += 1
                        if (counterProgress == progress.totalUnitCount) {
                            completionHandler(nil)
                        }
                        
                    }, failure: { (message, errorCode) in

                        perThumbnailCompletionHandler(item, nil, NSFileProviderError(.serverUnreachable))
                        
                        counterProgress += 1
                        if (counterProgress == progress.totalUnitCount) {
                            completionHandler(nil)
                        }
                    })
                    
                } else {
                    
                    counterProgress += 1
                    if (counterProgress == progress.totalUnitCount) {
                        completionHandler(nil)
                    }
                }
            } else {
                counterProgress += 1
                if (counterProgress == progress.totalUnitCount) {
                    completionHandler(nil)
                }
            }
        }
        
        return progress
    }
    
    override func createDirectory(withName directoryName: String, inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {

        guard let directoryParent = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND fileID = %@", account, parentItemIdentifier.rawValue)) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        ocNetworking?.createFolder(directoryName, serverUrl: directoryParent.serverUrl, account: account, success: { (fileID, date) in
            
            guard let newTableDirectory = NCManageDatabase.sharedInstance.addDirectory(encrypted: false, favorite: false, fileID: fileID, permissions: nil, serverUrl: directoryParent.serverUrl+"/"+directoryName) else {
                completionHandler(nil, NSFileProviderError(.noSuchItem))
                return
            }
            
            let metadata = tableMetadata()
            
            metadata.account = account
            metadata.directory = true
            metadata.directoryID = newTableDirectory.directoryID
            metadata.fileID = fileID!
            metadata.fileName = directoryName
            metadata.fileNameView = directoryName
            metadata.typeFile = k_metadataTypeFile_directory
                        
            let item = FileProviderItem(metadata: metadata, serverUrl: directoryParent.serverUrl)
            
            completionHandler(item, nil)
            
        }, failure: { (message, errorCode) in
            completionHandler(nil, NSFileProviderError(.serverUnreachable))
        })
    }
    
    override func importDocument(at fileURL: URL, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        
        guard let directoryParent = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND fileID = %@", account, parentItemIdentifier.rawValue)) else {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        if fileURL.startAccessingSecurityScopedResource() == false {
            completionHandler(nil, NSFileProviderError(.noSuchItem))
            return
        }
        
        let fileName = fileURL.lastPathComponent
        let fileNameLocalPath = fileURL.path

        ocNetworking?.uploadFileNameServerUrl(directoryParent.serverUrl+"/"+fileName, fileNameLocalPath: fileNameLocalPath, success: { (fileID, etag, date) in
            
            let metadata = tableMetadata()
            
            metadata.account = account
            metadata.date = date! as NSDate
            metadata.directory = false
            metadata.directoryID = directoryParent.directoryID
            metadata.etag = etag!
            metadata.fileID = fileID!
            metadata.fileName = fileName
            metadata.fileNameView = fileName

            do {
                let attributes = try self.fileManager.attributesOfItem(atPath: fileURL.path)
                metadata.size = attributes[FileAttributeKey.size] as! Double
            } catch {
            }
            
            CCUtility.insertTypeFileIconName(fileName, metadata: metadata)
            
            guard let metadataDB = NCManageDatabase.sharedInstance.addMetadata(metadata) else {
                completionHandler(nil, NSFileProviderError(.noSuchItem))
                return
            }

            // Copy file
            self.createFileProviderItem(metadata.fileID, fromFileNamePath: fileURL.path, fileName: fileName)
            try? self.fileManager.copyItem(atPath: fileURL.path, toPath: directoryUser+"/"+metadata.fileID)

            // add item
            let item = FileProviderItem(metadata: metadataDB, serverUrl: directoryParent.serverUrl)
            
            fileURL.stopAccessingSecurityScopedResource()
            completionHandler(item, nil)

        }, failure: { (message, errorCode) in
            fileURL.stopAccessingSecurityScopedResource()
            completionHandler(nil, NSFileProviderError(.serverUnreachable))
        })
    }
    
    // ----------------------------------------------------------------------------------------------------------------------------
    
    func createFileProviderItem(_ fileProviderItem: String, fromFileNamePath: String, fileName: String) {
        
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: NCBrandOptions.sharedInstance.capabilitiesGroups) else {
            return
        }
        
        var storagePathUrl = groupURL.appendingPathComponent("File Provider Storage")
        storagePathUrl = storagePathUrl.appendingPathComponent(fileProviderItem)
        let storagePath = storagePathUrl.path
        
        if !FileManager.default.fileExists(atPath: storagePath) {
            do {
                try FileManager.default.createDirectory(atPath: storagePath, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                print("error creating filepath: \(error)")
                return
            }
        }
        
        // ??? move o create 0 file .. is correct ???
        let toFilePath = "\(storagePath)/\(fileName)"
            
        try? fileManager.removeItem(atPath: toFilePath)
            
        if fileManager.fileExists(atPath: fromFileNamePath) {
            try? fileManager.copyItem(atPath: fromFileNamePath, toPath: toFilePath)
        } else {
            fileManager.createFile(atPath: toFilePath, contents: nil, attributes: nil)
        }
    }
}
