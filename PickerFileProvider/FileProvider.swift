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

@available(iOSApplicationExtension 11.0, *)

class FileProvider: NSFileProviderExtension {
    
    var fileManager = FileManager()

    override init() {
        super.init()
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        
        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:])
        }
        
        if identifier == .rootContainer {
            
            if let serverUrl = CCUtility.getHomeServerUrlActiveUrl(activeAccount.url)  {
                if let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", activeAccount.account, serverUrl)) {
                    
                    let metadata = tableMetadata()
                    metadata.account = activeAccount.account
                    metadata.directory = true
                    metadata.directoryID = directory.directoryID
                    metadata.fileID = directory.fileID
                    metadata.fileName = "."
                    metadata.fileNameView = "."
                    metadata.typeFile = k_metadataTypeFile_directory
                    
                    return FileProviderItem(metadata: metadata, root: true)
                }
            }
        } else {
        
            if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", activeAccount.account, identifier.rawValue))  {
                
                if (!metadata.directory) {
                    createFileProviderItem(identifier.rawValue,fileName: metadata.fileNameView)
                }
                
                return FileProviderItem(metadata: metadata, root: false)
            }
        }
        // TODO: implement the actual lookup
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:])
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        // resolve the given identifier to a file on disk
                
        guard let item = try? item(for: identifier) else {
            return nil
        }
        
        // in this implementation, all paths are structured as <base storage directory>/<item identifier>/<item file name>
        let manager = NSFileProviderManager.default
        let perItemDirectory = manager.documentStorageURL.appendingPathComponent(identifier.rawValue, isDirectory: true)
        
        if item.typeIdentifier == (kUTTypeFolder as String) {
            return perItemDirectory.appendingPathComponent(item.filename, isDirectory:true)
        } else {
            return perItemDirectory.appendingPathComponent(item.filename, isDirectory:false)
        }
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
        
        do {
            let attr = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attr[FileAttributeKey.size] as! UInt64
            
            if fileSize == 0 {
                completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
            } else {
                completionHandler(nil)
            }
            
        } catch {
            print("Error: \(error)")
            completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
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
        
        var maybeEnumerator: NSFileProviderEnumerator? = nil
        
        if (containerItemIdentifier == NSFileProviderItemIdentifier.rootContainer) {
            
            maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
            
        } else if (containerItemIdentifier == NSFileProviderItemIdentifier.workingSet) {
            
            maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
            
        } else {
            
            // TODO: determine if the item is a directory or a file
            // - for a directory, instantiate an enumerator of its subitems
            // - for a file, instantiate an enumerator that observes changes to the file
            
            print("\(containerItemIdentifier.rawValue)");
            
            maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
        }
        guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
        }
        return enumerator
    }
    
    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void, completionHandler: @escaping (Error?) -> Void) -> Progress {
        
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        var counterProgress: Int64 = 0
        
        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            completionHandler(nil)
            return progress
        }
        
        let directoryUser = CCUtility.getDirectoryActiveUser(activeAccount.user, activeUrl: activeAccount.url)
        let ocNetworking = OCnetworking.init(delegate: nil, metadataNet: nil, withUser: activeAccount.user, withUserID: activeAccount.userID, withPassword: activeAccount.password, withUrl: activeAccount.url)

        for item in itemIdentifiers {
            
            counterProgress += 1

            if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", activeAccount.account, item.rawValue))  {
                
                if (metadata.typeFile == k_metadataTypeFile_image || metadata.typeFile == k_metadataTypeFile_video) {
                    
                    let serverUrl = NCManageDatabase.sharedInstance.getServerUrl(metadata.directoryID)
                    let fileName = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: serverUrl, activeUrl: activeAccount.url)
                    let fileNameLocal = metadata.fileID

                    ocNetworking?.downloadThumbnail(withDimOfThumbnail: "m", fileName: fileName, fileNameLocal: fileNameLocal, success: {

                        do {
                            let url = URL.init(fileURLWithPath: "\(directoryUser!)/\(item.rawValue).ico")
                            let data = try Data.init(contentsOf: url)
                            perThumbnailCompletionHandler(item, data, nil)
                        } catch {
                            perThumbnailCompletionHandler(item, nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:]))
                        }
                        
                        if (counterProgress == progress.totalUnitCount) {
                            completionHandler(nil)
                        }
                        
                    }, failure: {

                        perThumbnailCompletionHandler(item, nil, NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:]))
                        
                        if (counterProgress == progress.totalUnitCount) {
                            completionHandler(nil)
                        }

                    })
                    
                } else {
                    
                    if (counterProgress == progress.totalUnitCount) {
                        completionHandler(nil)
                    }
                }
            }
        }
        
        return progress
    }
    
    func createFileProviderItem(_ fileProviderItem: String, fileName: String) {
        
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
        if let activeAccount = NCManageDatabase.sharedInstance.getAccountActive()  {
                
            let directoryUser = CCUtility.getDirectoryActiveUser(activeAccount.user, activeUrl: activeAccount.url)
            let atFilePath = "\(directoryUser!)/\(fileProviderItem)"
            let toFilePath = "\(storagePath)/\(fileName)"
                
            try? fileManager.removeItem(atPath: toFilePath)

            if fileManager.fileExists(atPath: atFilePath) {
                try? fileManager.copyItem(atPath: atFilePath, toPath: toFilePath)
            } else {
                fileManager.createFile(atPath: toFilePath, contents: nil, attributes: nil)
            }
        }
    }
}
