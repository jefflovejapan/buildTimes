/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Cocoa

enum FunctionBuildTimeInitError: Error {
  case noFirstComponent(readout: String)
  case invalidFirstComponent(readout: String, component: String)
  case unableToCreateTime(readout: String)
  case tooFewComponents(readout: String)
  case noLineNumberInPath(readout: String, path: String)
  case invalidLineNumber(readout: String, lineNo: String)
  case noFunctionName(readout: String)
}

func tryAndPrintError<T>(_ f: () throws -> T) -> T? {
  do {
    return try f()
  } catch {
    print(error)
    return nil
  }
}

enum BuildTimeOrder: String {
  case buildTime = "buildTime"
  case path = "path"
  case functionName = "functionName"
  case lineNumber = "lineNumber"
}

struct FunctionBuildTime {
  var buildTimeSeconds: TimeInterval
  var path: String
  var functionName: String
  var lineNumber: Int

  init (culpritsReadout: String) throws {
    let comps: [String] = culpritsReadout.components(separatedBy: .whitespaces)
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

class ViewController: NSViewController {

  @IBOutlet weak var statusLabel: NSTextField!
  @IBOutlet weak var tableView: NSTableView!

  var buildTimes: [FunctionBuildTime] = [] {
    didSet {
      tableView?.reloadData()
    }
  }

  var sortOrder = BuildTimeOrder.buildTime
  var sortAscending = true

  override func viewDidLoad() {
    super.viewDidLoad()
    statusLabel.stringValue = ""
  }

  @IBAction func doubleClicked(_ sender: Any) {
    guard let table = sender as? NSTableView else {
      return
    }

    let row = table.selectedRow
    guard row < self.buildTimes.count else {
      return
    }

    let buildTime = buildTimes[row]
    print(buildTime)
  }

  override var representedObject: Any? {
    didSet {
      if let url = representedObject as? URL {
        print("Represented object: \(url)")

        let data: Data
        do {
          try data = Data(contentsOf: url, options: [])
        } catch {
          print("error loading data: \(error)")
          return
        }

        let str = String(data: data, encoding: .utf8)
        let lines = str?.components(separatedBy: .newlines) ?? []
        self.buildTimes = lines.flatMap { readout in tryAndPrintError { try FunctionBuildTime(culpritsReadout: readout) } }
        print(buildTimes)
      }
    }
  }
}

extension ViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.buildTimes.count
  }
}

extension ViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard row < self.buildTimes.count, let column = tableColumn else {
      return nil
    }

    guard let cell = tableView.make(withIdentifier: "whatever", owner: nil) as? NSTableCellView else {
      return nil
    }

    guard let columnType = BuildTimeOrder(rawValue: column.identifier) else {
      return nil
    }

    let buildTime = buildTimes[row]

    switch columnType {
    case .buildTime:
      cell.textField?.stringValue = "\(buildTime.buildTimeSeconds) s"
    case .functionName:
      cell.textField?.stringValue = buildTime.functionName
    case .lineNumber:
      cell.textField?.stringValue = String(buildTime.lineNumber)
    case .path:
      cell.textField?.stringValue = buildTime.path
    }

    return cell
  }
}




