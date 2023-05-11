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
        
        self.title = "페리퍼럴 캐리터리스틱"
    }
    
    @IBAction func scanButton(_ sender: Any) {
        performSegue(withIdentifier: "ScanViewController", sender: nil)
    }
}
