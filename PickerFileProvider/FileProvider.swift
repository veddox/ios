//
//  OCFileProvider.swift
//  ownCloudExtAppFileProvider
//
//  Created by Pablo Carrascal on 03/11/2017.
//

import UIKit
import MobileCoreServices

@available(iOSApplicationExtension 11.0, *)

class FileProvider: NSFileProviderExtension {
    
    // This is our file provider manager, it handles things like placeholders on disk
    var fileProviderManager: NSFileProviderManager!
    var fileManager: FileManager!
    
    
    override init() {
        
        print("FileProviderExtension is being created")
        super.init()
        
        self.fileProviderManager = NSFileProviderManager.default
        self.fileManager = FileManager()
    }
    
    deinit {
        print("FileProviderExtension is being deallocated")
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
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        
        guard let item = try? item(for: identifier) else {
            return nil
        }
        
        //TODO: Change the scheme to the OC scheme.
        let manager = NSFileProviderManager.default
        let perItemDirectory = manager.documentStorageURL.appendingPathComponent(identifier.rawValue, isDirectory: true)
        
        var finalPath: URL
        print("LOG ---> name = \(item.filename.removingPercentEncoding!) = \(item.typeIdentifier)")
        if item.typeIdentifier == (kUTTypeFolder as String) {
            finalPath = perItemDirectory.appendingPathComponent(item.filename, isDirectory:true)
        } else {
            finalPath = perItemDirectory.appendingPathComponent(item.filename, isDirectory:false)
        }

        return finalPath
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        
        guard let activeAccount = NCManageDatabase.sharedInstance.getAccountActive() else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:])
        }

        if identifier == .rootContainer {
            
            guard let homeServerUrl = CCUtility.getHomeServerUrlActiveUrl(activeAccount.url) else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:])
            }
            
            guard let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account = %@ AND serverUrl = %@", activeAccount.account, homeServerUrl)) else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:])
            }
            
            let metadata = tableMetadata()
            metadata.account = activeAccount.account
            metadata.directory = true
            metadata.directoryID = directory.directoryID
            metadata.typeFile = k_metadataTypeFile_directory
            
            return FileProviderItem(metadata: metadata, root: true) 
        }
        
        if let metadata =  NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account = %@ AND fileID = %@", activeAccount.account, identifier.rawValue)) {
            return FileProviderItem(metadata: metadata, root: false)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:])
        }
    }
    
    override func itemChanged(at url: URL) {
        print("LOG ---> itemchanged")
    }
    
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }
        
        let fileName:String = url.lastPathComponent

        var formedURL: URL = self.fileProviderManager.documentStorageURL.appendingPathComponent(identifier.rawValue, isDirectory: true)
        formedURL.appendPathComponent(fileName, isDirectory: false)
        
        do {
            let fileProviderItem = try item(for: identifier)

            let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
            let placecholderDirectoryUrl = placeholderURL.deletingLastPathComponent()
            var createDirectoryError:Error?
            
            if (!fileManager.fileExists(atPath: placecholderDirectoryUrl.absoluteString)) {
                var fcError: NSError?
                self.fileCoordinator().coordinate(writingItemAt: placecholderDirectoryUrl, options: NSFileCoordinator.WritingOptions(rawValue: 0), error: &fcError
                    , byAccessor: { (newUrl) in
                        do {
                            createDirectoryError = fcError;
                            if (fcError == nil) {
                                try fileManager.createDirectory(at: newUrl, withIntermediateDirectories: true, attributes: nil)
                            }
                        } catch let fmError {
                            NSLog("createError = %@", fmError.localizedDescription)
                            createDirectoryError = fmError
                        }
                })
            }
            
            if let placeholderError = createDirectoryError {
                throw placeholderError
            }
            else {
                NSLog("placeholderURL = %@", placeholderURL.absoluteString)
                try NSFileProviderManager.writePlaceholder(at: placeholderURL,
                                                           withMetadata: fileProviderItem)
                completionHandler(nil)
            }
            
        } catch let error {
            NSLog("writePlaceholder error = %@", error.localizedDescription)
            completionHandler(error)
        }
    }
    
    func fileCoordinator() -> NSFileCoordinator {
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.purposeIdentifier = self.providerIdentifier
        return fileCoordinator
    }
    
    override func startProvidingItem(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        
        print("LOG --->startproviding")

    }
    
    override func stopProvidingItem(at url: URL) {
        print("LOG --->stopproviding")
    }
    
    override func createDirectory(withName directoryName: String, inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->createdirectory")
        completionHandler(nil, nil)
    }
    
    override func deleteItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (Error?) -> Void) {
        print("LOG --->delete")
        completionHandler(nil)
    }
    
    override func importDocument(at fileURL: URL, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->import")
        completionHandler(nil, nil)

    }
    
    override func renameItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toName itemName: String, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> rename")
        completionHandler(nil, nil)
    }
    
    override func setFavoriteRank(_ favoriteRank: NSNumber?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->setfavourite")
        completionHandler(nil, nil)
    }
    
    override func setLastUsedDate(_ lastUsedDate: Date?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->setLastUsedDate")
        completionHandler(nil, nil)
    }
    
    override func setTagData(_ tagData: Data?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> setTagData")
        completionHandler(nil, nil)
    }
    
    override func trashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> trashitem")
        completionHandler(nil, nil)
    }
    
    override func untrashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier?, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> untrashitem")
        completionHandler(nil, nil)
    }
    
    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void, completionHandler: @escaping (Error?) -> Void) -> Progress {
    
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        
        /*
        let image = UIImage(named: "folder")
        let imagePNG = UIImagePNGRepresentation(image!) as! Data
        
        for item in itemIdentifiers {
            perThumbnailCompletionHandler(item, imagePNG, nil)
        }
        */
        
        return progress

    }
    
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
            
            let item = try self.item(for: containerItemIdentifier)
            
            print("\(containerItemIdentifier.rawValue)");
            
            maybeEnumerator = FileProviderEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
        }
        guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
        }
        return enumerator
    }
    
    /*
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
        print("LOG ---> enumerator")
        var maybeEnumerator: NSFileProviderEnumerator? = nil
        
        print("LOG ---> containerItemIdentifier \(containerItemIdentifier)")
        switch containerItemIdentifier {
                case .rootContainer:
                maybeEnumerator = RootContainerEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
                case .workingSet:
                // TODO: instantiate an enumerator for the working set
                maybeEnumerator = DirectoryEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
                default:
                    do{
                        let item = try self.item(for: containerItemIdentifier)
                        
                        if item.typeIdentifier == kUTTypeFolder as String {
                            // - for a directory, instantiate an enumerator of its subitems
                            maybeEnumerator = DirectoryEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
                        } else {
                            // - for a file, instantiate an enumerator that observes changes to the file
                            maybeEnumerator = DirectoryEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
                        }
          
                    } catch let error {
                        maybeEnumerator = nil
                        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo:[:])
                    }
            }
            
            guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
            }
            return enumerator
    }
    */
    
}

