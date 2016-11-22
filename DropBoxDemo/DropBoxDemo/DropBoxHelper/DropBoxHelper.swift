//
//  DropBoxHelper.swift
//  DropBoxDemo
//
//  Created by prabhjot singh on 7/29/16.
//  Copyright © 2016 Prabhjot Singh. All rights reserved.
//

internal typealias DropBoxFileDataClosure = (_ obj: FileDropBox?, _ isSuccess: Bool) -> Void

/**
 *  Model of a DropBox File
 */
struct  FileDropBox {
    var fileDownloadLink: URL? // url of file
    var fileName: String? // name of the file
    var fileSize: Int64? // size of the File
    var iconURL: URL? // url of the icon
    var isDownloadedOnLocal: Bool? // bool variable will check if the file is downloaded or not
    var localPath: String? // path(local) of the file where it downloads
    var fileData: Data? // data of the file
    var fileType: String? { // extension of the file
        get {
            if fileName != nil {
                if fileName!.components(separatedBy: ".").count > 1 {
                    return fileName?.components(separatedBy: ".").last!
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
    case library(apendPath: String)
    case document(apendPath: String)
    
    /**
     fetch the path and returns string
     - returns: pathh in string
     */
    fileprivate func fullPath() -> String {
        switch self {
        case let .library(path):
            let dirPath = self.getPath(.libraryDirectory)
            return("\(dirPath)/\(path)")
        case let .document(path):
            let dirPath = self.getPath(.documentDirectory)
            return("\(dirPath)/\(path)")

        }
    }
    /**
     private function used to fetch the document directory path
     - parameter serachPath: NSSearchPathDirectory object
     - returns: returns string path
     */
    fileprivate func getPath(_ serachPath: FileManager.SearchPathDirectory) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(serachPath, .userDomainMask, true)
        return paths[0]
    }
}

/// DropBoxHelepr class is the helper class which is used to download the file from dropbox with just in 2-3 lines of code
class DropBoxHelper {
    
// Private variables
    fileprivate var dropBoxFileClosure: DropBoxFileDataClosure? // closure which calls back the FileDropBox model and success bool when file downloaded or failure
    fileprivate var pathToSave: FileDirectories? // enum which will fetch the ios library and document path
    fileprivate var delegate: UIViewController? // controller object
    fileprivate var maxDownloadLimitInMB: Int64 { // variable which converts the KB into MB
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
    init (pathToSave: FileDirectories = .document(apendPath: ""), controller: UIViewController, dropBoxFileDataClosure: @escaping DropBoxFileDataClosure) {
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
    internal func getFileDataFromDropBox(_ pathToSave: FileDirectories = .document(apendPath: ""), controller: UIViewController, dropBoxFileDataClosure: @escaping DropBoxFileDataClosure) {
        self.pathToSave = pathToSave
        self.dropBoxFileClosure = dropBoxFileDataClosure
        self.delegate = controller
        self.fetchFileDataFromDBChooser()
    }
    
    /**
     used to fetch the file metadata data from dropbox
     */
    fileprivate func fetchFileDataFromDBChooser() {
        DBChooser.default().open(for: DBChooserLinkTypeDirect, from: delegate) { (results) in
            guard let resultsArray = results as? [DBChooserResult], resultsArray.count > 0 else {
                self.dropBoxFileClosure!(nil, false)
                return
            }
            
            var fileDropBox = self.setFileDropBoxObj(resultsArray[0])
            
            if self.hasLimitedSize(fileDropBox.fileSize!) == false || self.hasRestrictedFileType(fileDropBox.fileType!) == false {
                self.dropBoxFileClosure!(nil, false)
                return
            }
            
            self.downloadTheFileAsync(fileDropBox, dataHandler: { (fileData: Data?, success: Bool) in
                if success == true {
                    fileDropBox.fileData = fileData
                    fileDropBox.localPath = fileDropBox.localPath!.replacingOccurrences(of: "//", with: "/")
                    
                    if self.isSaveDataToLocal(fileDropBox) == true {
                        fileDropBox.isDownloadedOnLocal = true
                        self.dropBoxFileClosure!(fileDropBox, true)
                    } else {
                        self.dropBoxFileClosure!(fileDropBox, false)
                    }
                } else {
                    self.dropBoxFileClosure!(fileDropBox, false)
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
    
    fileprivate func hasLimitedSize(_ fileSize: Int64) -> Bool {
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
    fileprivate func hasRestrictedFileType(_ fileType: String) -> Bool {
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
    fileprivate func setFileDropBoxObj(_ dbChooser: DBChooserResult) -> FileDropBox {
        return  FileDropBox(fileDownloadLink: dbChooser.link, fileName: dbChooser.name, fileSize: dbChooser.size, iconURL: dbChooser.iconURL, isDownloadedOnLocal: false, localPath: pathToSave!.fullPath(), fileData: nil)
    }
    
    /**
     used to download the data through file url asynchrounously
     
     - parameter fileDropBox: FileDropBox object
     - parameter dataHandler: which handles the nsadata and download status
     */
    fileprivate func downloadTheFileAsync(_ fileDropBox: FileDropBox, dataHandler: @escaping (_ fileData: Data?, _ success: Bool) -> Void) {
        
        if fileDropBox.fileDownloadLink != nil {
            
            DispatchQueue.global().async {
                let fileData =  try? Data(contentsOf: fileDropBox.fileDownloadLink!)
                DispatchQueue.main.sync(execute: {
                    if fileData!.count > 0 {
                        dataHandler(fileData, true)
                    } else {
                        dataHandler(nil, false)
                    }
                })
            }
            
        } else {
            dataHandler(nil, false)
        }
    }
    
    /**
     function which saves the data into file
     
     - parameter fileObj: FileDropBox object
     
     - returns: bool which tells file successfully saved in file or not
     */
    fileprivate func isSaveDataToLocal(_ fileObj: FileDropBox) -> Bool {
        if createFolderIfNotExist(fileObj.localPath!) {
            var fullPath = fileObj.localPath! + "/\(fileObj.fileName!)"
            fullPath = fullPath.replacingOccurrences(of: "//", with: "/")
            return ((try? fileObj.fileData!.write(to: URL(fileURLWithPath: fullPath), options: [.atomic])) != nil)
        } else {
            return false
        }
    }
    
    /**
     this method will create the folder if not exist
     
     - parameter filePath: it is the local path where file will be saved
     
     - returns: if not able to create the directories the returns false otherwise true
     */
    fileprivate func createFolderIfNotExist(_ filePath: String) -> Bool {
        
        if !FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
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
    fileprivate func showAlert(_ title: String, message: String) {
        
        if NSClassFromString("UIAlertController") != nil { // Check if UIAlertController class exists
            let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let alertAction: UIAlertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(alertAction)
            self.delegate?.present(alertController, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(title: title, message: message, delegate: self.delegate, cancelButtonTitle: "Ok")
            alertView.show()
        }
    }
}
