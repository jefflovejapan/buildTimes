//
//  FreeFunctions.swift
//  FileViewer
//
//  Created by Jeffrey Blagdon on 1/28/17.
//  Copyright © 2017 razeware. All rights reserved.
//

import Foundation


/// Tries to execute a throwing function, print an error and returning nil on failure
///
/// - Parameter f: A throwing function
/// - Returns: An optional value: .some on success, .none on error.
func tryAndPrintError<T>(_ f: () throws -> T) -> T? {
  do {
    return try f()
  } catch {
    print(error)
    return nil
  }
}
