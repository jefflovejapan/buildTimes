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


class ViewController: NSViewController {

  @IBOutlet weak var statusLabel: NSTextField!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var selectionTextLabel: NSTextField!

  let descriptorTime = NSSortDescriptor(key: BuildTimeOrder.buildTime.rawValue, ascending: true)
  let descriptorPath = NSSortDescriptor(key: BuildTimeOrder.path.rawValue, ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
  let descriptorFunctionName = NSSortDescriptor(key: BuildTimeOrder.functionName.rawValue, ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
  let descriptorLineNumber = NSSortDescriptor(key: BuildTimeOrder.lineNumber.rawValue, ascending: true)

  var buildTimes: [FunctionBuildTime] = [] {
    didSet {
      selectedBuildTimes = []
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

    let stdDev: Double

    if buildTimes.isEmpty {
      stdDev = 0
    } else {
      let sumSigmaSquared = sortedBuildTimes.reduce(0) { (accum, buildTime) -> Double in
        let term = (buildTime.buildTimeSeconds - meanDuration) * (buildTime.buildTimeSeconds - meanDuration)
        return accum + term
      }

      let variance = sumSigmaSquared / Double(buildTimes.count)
      stdDev = sqrt(variance)
    }

    selectionTextLabel.stringValue = "\(buildTimes.count) \(countSuffix) in \(uniqueFiles.count) \(fileCountSuffix)     Total time: \(totalDuration)s     Mean: \(meanDuration)s     Std dev: \(stdDev)s"
  }

  var sortOrder = BuildTimeOrder.buildTime
  var sortAscending = true

  override func viewDidLoad() {
    super.viewDidLoad()
    statusLabel.stringValue = ""
    updateBuildTimesLabel(buildTimes: selectedBuildTimes)
    tableView.tableColumns[0].sortDescriptorPrototype = descriptorTime
    tableView.tableColumns[1].sortDescriptorPrototype = descriptorPath
    tableView.tableColumns[2].sortDescriptorPrototype = descriptorFunctionName
    tableView.tableColumns[3].sortDescriptorPrototype = descriptorLineNumber
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
    let script = NSAppleScript.xcodeMakeSelection(path: buildTime.path, lineNumber: buildTime.lineNumber)
    var dict: NSDictionary? = nil
    let pointer: UnsafeMutablePointer<NSDictionary?> = UnsafeMutablePointer(&dict)
    let autoreleasingPointer: AutoreleasingUnsafeMutablePointer<NSDictionary?> = AutoreleasingUnsafeMutablePointer(pointer)
    if let script = script  {
      script.executeAndReturnError(autoreleasingPointer)
      if let dict = dict {
        print("Error executing applescript: \(dump(dict))")
      }
    }

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
        self.buildTimes = lines.flatMap { readout in tryAndPrintError { try FunctionBuildTime(culpritsReadout: readout) } }
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

  typealias BuildTimeSortDescriptor = SortDescriptor<FunctionBuildTime>

  func sortDescriptors(grossDescriptors: [NSSortDescriptor]) -> [BuildTimeSortDescriptor] {
    return grossDescriptors.reduce([], { (accum, descriptor) -> [BuildTimeSortDescriptor] in
      guard let key = descriptor.key, let ordering = BuildTimeOrder(rawValue: key) else {
        return accum
      }

      var newAccum = accum
      let ascending = descriptor.ascending
      let newDescriptor: BuildTimeSortDescriptor
      switch (ordering) {
      case .buildTime:
        newDescriptor = sortDescriptor(key: { (buildTime: FunctionBuildTime) -> TimeInterval in buildTime.buildTimeSeconds }, ascending: ascending, { lhs in
          return { rhs in
            if lhs < rhs {
              return .orderedAscending
            } else if lhs > rhs {
              return .orderedDescending
            } else {
              return .orderedSame
            }
          }
        })
      case .path:
        newDescriptor = sortDescriptor(key: { (buildTime: FunctionBuildTime) -> String in buildTime.path }, ascending: ascending, { lhs in
          return { rhs in
            if lhs < rhs {
              return .orderedAscending
            } else if lhs > rhs {
              return .orderedDescending
            } else {
              return .orderedSame
            }
          }
        })

      case .functionName:
        newDescriptor = sortDescriptor(key: { (buildTime: FunctionBuildTime) -> String in buildTime.functionName }, ascending: ascending, { lhs in
          return { rhs in
            if lhs < rhs {
              return .orderedAscending
            } else if lhs > rhs {
              return .orderedDescending
            } else {
              return .orderedSame
            }
          }
        })

      case .lineNumber:
        newDescriptor = sortDescriptor(key: { (buildTime: FunctionBuildTime) -> Int in buildTime.lineNumber }, ascending: ascending, { lhs in
          return { rhs in
            if lhs < rhs {
              return .orderedAscending
            } else if lhs > rhs {
              return .orderedDescending
            } else {
              return .orderedSame
            }
          }
        })

      }

      newAccum.append(newDescriptor)
      return newAccum
    })
  }

  func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    tableView.deselectAll(nil)
    let newDescriptors = tableView.sortDescriptors
    let goodDescriptors = sortDescriptors(grossDescriptors: newDescriptors)
    let singleDescriptor = combine(sortDescriptors: goodDescriptors)
    self.buildTimes.sort(by: singleDescriptor)
  }
}




