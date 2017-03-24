//
//  BuildTimesHistogramViewController.swift
//  BuildTimeInspector
//
//  Created by Jeffrey Blagdon on 2/24/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

import AppKit

class HistogramBar: NSCollectionViewItem {
  weak var mouseDelegate: MouseDelegate?

  @IBOutlet weak var label: NSTextField!
  override func mouseEntered(with event: NSEvent) {
    mouseDelegate?.mouseEntered(sender: self, event: event)
  }

  override func mouseExited(with event: NSEvent) {
    mouseDelegate?.mouseExited(sender: self)
  }

  override func mouseDown(with event: NSEvent) {
    if event.clickCount > 1 {
      mouseDelegate?.doubleClicked(sender: self)
    }
  }

  @IBOutlet weak var barViewTopConstraint: NSLayoutConstraint!

  @IBOutlet weak var barView: NSView!
  var trackingArea: NSTrackingArea? {
    didSet {
      if let oldValue = oldValue {
        view.removeTrackingArea(oldValue)
      }

      if let trackingArea = trackingArea {
        view.addTrackingArea(trackingArea)
      }
    }
  }

  func showTooltip(for buildTime: FunctionBuildTime, event: NSEvent) {
    label.stringValue = ""
  }

  func hideTooltip() {
    label.stringValue = ""
  }
}

extension CGColor {
  static var random: CGColor {
    let randFloat = { CGFloat(arc4random_uniform(230)) / 255.0 }
    let (r, g, b, a) = (randFloat(), randFloat(), randFloat(), randFloat())
    print("\(r) \(g) \(b) \(a)")
    return CGColor(red: r, green: g, blue: b, alpha: a)
  }
}

protocol MouseDelegate: NSObjectProtocol {
  func doubleClicked(sender: NSCollectionViewItem)
  func mouseEntered(sender: NSCollectionViewItem, event: NSEvent)
  func mouseExited(sender: NSCollectionViewItem)
}

extension NSViewController {
  var window: NSWindow? {
    return NSApplication.shared().keyWindow
  }
}

class BuildTimesHistogramViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, MouseDelegate, NSCollectionViewDelegateFlowLayout {
  
  @IBOutlet weak var collectionView: NSCollectionView!

  var buildTimes: [FunctionBuildTime] = [] {
    didSet {
      selectedBuildTimes = []
      collectionView?.reloadData()
    }
  }

  var selectedBuildTimes: [FunctionBuildTime] = []

  static private let baseItemSize: NSSize = NSSize(width: 60, height: 500)
  static private let baseSeparatorWidth: CGFloat = 30

  var itemSize: NSSize = BuildTimesHistogramViewController.baseItemSize {
    didSet {
      updateCollectionView(itemSize: itemSize)
    }
  }

  private func updateCollectionView(itemSize: NSSize) {
    collectionView?.reloadData()
  }

  var itemScale: CGFloat = 1 {
    didSet {
      if let collectionViewSize = collectionView?.bounds.size {
        itemSize = itemSize(collectionViewSize: collectionViewSize, itemScale: itemScale)
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = NSNib(nibNamed: String(describing: HistogramBar.self), bundle: nil)
    collectionView.register(nib, forItemWithIdentifier: String(describing: HistogramBar.self))
    NotificationCenter.default.addObserver(self, selector: #selector(windowResized), name: Notification.Name.NSWindowDidResize, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(windowResized), name: Notification.Name.NSWindowDidEndLiveResize, object: nil)
  }

  @objc private func windowResized() {
    if let collectionViewSize = collectionView?.bounds.size {
      itemSize = itemSize(collectionViewSize: collectionViewSize, itemScale: itemScale)
    }
  }

  private func itemSize(collectionViewSize: NSSize, itemScale: CGFloat) -> NSSize {
    return NSSize(width: BuildTimesHistogramViewController.baseItemSize.width * itemScale, height: collectionViewSize.height * itemScale)
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    collectionView.reloadData()
    if let collectionViewSize = collectionView?.bounds.size {
      itemSize = itemSize(collectionViewSize: collectionViewSize, itemScale: itemScale)
    }
  }

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return buildTimes.count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    guard let histogramBar = collectionView.makeItem(withIdentifier: String(describing: HistogramBar.self), for: indexPath) as? HistogramBar else {
      fatalError()
    }

    let randomColor = CGColor.random
    histogramBar.barView?.layer?.backgroundColor = randomColor
    if indexPath.item < buildTimes.count {
      let buildTime = buildTimes[indexPath.item]
      let maybeLongest = buildTimes.max { (lhs: FunctionBuildTime, rhs: FunctionBuildTime) -> Bool in lhs.buildTimeSeconds < rhs.buildTimeSeconds }
      let buildTimeFraction: Double
      if let longest = maybeLongest {
        buildTimeFraction = buildTime.buildTimeSeconds / longest.buildTimeSeconds
      } else {
        buildTimeFraction = 1
      }

      histogramBar.barViewTopConstraint.constant = itemSize.height * CGFloat(1.0 - buildTimeFraction)
    } else {
      histogramBar.barViewTopConstraint.constant = 0
    }

    histogramBar.mouseDelegate = self
    histogramBar.trackingArea = NSTrackingArea(rect: histogramBar.view.frame, options: [.mouseEnteredAndExited, .activeAlways], owner: histogramBar, userInfo: nil)
//    histogramBar.label.frame = CGRect(x: 0, y: 0, width: histogramBar.view.bounds.size.height, height: histogramBar.view.bounds.size.width)
    histogramBar.label.layer?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(M_PI_2)))
    return histogramBar
  }



  func doubleClicked(sender: NSCollectionViewItem) {
    guard let collectionView = collectionView, let path = collectionView.indexPath(for: sender), path.item < buildTimes.count else {
      return
    }

    let buildTime = buildTimes[path.item]
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
  }

  func mouseEntered(sender: NSCollectionViewItem, event: NSEvent) {
//    guard let histogramBar = sender as? HistogramBar, let path = collectionView.indexPath(for: sender), path.item < buildTimes.count else {
//      return
//    }
//
//    let buildTime = buildTimes[path.item]
//    histogramBar.showTooltip(for: buildTime, event: event)
  }

  func mouseExited(sender: NSCollectionViewItem) {
//    guard let histogramBar = sender as? HistogramBar else { return }
//    histogramBar.hideTooltip()
  }

  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
    return itemSize
  }

}
