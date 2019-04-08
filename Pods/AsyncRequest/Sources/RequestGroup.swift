import Foundation

public class RequestGroup: Cancellable {
    
    private let handlers = GroupRequestHandlers()
    private var acceptingRequests = true
    
    private var requests: [Cancellable] = []
    private var requestCount = 0
    private var errors: [Error] = []
    
    public var completed: Bool {
        if acceptingRequests { return false }
        return requests.isEmpty
    }
    public var successful: Bool? {
        if !completed { return nil }
        return errors.isEmpty
    }
    
    public init(success: (() -> Void)? = nil) {
        if let handler = success {
            handlers.add(successHandler: handler)
        }
    }
    
    // MARK: -
    
    @discardableResult
    public func success(handler: @escaping () -> Void) -> Self {
        guard let success = successful else {
            handlers.add(successHandler: handler)
            return self
        }
        if success { handler() }
        return self
    }
    
    @discardableResult
    public func fail(handler: @escaping ([Error]) -> Void) -> Self {
        guard let _ = successful else {
            handlers.add(errorsHandler: handler)
            return self
        }
        if !errors.isEmpty { handler(errors) }
        return self
    }
    
    @discardableResult
    public func everyFail(handler: @escaping (Error) -> Void) -> Self {
        if completed { return self }
        handlers.add(everyErrorHandler: handler)
        return self
    }
    
    @discardableResult
    public func finished(handler: @escaping () -> Void) -> Self {
        if completed {
            handler()
        } else {
            handlers.add(finishHandler: handler)
        }
        return self
    }
    
    // MARK: -
    
    public func add<T>(request: Request<T>) {
        if !acceptingRequests { return }
        requests.append(request)
        request.finished {
            self.requestCount -= 1
            self.update()
        }
        request.fail { error in
            self.handlers.sendError(error)
            self.errors.append(error)
        }
        requestCount += 1
    }
    
    public func startObserving() {
        acceptingRequests = false
        update()
    }
    
    public func cancel() {
        requests.forEach({ $0.cancel() })
    }
    
    private func update() {
        if acceptingRequests || requestCount > 0 { return }
        requests = []
        if !errors.isEmpty {
            handlers.complete(with: errors)
        } else {
            handlers.completeSuccessfully()
        }
    }
}
