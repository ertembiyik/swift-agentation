//
//  HitTestable.swift
//  Agentation
//
//  Created by Ertem Biyik on 2025.
//

import UIKit

protocol HitTestable {
    func contains(_ point: CGPoint) -> Bool
}
