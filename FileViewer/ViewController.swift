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

enum ApplescriptKey {
  static var documentPath = "{docPath}"
  static var startRange = "{startRange}"
  static var endRange = "{endRange}"
}

func appleScript(path: String, lineNumber: Int) -> NSAppleScript? {
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

class ViewController: NSViewController {

  @IBOutlet weak var statusLabel: NSTextField!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var selectionTextLabel: NSTextField!

  var buildTimes: [FunctionBuildTime] = [] {
    didSet {
      tableView?.reloadData()
    }
  }

  var selectedBuildTimes: [FunctionBuildTime] = [] {
    didSet {
      updateBuildTimesLabel(buildTimes: selectedBuildTimes)
    }
  }

  private func updateBuildTimesLabel(buildTimes: [FunctionBuildTime]) {
    let countSuffix = buildTimes.count == 1 ? "item" : "items"
    let uniqueFiles = buildTimes.reduce([]) { (accum, buildTime) -> Set<String> in
      var newAccum = accum
      newAccum.insert(buildTime.path)
      return newAccum
    }

    let fileCountSuffix = uniqueFiles.count == 1 ? "file" : "files"
    let sortedBuildTimes = buildTimes.sorted { $0.0.buildTimeSeconds < $0.1.buildTimeSeconds }
    let totalDuration = sortedBuildTimes.map{ $0.buildTimeSeconds }.reduce(0, +)
    let meanDuration: TimeInterval
    if buildTimes.isEmpty {
      meanDuration = 0
    } else {
      meanDuration = totalDuration / Double(buildTimes.count)
    }
    selectionTextLabel.stringValue = "\(buildTimes.count) \(countSuffix) in \(uniqueFiles.count) \(fileCountSuffix)     Total time: \(totalDuration)s     Mean: \(meanDuration)s"
  }

  var sortOrder = BuildTimeOrder.buildTime
  var sortAscending = true

  override func viewDidLoad() {
    super.viewDidLoad()
    statusLabel.stringValue = ""
    updateBuildTimesLabel(buildTimes: selectedBuildTimes)
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    guard let table = notification.object as? NSTableView else {
      return
    }

    let indices = table.selectedRowIndexes
    let buildTimes = indices.flatMap { [unowned self] index -> FunctionBuildTime? in
      guard index < self.buildTimes.count else {
        return nil
      }

      return self.buildTimes[index]
    }

    self.selectedBuildTimes = buildTimes
  }

  @IBAction func doubleClicked(_ sender: Any) {
    guard let table = sender as? NSTableView else {
      return
    }

    guard table.selectedRowIndexes.count == 1 else {
      return
    }

    let row = table.selectedRow
    guard row < self.buildTimes.count && row >= 0 else {
      return
    }

    let buildTime = buildTimes[row]
    let script = appleScript(path: buildTime.path, lineNumber: buildTime.lineNumber)
    var dict: NSDictionary? = nil
    let pointer: UnsafeMutablePointer<NSDictionary?> = UnsafeMutablePointer(&dict)
    let autoreleasingPointer: AutoreleasingUnsafeMutablePointer<NSDictionary?> = AutoreleasingUnsafeMutablePointer(pointer)
    if let script = script  {
      script.executeAndReturnError(autoreleasingPointer)
      if let dict = dict {
        print("Error executing applescript: \(dump(dict))")
      }
    }

    //    script?.executeAndReturnError(pointer)
    print(buildTime)
  }

  override var representedObject: Any? {
    didSet {
      if let url = representedObject as? URL {
        let data: Data
        do {
          try data = Data(contentsOf: url, options: [])
        } catch {
          print("error loading data: \(error)")
          return
        }

        let str = String(data: data, encoding: .utf8)
        let lines = str?.components(separatedBy: .newlines) ?? []
        self.buildTimes = lines.prefix(10).flatMap { readout in tryAndPrintError { try FunctionBuildTime(culpritsReadout: readout) } }
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




