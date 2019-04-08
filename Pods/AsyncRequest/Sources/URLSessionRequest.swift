import Foundation

open class URLSessionRequest<T>: Request<T> {
    
    open var dataTask: URLSessionTask?
    
    override open func cancel() {
        dataTask?.cancel()
        super.cancel()
    }
}
