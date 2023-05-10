//
//  ScanViewController.swift
//  BLE
//
//  Created by SEOJIN HONG on 2023/05/10.
//

import UIKit
import CoreBluetooth

class ScanViewController: UIViewController {
    
    // 검색된 기기들을 나타내는 TableView 입니다.
    @IBOutlet weak var tableView: UITableView!
    
    // 현재 검색된 페리퍼럴입니다.
    var peripheralList: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // scan 버튼을 눌러 기기 검색을 시작할 때마다 list를 초기화합니다.
        peripheralList = []
        
        // serial의 delegate를 ScanViewController로 설정합니다. serial에서 delegate의 메서드를 호출하면 이 클래스에서 정의된 메서드가 호출됩니다.
        serial.delegate = self
        
        // 뷰가 로드된 후 검색을 시작합니다.
        serial.startScan()
    }
}

extension ScanViewController: BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        // serial의 delegate에서 호출됩니다.
        // 이미 저장되어 있는 기기라면 return 합니다.
        for existing in peripheralList {
            if existing.peripheral.identifier == peripheral.identifier { return }
        }
        
        // 신호의 세기에 따라 정렬하도록 합니다.
        let fRSSI = RSSI?.floatValue ?? 0.0
        peripheralList.append((peripheral: peripheral, RSSI: fRSSI))
        peripheralList.sort { $0.RSSI < $1.RSSI }
        
        tableView.reloadData()
    }
    
    func serialDidConnectPeripheral(peripheral: CBPeripheral) {
        // serial의 delegate에서 호출됩니다.
        // 연결 성공 시 alert를 띄우고, alert 확인 시 View를 dismiss합니다.
        let connectSuccessAlert = UIAlertController(title: "블루투스 연결 성공", message: "\(peripheral.name ?? "알수없는기기")", preferredStyle: .actionSheet)
        let confirm = UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        connectSuccessAlert.addAction(confirm)
        serial.delegate = nil
        present(connectSuccessAlert, animated: true, completion: nil)
    }
}

extension ScanViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let peripheralName = peripheralList[indexPath.row].peripheral.name
        cell.textLabel?.text = peripheralName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 검색을 중단하고 선택된 페리퍼럴을 연결합니다.
        serial.stopScan()
        let selectedPeripheral = peripheralList[indexPath.row].peripheral
        
        // serial의 connectToPeripheral 함수에 선택된 peripheral을 연결하도록 요청합니다.
        serial.connectToPeripheral(selectedPeripheral)
    }
}
