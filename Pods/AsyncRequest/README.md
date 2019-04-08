# AsyncRequest

![Cocoapods](https://img.shields.io/cocoapods/v/AsyncRequest.svg)
![Platform](https://img.shields.io/cocoapods/p/AsyncRequest.svg)
![License](https://img.shields.io/cocoapods/l/AsyncRequest.svg)
[![codebeat badge](https://codebeat.co/badges/8dad2ec2-3e10-413f-b60e-ec20503ba669)](https://codebeat.co/projects/github-com-juanjoarreola-asyncrequest-master)

## Useful classes to handle asynchronous code


A `Request` is an object containing closures that can be called asynchronously at some point in the future:

```swift
let request = Request<String>(successHandler: { string in
    print(string)
})
```

Depending on the result of some computation the request can be successful:

```swift
request.complete(with: "Success!")
```

Or not:

```swift
request.complete(with: TestError.error)
```

In any case the request finishes:

```swift
request.finished {
    print("did finish")
}
```

Requests can be canceled:

```swift
request.cancel()
```

Closures can be added:

```swift
request.success(handler: { string in
    print("Result: \(string)")
})

request.fail { error in
    print("Error: \(error)")
}

request.finished {
    print("request did complete")
})
```
