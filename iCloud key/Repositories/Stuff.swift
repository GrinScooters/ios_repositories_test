//
//  Stuff.swift
//  iCloud key
//
//  Created by Victor Soto on 4/9/19.
//  Copyright © 2019 Grin Scooters. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class ObserverToken {
    private let cancellationClosure: () -> Void
    
    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }
    
    func cancel() {
        cancellationClosure()
    }
}

typealias ObserverValueResponse = (Any?) -> Void

protocol StateObserver: class {
    associatedtype State: Hashable
    
    var observers: [State: [ObjectIdentifier: ObserverValueResponse]] { get set }
    
    func addObserver(_ observer: AnyObject, state: State, closure: @escaping ObserverValueResponse) -> ObserverToken
    func removeObserverFor(state: State, id: ObjectIdentifier)
    func startObserving(state: State)
    func stopObserving(state: State)
    func verifyObserversFor(state: State)
}

extension StateObserver {
    func addObserver(_ observer: AnyObject, state: State, closure: @escaping ObserverValueResponse) -> ObserverToken {
        let id = ObjectIdentifier(observer)
        if observers[state] == nil {
            observers[state] = [ObjectIdentifier: ObserverValueResponse]()
        }
        observers[state]?[id] = { [weak self, weak observer] result in
            guard let _ = observer else {
                self?.removeObserverFor(state: state, id: id)
                return
            }
            closure(result)
        }
        verifyObserversFor(state: state)
        return ObserverToken(cancellationClosure: { [weak self] in
            self?.removeObserverFor(state: state, id: id)
        })
    }
    
    func removeObserverFor(state: State, id: ObjectIdentifier) {
        observers[state]?.removeValue(forKey: id)
        verifyObserversFor(state: state)
    }
    
    func startObserving(state: State) { fatalError("Every observer needs to implement its own 'startObserving' function") }
    
    func stopObserving(state: State) { fatalError("Every observer needs to implement its own 'stopObserving' function") }
    
    func verifyObserversFor(state: State) {
        guard let observers = observers[state] else { return }
        let numberOfObservers = observers.count
        if numberOfObservers <= 0 {
            stopObserving(state: state)
        } else if numberOfObservers == 1 {
            startObserving(state: state)
        }
    }
}

protocol ValueObserver: class {
    associatedtype Value
    
    var observers: [ObjectIdentifier: (Value) -> Void] { get set }
    var numberOfObservers: Int { get }
    var existsObservers: Bool { get }
    
    func addObserver(_ observer: AnyObject, closure: @escaping (Value)-> Void) -> ObserverToken
    func removeObserverFor(id: ObjectIdentifier)
    func validateObservers()
}

extension ValueObserver {
    var numberOfObservers: Int {
        return observers.count
    }
    
    var existsObservers: Bool {
        return numberOfObservers > 0
    }
    
    func addObserver(_ observer: AnyObject, closure: @escaping (Value)-> Void) -> ObserverToken {
        let id = ObjectIdentifier(observer)
        observers[id] = { [weak self, weak observer] value in
            guard let _ = observer else {
                self?.removeObserverFor(id: id)
                return
            }
            closure(value)
        }
        validateObservers()
        return ObserverToken(cancellationClosure: { [weak self] in
            self?.removeObserverFor(id: id)
        })
    }
    
    func removeObserverFor(id: ObjectIdentifier) {
        observers.removeValue(forKey: id)
        validateObservers()
    }
}

class LocationSharedRepository: NSObject, ValueObserver, CLLocationManagerDelegate {
    
    // MARK: - Singleton
    
    static let shared = LocationSharedRepository()
    
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
    
    // MARK: - ValueObserver
    
    typealias Value = Result<CLLocation>
    
    var observers = [ObjectIdentifier : (Result<CLLocation>) -> Void]()
    
    func validateObservers() {
        if !existsObservers {
            invalidateTimer()
        }
    }
    
    // MARK: - Lifecycle
    
    private var updateInterval: TimeInterval
    
    let locationManager = CLLocationManager()
    
    private var timer: Timer?
    
    private var canStartUpdates: Bool {
        return existsObservers && !isUpdating
    }
    
    private var isUpdating: Bool {
        return timer?.isValid ?? false
    }
    
    private var backgroundHandle: NSObjectProtocol?
    private var foregroundHandle: NSObjectProtocol?
    
    private(set) var locationUpdated: Bool = false
    private(set) var location: CLLocation = CLLocation(latitude: 0, longitude: 0) {
        didSet {
            locationUpdated = true
            value = .success(location)
        }
    }
    
    private(set) var value: Result<CLLocation>! {
        didSet {
            observers.values.forEach { closure in
                closure(value)
            }
        }
    }
    
    required init(updateInterval: TimeInterval = 1) {
        self.updateInterval = updateInterval
        super.init()
        value = .failure(GrowError.Location.empty)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    deinit {
        invalidateTimer()
        removeNotificationHandlers()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Notifications
    
    fileprivate func addNotificationHandlers() {
        backgroundHandle = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
                                                                  object: nil,
                                                                  queue: nil) { [weak self] _ in
                                                                    self?.invalidateTimer()
        }
        foregroundHandle = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                  object: nil,
                                                                  queue: nil) { [weak self] _ in
                                                                    self?.setupUpdateTimer()
        }
    }
    
    fileprivate func removeNotificationHandlers() {
        if let backgroundHandle = backgroundHandle {
            NotificationCenter.default.removeObserver(backgroundHandle)
        }
        backgroundHandle = nil
        if let foregroundHandle = foregroundHandle {
            NotificationCenter.default.removeObserver(foregroundHandle)
        }
        foregroundHandle = nil
    }
    
    // MARK: - Update
    
    func setupUpdateTimer() {
        invalidateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true, block: { [weak self] _ in
            self?.startUpdatingLocation()
        })
    }
    
    func invalidateTimer() {
        timer?.invalidate()
    }
    
    func startUpdatingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            if canStartUpdates {
                locationManager.startUpdatingLocation()
            }
        default:
            break
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.location = location
        stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        value = .failure(error)
        stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            setupUpdateTimer()
        default:
            invalidateTimer()
        }
    }
}
