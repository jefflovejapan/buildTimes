//
//  BuildTimesHistogramViewController.swift
//  BuildTimeInspector
//
//  Created by Jeffrey Blagdon on 2/24/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

import AppKit

class HistogramBar: NSCollectionViewItem {
}

extension CGColor {
  static var random: CGColor {
    let randFloat = { CGFloat(arc4random_uniform(255)) / 255.0 }
    let (r, g, b, a) = (randFloat(), randFloat(), randFloat(), randFloat())
    print("\(r) \(g) \(b) \(a)")
    return CGColor(red: r, green: g, blue: b, alpha: a)
  }
}

class BuildTimesHistogramViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource {
  
  @IBOutlet weak var collectionView: NSCollectionView!

  var buildTimes: [FunctionBuildTime] = [] {
    didSet {
      selectedBuildTimes = []
      collectionView?.reloadData()
    }
  }

  var selectedBuildTimes: [FunctionBuildTime] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = NSNib(nibNamed: String(describing: HistogramBar.self), bundle: nil)
    collectionView.register(nib, forItemWithIdentifier: String(describing: HistogramBar.self))
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    collectionView.reloadData()
  }

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return buildTimes.count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    guard let histogramBar = collectionView.makeItem(withIdentifier: String(describing: HistogramBar.self), for: indexPath) as? HistogramBar else {
      fatalError()
    }
    histogramBar.view.layer?.backgroundColor = .random
    return histogramBar
  }
}
