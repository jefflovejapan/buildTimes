//
//  Sorting.swift
//  FileViewer
//
//  Created by Jeffrey Blagdon on 1/27/17.
//  Copyright © 2017 razeware. All rights reserved.
//

import Foundation

typealias SortDescriptor<Value> = (Value, Value) -> Bool

func sortDescriptor<Value, Key>(
  key: @escaping (Value) -> Key,
  ascending: Bool = true,
  _ comparator: @escaping (Key) -> (Key) -> ComparisonResult
  ) -> SortDescriptor<Value> {
  return { lhs, rhs in
    let order: ComparisonResult = ascending ? .orderedAscending : .orderedDescending
    return comparator(key(lhs))(key(rhs)) == order
  }
}

func combine<Value>(sortDescriptors: [SortDescriptor<Value>]) -> SortDescriptor<Value> {
  return { lhs, rhs in
    for isOrderedBefore in sortDescriptors {
      if isOrderedBefore(lhs, rhs) { return true }
      if isOrderedBefore(rhs, lhs) { return false }
    }

    return false
  }
}
