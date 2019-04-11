//
//  ViewModels.swift
//  iCloud key
//
//  Created by Victor Soto on 4/9/19.
//  Copyright © 2019 Grin Scooters. All rights reserved.
//

import Foundation

class SessionViewModel {
    
    let interactor = SessionInteractor()
    
    func getSession() {
        interactor.getLocation()
    }
}
