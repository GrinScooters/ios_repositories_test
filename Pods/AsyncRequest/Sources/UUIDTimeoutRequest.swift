//
//  UUIDTimeoutRequest.swift
//  AsyncRequest
//
//  Created by Juan Jose Arreola on 10/2/18.
//

import Foundation

@available(OSX 10.12, watchOS 3.0, tvOS 10.0, iOS 10.0, *)
public class UUIDTimeoutRequest<T>: TimeoutRequest<T>, Hashable, Equatable {
    
    public let uuid: UUID
    
    override public init(timeout: TimeInterval, successHandler: ((T) -> Void)? = nil) {
        uuid = UUID()
        super.init(timeout: timeout, successHandler: successHandler)
    }
    
    public static func == (lhs: UUIDTimeoutRequest<T>, rhs: UUIDTimeoutRequest<T>) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public var hashValue: Int {
        return uuid.hashValue
    }
}
