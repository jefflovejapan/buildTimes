//
//  AppleScript.swift
//  FileViewer
//
//  Created by Jeffrey Blagdon on 1/28/17.
//  Copyright © 2017 razeware. All rights reserved.
//

import Foundation

fileprivate enum ApplescriptKey {
  static let documentPath = "{docPath}"
  static let startRange = "{startRange}"
  static let endRange = "{endRange}"
}

enum BuildTimeOrder: String {
  case buildTime = "buildTime"
  case path = "path"
  case functionName = "functionName"
  case lineNumber = "lineNumber"
}

enum FunctionBuildTimeInitError: Error {
  case noFirstComponent(readout: String)
  case invalidFirstComponent(readout: String, component: String)
  case unableToCreateTime(readout: String)
  case tooFewComponents(readout: String)
  case noLineNumberInPath(readout: String, path: String)
  case invalidLineNumber(readout: String, lineNo: String)
  case noFunctionName(readout: String)
}


extension NSAppleScript {
  static func xcodeMakeSelection(path: String, lineNumber: Int) -> NSAppleScript? {
    guard let templatePath = Bundle.main.path(forResource: "applescript", ofType: "txt"),
      let templateData = FileManager.default.contents(atPath: templatePath),
      let templateStr = String(data: templateData, encoding: .utf8) else {
        return nil
    }

    let script = templateStr.replacingOccurrences(of: ApplescriptKey.documentPath, with: "\"\(path)\"", options: [], range: nil)
      .replacingOccurrences(of: ApplescriptKey.startRange, with: String(lineNumber), options: [], range: nil)
      .replacingOccurrences(of: ApplescriptKey.endRange, with: String(99999), options: [], range: nil)
      .trimmingCharacters(in: .newlines)

    return NSAppleScript(source: script)
  }
}
