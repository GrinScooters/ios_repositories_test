//
//  TimeoutRequest.swift
//  AsyncRequest
//
//  Created by Juan Jose Arreola Simon on 9/27/18.
//

import Foundation

@available(OSX 10.12, watchOS 3.0, tvOS 10.0, iOS 10.0, *)
open class TimeoutRequest<T>: Request<T> {
    
    private var timer: Timer?
    
    public init(timeout: TimeInterval, successHandler: ((T) -> Void)? = nil) {
        super.init(successHandler: successHandler)
        setupTimer(withTimeInterval: timeout)
    }
    
    func setupTimer(withTimeInterval interval: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { [weak self] _ in
            guard let completed = self?.completed, !completed else { return }
            self?.complete(with: RequestError.timeout)
        })
    }
}
