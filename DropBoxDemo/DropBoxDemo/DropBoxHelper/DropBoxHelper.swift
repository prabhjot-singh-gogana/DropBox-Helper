//
//  DropBoxHelper.swift
//  DropBoxDemo
//
//  Created by prabhjot singh on 7/29/16.
//  Copyright © 2016 Prabhjot Singh. All rights reserved.
//

internal typealias DropBoxFileDataClosure = (obj: FileDropBox?, isSuccess: Bool) -> Void

/**
 *  Model of a DropBox File
 */
struct  FileDropBox {
    var fileDownloadLink: NSURL? // url of file
    var fileName: String? // name of the file
    var fileSize: Int64? // size of the File
    var iconURL: NSURL? // url of the icon
    var isDownloadedOnLocal: Bool? // bool variable will check if the file is downloaded or not
    var localPath: String? // path(local) of the file where it downloads
    var fileData: NSData? // data of the file
    var fileType: String? { // extension of the file
        get {
            if fileName != nil {
                if fileName!.componentsSeparatedByString(".").count > 1 {
                    return fileName?.componentsSeparatedByString(".").last!
                } else {
                    return ""
                }
            } else {
                return ""
            }
        }
        set {
            fileType = newValue
        }
    }
}

/**
 FileDirectories is the enum which will fetch the ios library and document path
 
 - Library:       case which is used to fetch the library path and can append the path by appending the string
 - Document:      case which is used to fetch the document path and can append the path by appending the string
 */
enum FileDirectories {
    case Library(apendPath: String)
    case Document(apendPath: String)
    
    /**
     fetch the path and returns string
     - returns: pathh in string
     */
    private func fullPath() -> String {
        switch self {
        case let .Library(path):
            let dirPath = self.getPath(.LibraryDirectory)
            return("\(dirPath)/\(path)")
        case let .Document(path):
            let dirPath = self.getPath(.DocumentDirectory)
            return("\(dirPath)/\(path)")

        }
    }
    /**
     private function used to fetch the document directory path
     - parameter serachPath: NSSearchPathDirectory object
     - returns: returns string path
     */
    private func getPath(serachPath: NSSearchPathDirectory) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(serachPath, .UserDomainMask, true)
        return paths[0]
    }
}

/// DropBoxHelepr class is the helper class which is used to download the file from dropbox with just in 2-3 lines of code
class DropBoxHelper {
    
// Private variables
    private var dropBoxFileClosure: DropBoxFileDataClosure? // closure which calls back the FileDropBox model and success bool when file downloaded or failure
    private var pathToSave: FileDirectories? // enum which will fetch the ios library and document path
    private var delegate: UIViewController? // controller object
    private var maxDownloadLimitInMB: Int64 { // variable which converts the KB into MB
        get {
            return fileLimitInMB * 1000000
        }
        set {
            fileLimitInMB = newValue
        }
    }
    
    var restrictedExtenstions: [String]? // extension like png, txt, mp4 etc

// Public variable
    var fileLimitInMB: Int64 = 10 // public variable which checks the limit of the file in MB
    
    /**
       required intializer without params
     */
    required init() {
        
    }

    /**
     intializers which initialize DropBoxHelper
     
     - parameter pathToSave:             path(local) of the file where it downloads
     - parameter controller:             controller object
     - parameter dropBoxFileDataClosure: closure which calls back the FileDropBox model and success bool when file downloaded or failure
     
     - returns: DropBoxHelper object
     */
    init (pathToSave: FileDirectories = .Document(apendPath: ""), controller: UIViewController, dropBoxFileDataClosure: DropBoxFileDataClosure) {
        self.pathToSave = pathToSave
        self.dropBoxFileClosure = dropBoxFileDataClosure
        self.delegate = controller
        self.fetchFileDataFromDBChooser()
    }
    
    /**
     method used to download the file from dropbox
     
     - parameter pathToSave:             path(local) of the file where it downloads
     - parameter controller:             controller object
     - parameter dropBoxFileDataClosure: closure which calls back the FileDropBox model and success bool when file downloaded or failure
     */
    internal func getFileDataFromDropBox(pathToSave: FileDirectories = .Document(apendPath: ""), controller: UIViewController, dropBoxFileDataClosure: DropBoxFileDataClosure) {
        self.pathToSave = pathToSave
        self.dropBoxFileClosure = dropBoxFileDataClosure
        self.delegate = controller
        self.fetchFileDataFromDBChooser()
    }
    
    /**
     used to fetch the file metadata data from dropbox
     */
    private func fetchFileDataFromDBChooser() {
        DBChooser.defaultChooser().openChooserForLinkType(DBChooserLinkTypeDirect, fromViewController: delegate) { (results) in
            guard let resultsArray = results as? [DBChooserResult] where resultsArray.count > 0 else {
                self.dropBoxFileClosure!(obj: nil, isSuccess: false)
                return
            }
            
            var fileDropBox = self.setFileDropBoxObj(resultsArray[0])
            
            if self.hasLimitedSize(fileDropBox.fileSize!) == false || self.hasRestrictedFileType(fileDropBox.fileType!) == false {
                self.dropBoxFileClosure!(obj: nil, isSuccess: false)
                return
            }
            
            self.downloadTheFileAsync(fileDropBox, dataHandler: { (fileData: NSData?, success: Bool) in
                if success == true {
                    fileDropBox.fileData = fileData
                    fileDropBox.localPath = fileDropBox.localPath!.stringByReplacingOccurrencesOfString("//", withString: "/")
                    
                    if self.isSaveDataToLocal(fileDropBox) == true {
                        fileDropBox.isDownloadedOnLocal = true
                        self.dropBoxFileClosure!(obj: fileDropBox, isSuccess: true)
                    } else {
                        self.dropBoxFileClosure!(obj: fileDropBox, isSuccess: false)
                    }
                } else {
                    self.dropBoxFileClosure!(obj: fileDropBox, isSuccess: false)
                    return
                }
            })
            
        }
    }
    
    /**
     this methods checks the limited size of the file
     
     - parameter fileSize: fileSize will be compare with required size
     
     - returns: returns true and false
     */
    
    private func hasLimitedSize(fileSize: Int64) -> Bool {
        if fileSize >= self.maxDownloadLimitInMB {
            let errorMessage = "Downloadable file should not more than \(self.fileLimitInMB) MB size"
            print(errorMessage)
            self.showAlert("Size Error", message: errorMessage)
            
            return false
        }
        return true
    }
    
    /**
     checks the file type from restriction array
     
     - parameter fileType: extension of the file
     
     - returns: if array contains the type the it will return false otherwise 0
     */
    private func hasRestrictedFileType(fileType: String) -> Bool {
        if self.restrictedExtenstions != nil {
            if self.restrictedExtenstions!.contains(fileType) {
                let errorMessage = "\(fileType) is restricted"
                print(errorMessage)
                self.showAlert("Type Error", message: errorMessage)
                return false
            }
        }
        return true
    }
    
    /**
     used to set the FileDropBox through DBChooserResult
     
     - parameter dbChooser: DBChooserResult object
     
     - returns: FileDropBox object
     */
    private func setFileDropBoxObj(dbChooser: DBChooserResult) -> FileDropBox {
        return  FileDropBox(fileDownloadLink: dbChooser.link, fileName: dbChooser.name, fileSize: dbChooser.size, iconURL: dbChooser.iconURL, isDownloadedOnLocal: false, localPath: pathToSave!.fullPath(), fileData: nil)
    }
    
    /**
     used to download the data through file url asynchrounously
     
     - parameter fileDropBox: FileDropBox object
     - parameter dataHandler: which handles the nsadata and download status
     */
    private func downloadTheFileAsync(fileDropBox: FileDropBox, dataHandler: (fileData: NSData?, success: Bool) -> Void) {
        
        if fileDropBox.fileDownloadLink != nil {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    
                    let fileData =  NSData(contentsOfURL: fileDropBox.fileDownloadLink!)
                    dispatch_sync(dispatch_get_main_queue(), {
                            if fileData!.length > 0 {
                                dataHandler(fileData: fileData, success: true)
                            } else {
                                dataHandler(fileData: nil, success: false)
                            }
                        })
                })
        } else {
            dataHandler(fileData: nil, success: false)
        }
    }
    
    /**
     function which saves the data into file
     
     - parameter fileObj: FileDropBox object
     
     - returns: bool which tells file successfully saved in file or not
     */
    private func isSaveDataToLocal(fileObj: FileDropBox) -> Bool {
        if createFolderIfNotExist(fileObj.localPath!) {
            var fullPath = fileObj.localPath! + "/\(fileObj.fileName!)"
            fullPath = fullPath.stringByReplacingOccurrencesOfString("//", withString: "/")
            return fileObj.fileData!.writeToFile(fullPath, atomically: true)
        } else {
            return false
        }
    }
    
    /**
     this method will create the folder if not exist
     
     - parameter filePath: it is the local path where file will be saved
     
     - returns: if not able to create the directories the returns false otherwise true
     */
    private func createFolderIfNotExist(filePath: String) -> Bool {
        
        if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(filePath, withIntermediateDirectories: true, attributes: nil)
                return true
            } catch let createDirectoryError as NSError {
                print("Error with creating directory at path: \(createDirectoryError.localizedDescription)")
            }
            return false
        } else {
            return true
        }
    }
    
    /**
     used to show the Alert
     
     - parameter title:   alert Title
     - parameter message: alert Message
     */
    private func showAlert(title: String, message: String) {
        
        if NSClassFromString("UIAlertController") != nil { // Check if UIAlertController class exists
            let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let alertAction: UIAlertAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alertController.addAction(alertAction)
            self.delegate?.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(title: title, message: message, delegate: self.delegate, cancelButtonTitle: "Ok")
            alertView.show()
        }
    }
}