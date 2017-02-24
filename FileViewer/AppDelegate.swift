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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {

    let tableItem = NSMenuItem(title: "Table", action: #selector(tableItemSelected), keyEquivalent: "1")
    let histogramItem = NSMenuItem(title: "Histogram", action: #selector(histogramItemSelected), keyEquivalent: "2")

    guard let menu = NSApplication.shared().mainMenu else {
      return
    }

    let maybeViewItem = menu.items.first { $0.title == "View" }
    if let viewItem = maybeViewItem {
      viewItem.submenu?.addItem(tableItem)
      viewItem.submenu?.addItem(histogramItem)
    }

    dump(NSApplication.shared().mainMenu)
  }

  @objc func tableItemSelected() {
    guard let controller = NSApplication.shared().keyWindow?.windowController?.contentViewController else {
      return
    }

    switch controller {
    case let histogramController as BuildTimesHistogramViewController:
      guard let tableController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: String(describing: BuildTimesTableViewController.self)) as? BuildTimesTableViewController else {
        return
      }

      tableController.buildTimes = histogramController.buildTimes
      NSApplication.shared().keyWindow?.windowController?.contentViewController = tableController
    default:
      return
    }
  }

  @objc func histogramItemSelected() {
    guard let controller = NSApplication.shared().keyWindow?.windowController?.contentViewController else {
      return
    }

    switch controller {
    case let tableController as BuildTimesTableViewController:
      guard let histogram = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: String(describing: BuildTimesHistogramViewController.self)) as? BuildTimesHistogramViewController else {
        return
      }

      histogram.buildTimes = tableController.buildTimes
      NSApplication.shared().keyWindow?.windowController?.contentViewController = histogram
    default:
      return
    }
  }
}

