//
//  ViewController.swift
//  iCloud key
//
//  Created by Guillermo Haro on 4/3/19.
//  Copyright © 2019 DevilWearsCalvin. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tokenLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iCloudToken()
    }
    
    func iCloudToken() {
        iCloudUserID(onSuccess: { token in
            self.updateTokenLabel(token)
            }, onError: { error in
            self.updateTokenLabel("Error...")
        })
    }
    
    func updateTokenLabel(_ token: String) {
        DispatchQueue.main.async {
            print("Token: \(token)")
            self.tokenLabel.text = token
        }
    }
    
    enum iCloudError: Error {
        case genericError
    }
    
    func iCloudUserID(onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        let container = CKContainer.default()
        container.fetchUserRecordID() { (recordID, error) in
            if let recordID = recordID {
                onSuccess(recordID.recordName)
            } else {
                if let error = error {
                    onError(error)
                } else {
                    // Shouldn't happen
                    onError(iCloudError.genericError)
                }
            }
        }
    }

}

