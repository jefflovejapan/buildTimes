//
//  FileViewerTests.swift
//  FileViewerTests
//
//  Created by Jeffrey Blagdon on 1/27/17.
//  Copyright © 2017 razeware. All rights reserved.
//

import XCTest
@testable import FileViewer

class FileViewerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReadoutWithSpaces() {
      let readout = "97.5ms\t/Users/jeff/gamechanger/gcios/baseball_sc/Modules/BatsScoring/Scorekeeping/Side Left View/Stats Tables/GCBatsInGameStatViewController.swift:17:14\tprivate func makeStatEntry(_ dataSource: GCBatsTeamGameStatTableDataSource, column: Int, value: Any!, playerId: Any? = default) -> GCStatCollectionStatEntry"
      let buildTime = try! FunctionBuildTime(culpritsReadout: readout)
      XCTAssert(buildTime.lineNumber == 17)
      
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
