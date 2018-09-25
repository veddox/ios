//
//  CCCreateCloud.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 09/01/17.
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

import Foundation

// MARK: -

class CreateMenuAdd: NSObject {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    let fontButton = [NSAttributedStringKey.font:UIFont(name: "HelveticaNeue", size: 16)!, NSAttributedStringKey.foregroundColor: UIColor.black]
    let fontEncrypted = [NSAttributedStringKey.font:UIFont(name: "HelveticaNeue", size: 16)!, NSAttributedStringKey.foregroundColor: NCBrandColor.sharedInstance.encrypted as UIColor]
    let fontCancel = [NSAttributedStringKey.font:UIFont(name: "HelveticaNeue-Bold", size: 17)!, NSAttributedStringKey.foregroundColor: UIColor.black]
    let fontDisable = [NSAttributedStringKey.font:UIFont(name: "HelveticaNeue", size: 16)!, NSAttributedStringKey.foregroundColor: UIColor.darkGray]

    let colorLightGray = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1)
    let colorGray = UIColor(red: 150.0/255.0, green: 150.0/255.0, blue: 150.0/255.0, alpha: 1)
    var colorIcon = NCBrandColor.sharedInstance.brandElement
    
    @objc init (themingColor : UIColor) {
        
        super.init()
        colorIcon = themingColor
    }
    
    @objc func createMenu(view : UIView) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let actionSheet = AHKActionSheet.init(view: view, title: nil)!
        
        actionSheet.animationDuration = 0.2
        actionSheet.automaticallyTintButtonImages = 0
        
        actionSheet.buttonHeight = 50.0
        actionSheet.cancelButtonHeight = 50.0
        actionSheet.separatorHeight = 5.0
        
        actionSheet.separatorColor = NCBrandColor.sharedInstance.seperator
        
        actionSheet.buttonTextAttributes = fontButton
        actionSheet.encryptedButtonTextAttributes = fontEncrypted
        actionSheet.cancelButtonTextAttributes = fontCancel
        actionSheet.disableButtonTextAttributes = fontDisable
        
        actionSheet.cancelButtonTitle = NSLocalizedString("_cancel_", comment: "")
        
        actionSheet.addButton(withTitle: NSLocalizedString("_upload_photos_videos_", comment: ""), image: CCGraphics.changeThemingColorImage(UIImage(named: "media"), multiplier:2, color: colorGray), backgroundColor: NCBrandColor.sharedInstance.backgroundView, height: 50.0, type: AHKActionSheetButtonType.default, handler: {(AHKActionSheet) -> Void in
            appDelegate.activeMain.openAssetsPickerController()
        })
        
        actionSheet.addButton(withTitle: NSLocalizedString("_upload_file_", comment: ""), image: CCGraphics.changeThemingColorImage(UIImage(named: "file"), multiplier:2, color: colorGray), backgroundColor: NCBrandColor.sharedInstance.backgroundView, height: 50.0, type: AHKActionSheetButtonType.default, handler: {(AHKActionSheet) -> Void in
            appDelegate.activeMain.openImportDocumentPicker()
        })
        
        actionSheet.addButton(withTitle: NSLocalizedString("_upload_file_text_", comment: ""), image: CCGraphics.changeThemingColorImage(UIImage(named: "file_txt"), multiplier:2, color: colorGray), backgroundColor: NCBrandColor.sharedInstance.backgroundView, height: 50.0, type: AHKActionSheetButtonType.default, handler: {(AHKActionSheet) -> Void in
            
            let storyboard = UIStoryboard(name: "NCText", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "NCText")
            controller.modalPresentationStyle = UIModalPresentationStyle.pageSheet
            appDelegate.activeMain.present(controller, animated: true, completion: nil)
        })
        
        if #available(iOS 11.0, *) {
            actionSheet.addButton(withTitle: NSLocalizedString("_scans_document_", comment: ""), image: CCGraphics.changeThemingColorImage(UIImage(named: "scan"), multiplier:2, color: colorGray), backgroundColor: NCBrandColor.sharedInstance.backgroundView, height: 50.0, type: AHKActionSheetButtonType.default, handler: {(AHKActionSheet) -> Void in
                NCCreateScanDocument.sharedInstance.openScannerDocument(viewController: appDelegate.activeMain, openScan: true)
            })
        }
        
        actionSheet.addButton(withTitle: NSLocalizedString("_create_folder_", comment: ""), image: CCGraphics.changeThemingColorImage(UIImage(named: "folder"), multiplier:2, color: colorIcon), backgroundColor: NCBrandColor.sharedInstance.backgroundView, height: 50.0 ,type: AHKActionSheetButtonType.default, handler: {(AHKActionSheet) -> Void in
            appDelegate.activeMain.createFolder()
        })
        
        actionSheet.show()
    }
}

// MARK: -

@objc protocol createFormUploadAssetsDelegate {
    
    func dismissFormUploadAssets()
}

// MARK: -

class CreateFormUploadAssets: XLFormViewController, CCMoveDelegate {
    
    var serverUrl : String = ""
    var titleServerUrl : String?
    var assets: NSMutableArray = []
    var cryptated : Bool = false
    var session : String = ""
    weak var delegate: createFormUploadAssetsDelegate?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @objc convenience init(serverUrl : String, assets : NSMutableArray, cryptated : Bool, session : String, delegate: createFormUploadAssetsDelegate) {
        
        self.init()
        
        if serverUrl == CCUtility.getHomeServerUrlActiveUrl(appDelegate.activeUrl) {
            titleServerUrl = "/"
        } else {
            titleServerUrl = (serverUrl as NSString).lastPathComponent
        }
        
        self.serverUrl = serverUrl
        self.assets = assets
        self.cryptated = cryptated
        self.session = session
        self.delegate = delegate
        
        self.initializeForm()
    }
    
    //MARK: XLFormDescriptorDelegate

    func initializeForm() {

        let form : XLFormDescriptor = XLFormDescriptor(title: NSLocalizedString("_upload_photos_videos_", comment: "")) as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow

        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        // Section: Destination Folder
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_path_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: XLFormRowDescriptorTypeButton, title: self.titleServerUrl)
        row.action.formSelector = #selector(changeDestinationFolder(_:))

        let imageFolder = CCGraphics.changeThemingColorImage(UIImage(named: "folder")!, multiplier:2, color: NCBrandColor.sharedInstance.brandElement) as UIImage
        row.cellConfig["imageView.image"] = imageFolder
        
        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // User folder Media
        row = XLFormRowDescriptor(tag: "useFolderMedia", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_use_folder_media_", comment: ""))
        row.value = 0
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Use Sub folder
        row = XLFormRowDescriptor(tag: "useSubFolder", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_autoupload_create_subfolder_", comment: ""))
        let tableAccount = NCManageDatabase.sharedInstance.getAccountActive()
        if tableAccount?.autoUploadCreateSubfolder == true {
            row.value = 1
        } else {
            row.value = 0
        }
        row.hidden = "$\("useFolderMedia") == 0"

        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)

        section.addFormRow(row)
        
        // Section Mode filename
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_mode_filename_", comment: ""))
        form.addFormSection(section)
        
        // Maintain the original fileName
        
        row = XLFormRowDescriptor(tag: "maintainOriginalFileName", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_maintain_original_filename_", comment: ""))
        row.value = CCUtility.getOriginalFileName(k_keyFileNameOriginal)
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Add File Name Type

        row = XLFormRowDescriptor(tag: "addFileNameType", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: NSLocalizedString("_add_filenametype_", comment: ""))
        row.value = CCUtility.getFileNameType(k_keyFileNameType)
        row.hidden = "$\("maintainOriginalFileName") == 1"
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)

        section.addFormRow(row)
        
        // Section: Rename File Name
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_filename_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "maskFileName", rowType: XLFormRowDescriptorTypeAccount, title: (NSLocalizedString("_filename_", comment: "")))
        let fileNameMask : String = CCUtility.getFileNameMask(k_keyFileNameMask)
        if fileNameMask.count > 0 {
            row.value = fileNameMask
        }
        row.hidden = "$\("maintainOriginalFileName") == 1"
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)

        section.addFormRow(row)
        
        // Section: Preview File Name
        
        row = XLFormRowDescriptor(tag: "previewFileName", rowType: XLFormRowDescriptorTypeTextView, title: "")
        row.height = 180
        row.disabled = true

        row.cellConfig["textView.backgroundColor"] = NCBrandColor.sharedInstance.backgroundView
        row.cellConfig["textView.font"] = UIFont.systemFont(ofSize: 14.0)
        
        section.addFormRow(row)
        
        self.form = form
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "useFolderMedia" {
            
            if (formRow.value! as AnyObject).boolValue  == true {
                
                let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
                buttonDestinationFolder.hidden = true
                
            } else{
                
                let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
                buttonDestinationFolder.hidden = false
            }
        }
        else if formRow.tag == "useSubFolder" {
            
            if (formRow.value! as AnyObject).boolValue  == true {
                
            } else{
                
            }
        }
        else if formRow.tag == "maintainOriginalFileName" {
            CCUtility.setOriginalFileName((formRow.value! as AnyObject).boolValue, key: k_keyFileNameOriginal)
            self.reloadForm()
        }
        else if formRow.tag == "addFileNameType" {
            CCUtility.setFileNameType((formRow.value! as AnyObject).boolValue, key: k_keyFileNameType)
            self.reloadForm()
        }
        else if formRow.tag == "maskFileName" {
            
            let fileName = formRow.value as? String
            
            self.form.delegate = nil
            
            if let fileName = fileName {
                formRow.value = CCUtility.removeForbiddenCharactersServer(fileName)
            }
            
            self.form.delegate = self
            
            let previewFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "previewFileName")!
            previewFileName.value = self.previewFileName(valueRename: formRow.value as? String)
            
            // reload cell
            if fileName != nil {
                
                if newValue as! String != formRow.value as! String {
                    
                    self.reloadFormRow(formRow)
                    
                    appDelegate.messageNotification("_info_", description: "_forbidden_characters_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                }
            }
            
            self.reloadFormRow(previewFileName)
        }
    }
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let cancelButton : UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_cancel_", comment: ""), style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancel))
        let saveButton : UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItemStyle.plain, target: self, action: #selector(save))
        
        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = NCBrandColor.sharedInstance.brand
        self.navigationController?.navigationBar.tintColor = NCBrandColor.sharedInstance.brandText
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: NCBrandColor.sharedInstance.brandText]
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        self.reloadForm()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)

        self.delegate?.dismissFormUploadAssets()        
    }

    func reloadForm() {
        
        self.form.delegate = nil
        
        let buttonDestinationFolder : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
        buttonDestinationFolder.title = self.titleServerUrl
        
        let maskFileName : XLFormRowDescriptor = self.form.formRow(withTag: "maskFileName")!
        let previewFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "previewFileName")!
        previewFileName.value = self.previewFileName(valueRename: maskFileName.value as? String)
        
        self.tableView.reloadData()
        self.form.delegate = self
    }

    // MARK: - Action

    func moveServerUrl(to serverUrlTo: String!, title: String!) {
    
        self.serverUrl = serverUrlTo
        
        if let title = title {
            
            self.titleServerUrl = title
            
        } else {
            
            self.titleServerUrl = "/"
        }
        
        self.reloadForm()
    }
    
    @objc func save() {
        
        self.dismiss(animated: true, completion: {
            
            let useFolderPhotoRow : XLFormRowDescriptor  = self.form.formRow(withTag: "useFolderMedia")!
            let useSubFolderRow : XLFormRowDescriptor  = self.form.formRow(withTag: "useSubFolder")!
            var useSubFolder : Bool = false
            
            if (useFolderPhotoRow.value! as AnyObject).boolValue == true {
                
                self.serverUrl = NCManageDatabase.sharedInstance.getAccountAutoUploadPath(self.appDelegate.activeUrl)
                useSubFolder = (useSubFolderRow.value! as AnyObject).boolValue
            }
            
            self.appDelegate.activeMain.uploadFileAsset(self.assets, serverUrl: self.serverUrl, useSubFolder: useSubFolder, session: self.session)
        })
    }

    @objc func cancel() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Utility
    
    func previewFileName(valueRename : String?) -> String {
        
        var returnString: String = ""
        let asset = assets[0] as! PHAsset
        
        if (CCUtility.getOriginalFileName(k_keyFileNameOriginal)) {
            
            return (NSLocalizedString("_filename_", comment: "") + ": " + (asset.value(forKey: "filename") as! String))
            
        } else if let valueRename = valueRename {
            
            let valueRenameTrimming = valueRename.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if valueRenameTrimming.count > 0 {
                
                self.form.delegate = nil
                CCUtility.setFileNameMask(valueRename, key: k_keyFileNameMask)
                self.form.delegate = self
                
                returnString = CCUtility.createFileName(asset.value(forKey: "filename"), fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: k_keyFileNameMask, keyFileNameType: k_keyFileNameType, keyFileNameOriginal: k_keyFileNameOriginal)
                
            } else {
                
                CCUtility.setFileNameMask("", key: k_keyFileNameMask)
                returnString = CCUtility.createFileName(asset.value(forKey: "filename"), fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: k_keyFileNameType, keyFileNameOriginal: k_keyFileNameOriginal)
            }
            
        } else {
            
            CCUtility.setFileNameMask("", key: k_keyFileNameMask)
            returnString = CCUtility.createFileName(asset.value(forKey: "filename"), fileDate: asset.creationDate, fileType: asset.mediaType, keyFileName: nil, keyFileNameType: k_keyFileNameType, keyFileNameOriginal: k_keyFileNameOriginal)
        }
        
        return String(format: NSLocalizedString("_preview_filename_", comment: ""), "MM,MMM,DD,YY,YYYY and HH,hh,mm,ss,ampm") + ":" + "\n\n" + returnString
    }
    
    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {
        
        self.deselectFormRow(sender)
        
        let storyboard : UIStoryboard = UIStoryboard(name: "CCMove", bundle: nil)
        let navigationController = storyboard.instantiateViewController(withIdentifier: "CCMove") as! UINavigationController
        let viewController : CCMove = navigationController.topViewController as! CCMove
        
        viewController.delegate = self;
        viewController.tintColor = NCBrandColor.sharedInstance.brandText
        viewController.barTintColor = NCBrandColor.sharedInstance.brand
        viewController.tintColorTitle = NCBrandColor.sharedInstance.brandText
        viewController.move.title = NSLocalizedString("_select_", comment: "");
        viewController.networkingOperationQueue =  appDelegate.netQueue
        // E2EE
        viewController.includeDirectoryE2EEncryption = true;
        
        navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.present(navigationController, animated: true, completion: nil)
    }
    
}

// MARK: -

class CreateFormUploadFileText: XLFormViewController, CCMoveDelegate {
    
    var serverUrl = ""
    var titleServerUrl = ""
    var fileName = ""
    var text = ""
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    convenience init(serverUrl: String, text: String, fileName: String) {
        
        self.init()
        
        if serverUrl == CCUtility.getHomeServerUrlActiveUrl(appDelegate.activeUrl) {
            titleServerUrl = "/"
        } else {
            titleServerUrl = (serverUrl as NSString).lastPathComponent
        }
        
        self.fileName = fileName
        self.serverUrl = serverUrl
        self.text = text
        
        initializeForm()
    }
    
    //MARK: XLFormDescriptorDelegate
    
    func initializeForm() {
        
        let form : XLFormDescriptor = XLFormDescriptor() as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        // Section: Destination Folder
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_path_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: XLFormRowDescriptorTypeButton, title: self.titleServerUrl)
        row.action.formSelector = #selector(changeDestinationFolder(_:))

        let imageFolder = CCGraphics.changeThemingColorImage(UIImage(named: "folder")!, multiplier:2, color: NCBrandColor.sharedInstance.brandElement) as UIImage
        row.cellConfig["imageView.image"] = imageFolder
        
        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Section: File Name
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_filename_", comment: ""))
        form.addFormSection(section)
        
        
        row = XLFormRowDescriptor(tag: "fileName", rowType: XLFormRowDescriptorTypeAccount, title: NSLocalizedString("_filename_", comment: ""))
        row.value = self.fileName
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        self.form = form
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "fileName" {
            
            self.form.delegate = nil
            
            if let fileNameNew = formRow.value {
                 self.fileName = CCUtility.removeForbiddenCharactersServer(fileNameNew as! String)
            }
        
            formRow.value = self.fileName
            self.title = fileName
            
            self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let saveButton : UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItemStyle.plain, target: self, action: #selector(save))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = NCBrandColor.sharedInstance.brand
        self.navigationController?.navigationBar.tintColor = NCBrandColor.sharedInstance.brandText
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: NCBrandColor.sharedInstance.brandText]
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
    }
    
    // MARK: - Action
    
    func moveServerUrl(to serverUrlTo: String!, title: String!) {
        
        self.serverUrl = serverUrlTo
        
        if let title = title {
            
            self.titleServerUrl = title
            
        } else {
            
            self.titleServerUrl = "/"
        }
        
        // Update
        let row : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
        row.title = self.titleServerUrl
        self.updateFormRow(row)
    }
    
    @objc func save() {
        
        let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
        guard let name = rowFileName.value else {
            return
        }
        let ext = (name as! NSString).pathExtension.uppercased()
        var fileNameSave = ""
        
        if (ext == "") {
            fileNameSave = name as! String + ".txt"
        } else if (CCUtility.isDocumentModifiableExtension(ext)) {
            fileNameSave = name as! String
        } else {
            fileNameSave = (name as! NSString).deletingPathExtension + ".txt"
        }
        
        guard let directoryID = NCManageDatabase.sharedInstance.getDirectoryID(self.serverUrl) else {
            return
        }
        let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "directoryID == %@ AND fileNameView == %@", directoryID, fileNameSave))
        
        if (metadata != nil) {
            
            let alertController = UIAlertController(title: fileNameSave, message: NSLocalizedString("_file_already_exists_", comment: ""), preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .default) { (action:UIAlertAction) in
            }
            
            let overwriteAction = UIAlertAction(title: NSLocalizedString("_overwrite_", comment: ""), style: .cancel) { (action:UIAlertAction) in
                self.dismissAndUpload(fileNameSave, fileID: metadata!.fileID, directoryID: directoryID)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(overwriteAction)
            
            self.present(alertController, animated: true, completion:nil)
            
        } else {
           let directoryID = NCManageDatabase.sharedInstance.getDirectoryID(self.serverUrl)!
           dismissAndUpload(fileNameSave, fileID: directoryID + fileNameSave, directoryID: directoryID)
        }
    }
    
    func dismissAndUpload(_ fileNameSave: String, fileID: String, directoryID: String) {
        
        self.dismiss(animated: true, completion: {
            
            let data = self.text.data(using: .utf8)
            let success = FileManager.default.createFile(atPath: CCUtility.getDirectoryProviderStorageFileID(fileID, fileNameView: fileNameSave), contents: data, attributes: nil)
            
            if success {
                
                let metadataForUpload = tableMetadata()
                
                metadataForUpload.account = self.appDelegate.activeAccount
                metadataForUpload.date = NSDate()
                metadataForUpload.directoryID = directoryID
                metadataForUpload.fileID = fileID
                metadataForUpload.fileName = fileNameSave
                metadataForUpload.fileNameView = fileNameSave
                metadataForUpload.session = k_upload_session
                metadataForUpload.sessionSelector = selectorUploadFile
                metadataForUpload.status = Int(k_metadataStatusWaitUpload)
                
                _ = NCManageDatabase.sharedInstance.addMetadata(metadataForUpload)
                self.appDelegate.perform(#selector(self.appDelegate.loadAutoDownloadUpload), on: Thread.main, with: nil, waitUntilDone: true)
                
                NCMainCommon.sharedInstance.reloadDatasource(ServerUrl: self.serverUrl, fileID: nil, action: Int32(k_action_NULL))
                
            } else {
                
                self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
            }
        })
    }
    
    func cancel() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {
        
        self.deselectFormRow(sender)
        
        let storyboard : UIStoryboard = UIStoryboard(name: "CCMove", bundle: nil)
        let navigationController = storyboard.instantiateViewController(withIdentifier: "CCMove") as! UINavigationController
        let viewController : CCMove = navigationController.topViewController as! CCMove
        
        viewController.delegate = self;
        viewController.tintColor = NCBrandColor.sharedInstance.brandText
        viewController.barTintColor = NCBrandColor.sharedInstance.brand
        viewController.tintColorTitle = NCBrandColor.sharedInstance.brandText
        viewController.move.title = NSLocalizedString("_select_", comment: "");
        viewController.networkingOperationQueue =  appDelegate.netQueue
        // E2EE
        viewController.includeDirectoryE2EEncryption = true;
        
        navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.present(navigationController, animated: true, completion: nil)
    }
}

//MARK: -

class CreateFormUploadScanDocument: XLFormViewController, CCMoveDelegate {
    
    var serverUrl = ""
    var titleServerUrl = ""
    var arrayImages = [UIImage]()
    var fileName = "scan.pdf"
    var password : PDFPassword = ""
    var compressionQuality: Double = 0.5
    var fileType = "PDF"
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    convenience init(serverUrl: String, arrayImages: [UIImage]) {
        
        self.init()
        
        if serverUrl == CCUtility.getHomeServerUrlActiveUrl(appDelegate.activeUrl) {
            titleServerUrl = "/"
        } else {
            titleServerUrl = (serverUrl as NSString).lastPathComponent
        }
        
        self.serverUrl = serverUrl
        self.arrayImages = arrayImages
        
        initializeForm()
    }
    
    //MARK: XLFormDescriptorDelegate
    
    func initializeForm() {
        
        let form : XLFormDescriptor = XLFormDescriptor(title: NSLocalizedString("_save_settings_", comment: "")) as XLFormDescriptor
        form.rowNavigationOptions = XLFormRowNavigationOptions.stopDisableRow
        
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        // Section: Destination Folder
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_save_path_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "ButtonDestinationFolder", rowType: XLFormRowDescriptorTypeButton, title: self.titleServerUrl)
        row.action.formSelector = #selector(changeDestinationFolder(_:))

        let imageFolder = CCGraphics.changeThemingColorImage(UIImage(named: "folder")!, multiplier:2, color: NCBrandColor.sharedInstance.brandElement) as UIImage
        row.cellConfig["imageView.image"] = imageFolder

        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Section: Quality
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_quality_image_title_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "compressionQuality", rowType: XLFormRowDescriptorTypeSlider)
        row.value = 0.5
        row.title = NSLocalizedString("_quality_medium_", comment: "")
        
        row.cellConfig["slider.minimumTrackTintColor"] = NCBrandColor.sharedInstance.brand

        row.cellConfig["slider.maximumValue"] = 1
        row.cellConfig["slider.minimumValue"] = 0
        row.cellConfig["steps"] = 2

        row.cellConfig["textLabel.textAlignment"] = NSTextAlignment.center.rawValue
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)

        // Section: Password
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_pdf_password_", comment: ""))
        form.addFormSection(section)
        
        row = XLFormRowDescriptor(tag: "password", rowType: XLFormRowDescriptorTypePassword, title: NSLocalizedString("_password_", comment: ""))
        
        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)
        
        section.addFormRow(row)
        
        // Section: File
        
        section = XLFormSectionDescriptor.formSection(withTitle: NSLocalizedString("_file_creation_", comment: ""))
        form.addFormSection(section)
        
        if arrayImages.count == 1 {
            row = XLFormRowDescriptor(tag: "filetype", rowType: XLFormRowDescriptorTypeSelectorSegmentedControl, title: NSLocalizedString("_file_type_", comment: ""))
            row.selectorOptions = ["PDF","JPG"]
            row.value = "PDF"
            
            row.cellConfig["tintColor"] = NCBrandColor.sharedInstance.brand
            row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
            
            section.addFormRow(row)
        }
        
        row = XLFormRowDescriptor(tag: "fileName", rowType: XLFormRowDescriptorTypeAccount, title: NSLocalizedString("_filename_", comment: ""))
        row.value = self.fileName

        row.cellConfig["textLabel.font"] = UIFont.systemFont(ofSize: 15.0)
        
        row.cellConfig["textField.textAlignment"] = NSTextAlignment.right.rawValue
        row.cellConfig["textField.font"] = UIFont.systemFont(ofSize: 15.0)

        section.addFormRow(row)
       
        self.form = form
    }
    
    override func formRowDescriptorValueHasChanged(_ formRow: XLFormRowDescriptor!, oldValue: Any!, newValue: Any!) {
        
        super.formRowDescriptorValueHasChanged(formRow, oldValue: oldValue, newValue: newValue)
        
        if formRow.tag == "fileName" {
            
            self.form.delegate = nil
            
            let fileNameNew = newValue as? String
            
            if fileNameNew != nil {
                self.fileName = CCUtility.removeForbiddenCharactersServer(fileNameNew)
            } else {
                self.fileName = ""
            }
            
            formRow.value = self.fileName
            
            self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
        
        if formRow.tag == "compressionQuality" {
            
            self.form.delegate = nil
            
            //let row : XLFormRowDescriptor  = self.form.formRow(withTag: "descriptionQuality")!
            let newQuality = newValue as? NSNumber
            compressionQuality = (newQuality?.doubleValue)!
            
            if compressionQuality >= 0.0 && compressionQuality <= 0.3  {
                formRow.title = NSLocalizedString("_quality_low_", comment: "")
                compressionQuality = 0.1
            } else if compressionQuality >= 0.4 && compressionQuality <= 0.6 {
                formRow.title = NSLocalizedString("_quality_medium_", comment: "")
                compressionQuality = 0.5
            } else if compressionQuality >= 0.7 && compressionQuality <= 1.0 {
                formRow.title = NSLocalizedString("_quality_high_", comment: "")
                compressionQuality = 0.8
            }
            
            self.updateFormRow(formRow)
            
            self.form.delegate = self
        }
        
        if formRow.tag == "password" {
            let stringPassword = newValue as? String
            if stringPassword != nil {
                password = PDFPassword(stringPassword!)
            } else {
                password = PDFPassword("")
            }
        }
        
        if formRow.tag == "filetype" {
            fileType = newValue as! String
            
            let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
            let rowPassword : XLFormRowDescriptor  = self.form.formRow(withTag: "password")!
            
            // rowFileName
            guard var name = rowFileName.value else {
                return
            }
            if name as! String == "" {
                name = "scan"
            }
            
            let ext = (name as! NSString).pathExtension.uppercased()
            var newFileName = ""
            
            if (ext == "") {
                newFileName = name as! String + "." + fileType.lowercased()
            } else {
                newFileName = (name as! NSString).deletingPathExtension + "." + fileType.lowercased()
            }
            
            rowFileName.value = newFileName
            
            self.updateFormRow(rowFileName)
            
            // rowPassword
            if fileType == "JPG" {
                rowPassword.value = ""
                password = PDFPassword("")
                rowPassword.disabled = true
            } else {
                rowPassword.disabled = false
            }
            
            self.updateFormRow(rowPassword)
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let saveButton : UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("_save_", comment: ""), style: UIBarButtonItemStyle.plain, target: self, action: #selector(save))
        self.navigationItem.rightBarButtonItem = saveButton
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = NCBrandColor.sharedInstance.brand
        self.navigationController?.navigationBar.tintColor = NCBrandColor.sharedInstance.brandText
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: NCBrandColor.sharedInstance.brandText]
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
//        self.tableView.sectionHeaderHeight = 10
//        self.tableView.sectionFooterHeight = 10
//        self.tableView.backgroundColor = NCBrandColor.sharedInstance.backgroundView
        
        
//        let row : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
//        let rowCell = row.cell(forForm: self)
//        rowCell.becomeFirstResponder()
    }
    
    // MARK: - Action
    
    func moveServerUrl(to serverUrlTo: String!, title: String!) {
        
        self.serverUrl = serverUrlTo
        
        if let title = title {
            
            self.titleServerUrl = title
            
        } else {
            
            self.titleServerUrl = "/"
        }
        
        // Update
        let row : XLFormRowDescriptor  = self.form.formRow(withTag: "ButtonDestinationFolder")!
        row.title = self.titleServerUrl
        self.updateFormRow(row)
    }
    
    @objc func save() {
        
        let rowFileName : XLFormRowDescriptor  = self.form.formRow(withTag: "fileName")!
        guard let name = rowFileName.value else {
            return
        }
        if name as! String == "" {
            return
        }
        
        let ext = (name as! NSString).pathExtension.uppercased()
        var fileNameSave = ""
        
        if (ext == "") {
            fileNameSave = name as! String + "." + fileType.lowercased()
        } else {
            fileNameSave = (name as! NSString).deletingPathExtension + "." + fileType.lowercased()
        }
        
        guard let directoryID = NCManageDatabase.sharedInstance.getDirectoryID(self.serverUrl) else {
            return
        }
        let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "directoryID == %@ AND fileNameView == %@", directoryID, fileNameSave))
        
        if (metadata != nil) {
            
            let alertController = UIAlertController(title: fileNameSave, message: NSLocalizedString("_file_already_exists_", comment: ""), preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("_cancel_", comment: ""), style: .default) { (action:UIAlertAction) in
            }
            
            let overwriteAction = UIAlertAction(title: NSLocalizedString("_overwrite_", comment: ""), style: .cancel) { (action:UIAlertAction) in
                NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "directoryID == %@ AND fileNameView == %@", directoryID, fileNameSave), clearDateReadDirectoryID: directoryID)
                self.dismissAndUpload(fileNameSave, fileID: directoryID + fileNameSave, directoryID: directoryID)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(overwriteAction)
            
            self.present(alertController, animated: true, completion:nil)
            
        } else {
            let directoryID = NCManageDatabase.sharedInstance.getDirectoryID(self.serverUrl)!
            dismissAndUpload(fileNameSave, fileID: directoryID + fileNameSave, directoryID: directoryID)
        }
    }
    
    func dismissAndUpload(_ fileNameSave: String, fileID: String, directoryID: String) {
        
        guard let fileNameGenerateExport = CCUtility.getDirectoryProviderStorageFileID(fileID, fileNameView: fileNameSave) else {
            self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
            return
        }
        
        if fileType == "PDF" {
        
            var pdfPages = [PDFPage]()

            //Generate PDF
            for image in self.arrayImages {
                guard let data = UIImageJPEGRepresentation(image, CGFloat(compressionQuality)) else {
                    self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                    return
                }
                let page = PDFPage.image(UIImage(data: data)!)
                pdfPages.append(page)
            }
            
            do {
                try PDFGenerator.generate(pdfPages, to: fileNameGenerateExport, password: password)
            } catch {
                self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                return
            }
        }
        
        if fileType == "JPG" {
            
            guard let data = UIImageJPEGRepresentation(self.arrayImages[0], CGFloat(compressionQuality)) else {
                self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                return
            }
            
            do {
                try data.write(to: NSURL.fileURL(withPath: fileNameGenerateExport), options: .atomic)
            } catch {
                self.appDelegate.messageNotification("_error_", description: "_error_creation_file_", visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.info, errorCode: 0)
                return
            }
        }
        
        //Create metadata for upload
        let metadataForUpload = tableMetadata()
        
        metadataForUpload.account = self.appDelegate.activeAccount
        metadataForUpload.date = NSDate()
        metadataForUpload.directoryID = directoryID
        metadataForUpload.fileID = fileID
        metadataForUpload.fileName = fileNameSave
        metadataForUpload.fileNameView = fileNameSave
        metadataForUpload.session = k_upload_session
        metadataForUpload.sessionSelector = selectorUploadFile
        metadataForUpload.status = Int(k_metadataStatusWaitUpload)
        
        _ = NCManageDatabase.sharedInstance.addMetadata(metadataForUpload)
        self.appDelegate.perform(#selector(self.appDelegate.loadAutoDownloadUpload), on: Thread.main, with: nil, waitUntilDone: true)
        
        NCMainCommon.sharedInstance.reloadDatasource(ServerUrl: self.serverUrl, fileID: nil, action: Int32(k_action_NULL))
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancel() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func changeDestinationFolder(_ sender: XLFormRowDescriptor) {
        
        self.deselectFormRow(sender)
        
        let storyboard : UIStoryboard = UIStoryboard(name: "CCMove", bundle: nil)
        let navigationController = storyboard.instantiateViewController(withIdentifier: "CCMove") as! UINavigationController
        let viewController : CCMove = navigationController.topViewController as! CCMove
        
        viewController.delegate = self;
        viewController.tintColor = NCBrandColor.sharedInstance.brandText
        viewController.barTintColor = NCBrandColor.sharedInstance.brand
        viewController.tintColorTitle = NCBrandColor.sharedInstance.brandText
        viewController.move.title = NSLocalizedString("_select_", comment: "");
        viewController.networkingOperationQueue =  appDelegate.netQueue
        // E2EE
        viewController.includeDirectoryE2EEncryption = true;
        
        navigationController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.present(navigationController, animated: true, completion: nil)
    }
}

class NCCreateScanDocument : NSObject, ImageScannerControllerDelegate {
    
    @objc static let sharedInstance: NCCreateScanDocument = {
        let instance = NCCreateScanDocument()
        return instance
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewController: UIViewController?
    var openScan: Bool = false
    
    @available(iOS 10, *)
    func openScannerDocument(viewController: UIViewController, openScan: Bool) {
        
        self.viewController = viewController
        self.openScan = openScan
        
        let scannerVC = ImageScannerController()
        scannerVC.imageScannerDelegate = self
        self.viewController?.present(scannerVC, animated: true, completion: nil)
    }
    
    @available(iOS 10, *)
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        
        let fileName = CCUtility.createFileName("scan.png", fileDate: Date(), fileType: PHAssetMediaType.image, keyFileName: k_keyFileNameMask, keyFileNameType: k_keyFileNameType, keyFileNameOriginal: k_keyFileNameOriginal)!
        let fileNamePath = CCUtility.getDirectoryScan() + "/" + fileName
        
        // A4 74 DPI : 595 x 842 px 
        
        var image = results.scannedImage
        let imageWidthInPixels = image.size.width * results.scannedImage.scale
        let imageHeightInPixels = image.size.height * results.scannedImage.scale
        
        if imageWidthInPixels > 595 || imageHeightInPixels > 842  {
            image = CCGraphics.scale(image, to: CGSize(width: 595, height: 842), isAspectRation: true)
        }
        
        do {
            try UIImagePNGRepresentation(image)?.write(to: NSURL.fileURL(withPath: fileNamePath), options: .atomic)
        } catch { }
        
        scanner.dismiss(animated: true, completion: {
            if (self.openScan) {
                let storyboard = UIStoryboard(name: "Scan", bundle: nil)
                let controller = storyboard.instantiateInitialViewController()!
                
                controller.modalPresentationStyle = UIModalPresentationStyle.pageSheet
                self.viewController?.present(controller, animated: true, completion: nil)
            }
        })
    }
    
    @available(iOS 10, *)
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 10, *)
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        appDelegate.messageNotification("_error_", description: error.localizedDescription, visible: true, delay: TimeInterval(k_dismissAfterSecond), type: TWMessageBarMessageType.error, errorCode: Int(k_CCErrorInternalError))
    }
}


