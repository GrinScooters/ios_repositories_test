//
//  ViewController.swift
//  iCloud key
//
//  Created by Guillermo Haro on 4/3/19.
//  Copyright © 2019 DevilWearsCalvin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tokenLabel: UILabel!
    
    let sessionViewModel = SessionViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionViewModel.getSession()        
    }
}

