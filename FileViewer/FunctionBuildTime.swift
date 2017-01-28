//
//  FunctionBuildTime.swift
//  FileViewer
//
//  Created by Jeffrey Blagdon on 1/28/17.
//  Copyright © 2017 razeware. All rights reserved.
//

import Foundation

class FunctionBuildTime: NSObject {
  var buildTimeSeconds: TimeInterval
  var path: String
  var functionName: String
  var lineNumber: Int

  init (culpritsReadout: String) throws {
    let comps: [String] = culpritsReadout.components(separatedBy: "\t")
    guard let firstComp = comps.first else {
      throw FunctionBuildTimeInitError.noFirstComponent(readout: culpritsReadout)
    }

    guard String(firstComp.characters.suffix(2)) == "ms" else {
      throw FunctionBuildTimeInitError.invalidFirstComponent(readout: culpritsReadout, component: firstComp)
    }

    let withoutMS = firstComp.characters.dropLast(2)
    guard let timeMS = Double(String(withoutMS)) else {
      throw FunctionBuildTimeInitError.unableToCreateTime(readout: culpritsReadout)
    }

    let remaining = comps.dropFirst()
    guard let pathLineCol = remaining.first else {
      throw FunctionBuildTimeInitError.tooFewComponents(readout: culpritsReadout)
    }

    let pathComps = pathLineCol.components(separatedBy: ":")
    guard pathComps.count >= 2 else {
      throw FunctionBuildTimeInitError.noLineNumberInPath(readout: culpritsReadout, path: pathLineCol)
    }

    let path = pathComps[0]
    let lineStr = pathComps[1]
    guard let line = Int(lineStr) else {
      throw FunctionBuildTimeInitError.invalidLineNumber(readout: culpritsReadout, lineNo: lineStr)
    }

    let functionName = remaining.dropFirst().joined(separator: " ")

    self.buildTimeSeconds = timeMS / 1000
    self.path = String(path)
    self.functionName = functionName.isEmpty ? "*** NO FUNCTION NAME ***" : functionName
    self.lineNumber = line
  }
}
