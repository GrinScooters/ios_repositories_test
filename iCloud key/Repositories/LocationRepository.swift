//
//  LocationRepository.swift
//

import Foundation
import AsyncRequest
import CoreLocation

class LocationRequest<T>: Request<T> {
    weak var manager: CLLocationManager?
    
    override open func cancel() {
        manager?.delegate = nil
        manager?.stopUpdatingLocation()
        super.cancel()
    }
}

class LocationTimeoutRequest<T>: TimeoutRequest<T> {
    weak var manager: CLLocationManager?
    
    override open func cancel() {
        manager?.delegate = nil
        manager?.stopUpdatingLocation()
        super.cancel()
    }
}

extension CLLocationManager {
    func apply(configuration: LocationRepository.Configuration) {
        desiredAccuracy = configuration.desiredAccuracy
        allowsBackgroundLocationUpdates = configuration.allowsBackgroundLocationUpdates
        pausesLocationUpdatesAutomatically = configuration.pausesLocationUpdatesAutomatically
    }
}

typealias LocationResult = Result<CLLocation>
typealias LocationAuthorizationStatus = (CLAuthorizationStatus) -> Void

class LocationRepository: NSObject, CLLocationManagerDelegate {
    
    struct Configuration {
        let allowsBackgroundLocationUpdates: Bool
        let pausesLocationUpdatesAutomatically: Bool
        let desiredAccuracy: CLLocationAccuracy
        
        static let `default`: Configuration = Configuration(allowsBackgroundLocationUpdates: false,
                                                            pausesLocationUpdatesAutomatically: true,
                                                            desiredAccuracy: kCLLocationAccuracyBestForNavigation)
        
        
        static let background: Configuration = Configuration(allowsBackgroundLocationUpdates: true,
                                                             pausesLocationUpdatesAutomatically: false,
                                                             desiredAccuracy: kCLLocationAccuracyBestForNavigation)
    }
    
    let locationManager = CLLocationManager()
    
    private(set) var value: LocationResult = .failure(GrowError.Location.empty) {
        didSet {
            switch value {
            case .success(let location):
                request?.complete(with: location)
            case .failure(let error):
                request?.complete(with: error)
            }
        }
    }
    
    weak private var request: Request<CLLocation>? {
        didSet {
            locationManager.startUpdatingLocation()
        }
    }
    
    // MARK: - Lifecycle
    
    required convenience init(configuration: LocationRepository.Configuration) {
        self.init()
        locationManager.apply(configuration: configuration)
        locationManager.delegate = self
    }
    
    deinit {
        locationManager.delegate = nil
        request?.cancel()
        request = nil
        authClosure = nil
    }
    
    // MARK: - Auth
    
    var authClosure: LocationAuthorizationStatus?
    
    static var locationServicesEnabled: Bool {
        guard CLLocationManager.locationServicesEnabled() else {
            return false
        }
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        }
    }
    
    func requestAuthorization(closure: LocationAuthorizationStatus? = nil) {
        self.authClosure = closure
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Functions
    
    func getLocation(timeout: TimeInterval? = nil, closure: @escaping (CLLocation) -> Void) -> Request<CLLocation> {
        let request: Request<CLLocation>
        if let timeout = timeout {
            let req = LocationTimeoutRequest<CLLocation>(timeout:timeout, successHandler: closure)
            req.manager = locationManager
            request = req
        } else {
            let req = LocationRequest<CLLocation>(successHandler: closure)
            req.manager = locationManager
            request = req
        }
        self.request = request
        return request
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        value = .success(location)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        value = .failure(error)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authClosure?(status)
    }
}



