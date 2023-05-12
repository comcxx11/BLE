//
//  SerialViewController.swift
//  BLE
//
//  Created by SEOJIN HONG on 2023/05/10.
//

import UIKit

// https://staktree.github.io/ios/iOS-Bluetooth-03-bluetooth-communication/

class SerialViewController: UIViewController, BluetoothSerialDelegate {
    
    @IBOutlet weak var serialMessageLabel: UILabel!
    var msg = "1"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serial = BluetoothSerial.init()
        
        self.title = "페리퍼럴 캐리터리스틱"
    }
    
    @IBAction func scanButton(_ sender: Any) {
        performSegue(withIdentifier: "ScanViewController", sender: nil)
    }
    
    @IBAction func sendMessageButton(_ sender: Any) {
        if !serial.bluetoothIsReady {
            print("시리얼이 준비되지 않음")
            return
        }
        
        // 시리얼의 delegate를 SerialViewController로 설정합니다.
        serial.delegate = self
        
        if msg == "1" {
            msg = "2"
        } else {
            msg = "1"
        }
        
        serial.sendMessageToDevice(msg)
        
        serialMessageLabel.text = "Waiting for Peripherak's message"
    }
    
    /// 데이터가 전송된 후 Peripheral로 부터 응답이 오면 호출되는 메서드입니다.
    func serialDidReceiveMessage(message : String)
    {
        // 응답으로 온 메시지를 라벨에 표시합니다.
        serialMessageLabel.text = message
    }
}
