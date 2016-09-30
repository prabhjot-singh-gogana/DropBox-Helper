//
//  ViewController.swift
//  DropBoxDemo
//
//  Created by prabhjot singh on 7/29/16.
//  Copyright © 2016 Prabhjot Singh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let dropBoxHelper = DropBoxHelper()
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var segmentBar: UISegmentedControl!
    @IBOutlet weak var textFieldPath: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        showListOfDirectories()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func linkButtonPressed(sender: AnyObject) {
        let pathEnum = segmentBar.selectedSegmentIndex == 0 ? FileDirectories.Library(apendPath: "\(textFieldPath.text!)") : FileDirectories.Document(apendPath: "\(textFieldPath.text!)")
        
        dropBoxHelper.fileLimitInMB = 10 //variable which checks the limit of the file in MB
        dropBoxHelper.restrictedExtenstions = ["txt"]
        //method used to download the file from dropbox
        dropBoxHelper.getFileDataFromDropBox(pathEnum, controller: self) { (obj, isSuccess) in
            if isSuccess == true {
                print(obj.debugDescription)
                self.showListOfDirectories()
            }
        }
        
        // User can use following methods as well
//        DropBoxHelper(controller: self) { (obj, isSuccess) in
//            
//        }
        
//        DropBoxHelper(pathToSave: .Library(apendPath: "/Folder Name/"), controller: self) { (obj, isSuccess) in
//            
//        }
        
    }

    func showListOfDirectories() {
        let fileManager = NSFileManager.defaultManager()
        do {
            let docsArray = try fileManager.subpathsOfDirectoryAtPath(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
            let libArray = try fileManager.subpathsOfDirectoryAtPath(NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0])
            let docsList = "Document = \(docsArray.debugDescription)"
            let libList = "Library = \(libArray.debugDescription)"
            txtView.text = "\(docsList)\n\(libList)"
        } catch {
            print(error)
        }
    }

}