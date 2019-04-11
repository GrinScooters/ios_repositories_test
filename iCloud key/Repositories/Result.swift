//
//  Result.swift
//

import Foundation

enum Result<V> {
    case success(V)
    case failure(Error)
}
