//
//  GroupRequestHandlers.swift
//  AsyncRequest
//
//  Created by Juan Jose Arreola on 11/11/17.
//

import Foundation

class GroupRequestHandlers {
    
    private var successHandlers: [() -> Void] = []
    private var everyErrorHandlers: [(Error) -> Void] = []
    private var errorsHandlers: [([Error]) -> Void] = []
    private var finishHandlers: [() -> Void] = []
    
    func add(successHandler: @escaping () -> Void) {
        successHandlers.append(successHandler)
    }
    
    func add(everyErrorHandler: @escaping (Error) -> Void) {
        everyErrorHandlers.append(everyErrorHandler)
    }
    
    func add(errorsHandler: @escaping ([Error]) -> Void) {
        errorsHandlers.append(errorsHandler)
    }
    
    func add(finishHandler: @escaping () -> Void) {
        finishHandlers.append(finishHandler)
    }
    
    // MARK: -
    
    func completeSuccessfully() {
        successHandlers.forEach({ $0() })
        finishHandlers.forEach({ $0() })
        clear()
    }
    
    func sendError(_ error: Error) {
        everyErrorHandlers.forEach({ $0(error) })
    }
    
    func complete(with errors: [Error]) {
        errorsHandlers.forEach({ $0(errors) })
        finishHandlers.forEach({ $0() })
        clear()
    }
    
    func clear() {
        successHandlers = []
        everyErrorHandlers = []
        errorsHandlers = []
        finishHandlers = []
    }
}
