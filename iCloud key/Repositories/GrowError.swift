//
//  GrowError.swift
//

import Foundation

struct GrowError {
    enum Location: Error {
        case empty
    }
    
    enum CloudKit: Error {
        case generic
        case notAuthenticated
    }
}
