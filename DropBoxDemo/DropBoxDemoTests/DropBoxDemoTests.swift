//
//  DropBoxDemoTests.swift
//  DropBoxDemoTests
//
//  Created by prabhjot singh on 7/29/16.
//  Copyright © 2016 Prabhjot Singh. All rights reserved.
//

import XCTest
@testable import DropBoxDemo

class DropBoxDemoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
            let paths = NSSearchPathForDirectoriesInDomains(.AllApplicationsDirectory, .UserDomainMask, true)
            print(paths)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
