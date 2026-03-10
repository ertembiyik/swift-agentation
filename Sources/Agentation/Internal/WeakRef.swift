//
//  WeakRef.swift
//  Agentation
//
//  Created by Ertem Biyik on 2025.
//

import Foundation

struct WeakRef<T: AnyObject> {
    weak var value: T?
}
