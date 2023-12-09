//
//  ViewController.swift
//  BoardingPassKitDemo
//
//  Created by Justin Ackermann on 12/8/23.
//

import UIKit
import BoardingPassKit
import NomadUtilities

class ViewController: UIViewController {
    
    let testscan: String = "M1AIGOZHINA/ELMIRA EPYP98I NQZALAKC 7773 332Y013K0001 31C>2080 B0E 0"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            let pass = try BoardingPassDecoder().decode(code: testscan)
            print(pass.prettyJSON)
            print()
        } catch {
            error.explain()
            print()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }


}

