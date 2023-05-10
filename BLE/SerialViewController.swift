//
//  SerialViewController.swift
//  BLE
//
//  Created by SEOJIN HONG on 2023/05/10.
//

import UIKit

class SerialViewController: UIViewController, BluetoothSerialDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serial = BluetoothSerial.init()
    }
    
    @IBAction func scanButton(_ sender: Any) {
        performSegue(withIdentifier: "ScanViewController", sender: nil)
    }
}
