//
//  Interactors.swift
//  iCloud key
//
//  Created by Victor Soto on 4/9/19.
//  Copyright © 2019 Grin Scooters. All rights reserved.
//

import Foundation
import AsyncRequest
import CoreLocation

class SessionInteractor {
    
    private let locationRepository = LocationRepository(configuration: .default)    
    private var locationRequest: Request<CLLocation>?
    
    deinit {
        cancelGetLocation()
    }
    
    func getLocation() {
        if LocationRepository.locationServicesEnabled {
            locationRequest = locationRepository.getLocation(timeout: 2, closure: { location in
                print(location)
            }).fail(handler: { error in
                print(error)
            }).finished {
                print("'getLocation' finished")
            }
        } else {
            locationRepository.requestAuthorization { [weak self] status in
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    self?.getLocation()
                default:
                    return
                }
            }
        }
    }
    
    func cancelGetLocation() {
        locationRequest?.cancel()
        locationRequest = nil
    }
}
