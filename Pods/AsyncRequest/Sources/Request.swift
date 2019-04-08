import Foundation

open class Request<T>: Cancellable {
    
    private var handlers: RequestHandlers<T>? = RequestHandlers<T>()
    
    private var object: T?
    private var error: Error?
    
    open var subrequest: Cancellable? {
        didSet {
            if let _ = error {
                subrequest?.cancel()
            }
        }
    }
    
    open var completed: Bool {
        return object != nil || error != nil
    }
    
    /// Creates an already falied request, use only on serial queues
    public static func completed(with error: Error, in queue: DispatchQueue) -> Request<T> {
        let request = Request<T>()
        queue.async {
            request.complete(with: error)
        }
        return request
    }
    
    /// Creates an already successful request, use only on serial queues
    public static func completed(with object: T, in queue: DispatchQueue) -> Request<T> {
        let request = Request<T>()
        queue.async {
            request.complete(with: object)
        }
        return request
    }
    
    public init(successHandler: ((T) -> Void)? = nil) {
        if let handler = successHandler {
            handlers?.add(successHandler: handler)
        }
    }
    
    /// Cancels the request and subrequest and call the handlers, subsequent calls are ignored
    open func cancel() {
        subrequest?.cancel()
        complete(with: RequestError.canceled)
    }
    
    open func complete(with object: T, in queue: DispatchQueue) {
        queue.async { self.complete(with: object) }
    }
    
    open func complete(with object: T) {
        if !completed {
            self.object = object
            handlers?.complete(with: object)
            handlers = nil
        }
    }
    
    open func complete(with error: Error, in queue: DispatchQueue) {
        queue.async { self.complete(with: error) }
    }
    
    open func complete(with error: Error) {
        if !completed {
            self.error = error
            handlers?.complete(with: error)
            handlers = nil
        }
    }
    
    @discardableResult
    public func success(handler: @escaping (T) -> Void) -> Self {
        if let object = object {
            handler(object)
        } else {
            handlers?.add(successHandler: handler)
        }
        return self
    }
    
    @discardableResult
    public func fail(handler: @escaping (Error) -> Void) -> Self {
        if let error = error {
            handler(error)
        } else {
            handlers?.add(errorHandler: handler)
        }
        return self
    }
    
    @discardableResult
    public func finished(handler: @escaping () -> Void) -> Self {
        if completed {
            handler()
        } else {
            handlers?.add(finishHandler: handler)
        }
        return self
    }
    
    /// Returs a Request object that is a Proxy of this Request,
    /// when the proxy is canceled the parent Request is not canceled
    
    public func proxy(success: @escaping (T) -> Void) -> Request<T> {
        let request = Request<T>(successHandler: success)
        if let object = object {
            request.complete(with: object)
        } else if let error = error {
            request.complete(with: error)
        } else {
            handlers?.add(proxy: request)
        }
        
        return request
    }
}
