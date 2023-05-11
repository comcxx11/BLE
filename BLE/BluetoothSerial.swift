//
//  BluetoothSerial.swift
//  BLE
//
//  Created by SEOJIN HONG on 2023/05/10.
//

import Foundation
import CoreBluetooth

// pərífərəl 페리퍼럴
// kæ̀riktərístik 캐리터리스틱

// 블루투스를 연결하는 과정에서의 시리얼과 뷰의 소통을 위해 필요한 프로토콜입니다.
protocol BluetoothSerialDelegate : AnyObject {
    
    /// 검색된 기기 리스트와 테이블 뷰를 업데이트하는 메서드
    /// - Parameters:
    ///   - peripheral: 페리퍼럴
    ///   - RSSI: 감도
    func serialDidDiscoverPeripheral(peripheral : CBPeripheral, RSSI : NSNumber?)
    
    /// 연결되었을 때 호출되는 메서드
    /// - Parameter peripheral: 연결된 페리퍼럴
    func serialDidConnectPeripheral(peripheral : CBPeripheral)
}

// 프로토콜에 포함되어 있는 일부 함수를 옵셔널로 설정합니다.
extension BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral : CBPeripheral, RSSI : NSNumber?) {}
    func serialDidConnectPeripheral(peripheral : CBPeripheral) {}
}

var serial: BluetoothSerial!

class BluetoothSerial: NSObject {
    
    enum SearchType {
        case all
        case HM10
    }
    
    /// centralManager은 블루투스 주변기기를 검색하고 연결하는 역할을 수행합니다.
    var centralManager : CBCentralManager!
    
    /// pendingPeripheral은 현재 연결을 시도하고 있는 블루투스 주변기기를 의미합니다.
    var pendingPeripheral : CBPeripheral?
    
    /// connectedPeripheral은 연결에 성공된 기기를 의미합니다. 기기와 통신을 시작하게되면 이 객체를 이용하게됩니다.
    var connectedPeripheral : CBPeripheral?
    
    /// 데이터를 주변기기에 보내기 위한 characteristic을 저장하는 변수입니다.
    weak var writeCharacteristic: CBCharacteristic?
    
    /// 데이터를 주변기기에 보내는 type을 설정합니다. withResponse는 데이터를 보내면 이에 대한 답장이 오는 경우입니다. withoutResponse는 반대로 데이터를 보내도 답장이 오지 않는 경우입니다.
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻합니다. 거의 모든 HM-10모듈이 기본적으로 갖고있는 FFE0으로 설정하였습니다. 하나의 기기는 여러개의 serviceUUID를 가질 수도 있습니다.
    var serviceUUID = CBUUID(string: "FFE0")
    
    /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
    var characteristicUUID = CBUUID(string : "FFE1")
    
    var searchType = SearchType.HM10
    
    /// BluetoothSerialDelegate 프로토콜에 등록된 메서드를 수행하는 delegate입니다.
    var delegate: BluetoothSerialDelegate?
    
    /// seriald을 초기화할 때 호출하여야합니다. 시리얼은 nil이여서는 안되기 때문에 항상 초기화후 사용해야 합니다.
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BluetoothSerial {
    
    /// 기기 검색을 시작합니다. 연결이 가능한 모든 주변기기를 serviceUUID를 통해 찾아냅니다.
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        // CBCentralManager의 메서드인 scanForPeripherals를 호출하여 연결가능한 기기들을 검색합니다.
        // 이 때 withService 파라미터에 nil을 입력하면 모든 종류의 기기가 검색되고,
        // 지금과 같이 serviceUUID를 입력하면 특정 serviceUUID를 가진 기기만을 검색합니다.
        switch searchType {
        case .all:
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        case .HM10:
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
        
        
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        
        for peripheral in peripherals {
            // TODO: 검색된 기기들에 대한 처리를 여기에 작성합니다.
            print(peripheral)
            delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: nil)
        }
    }
    
    /// 기기 검색을 중단합니다.
    func stopScan() {
        centralManager.stopScan()
    }
    
    
    /// 파라미터로 넘어온 주변기기를 CentralManager에 연결하도록 시도합니다.
    /// - Parameter peripheral: 연결 대상
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        // 연결 실패를 대비하여 현재 연결중인 주변기기를 저장합니다.
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    
}

extension BluetoothSerial: CBCentralManagerDelegate {
    /// CBCentralManagerDelegate에 포함되어 있는 메서드입니다. central 기기의 블루투스가 켜져있는지, 꺼져있는지 등에 대한 상태가 변화할 때 마다 호출됩니다. 이 상태는 블루투스가 켜져있을 때는 .poweredOn, 꺼져있을 때는 .poweredOff로 관리됩니다.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        pendingPeripheral = nil
        connectedPeripheral = nil
    }
    
    
    /// 기기가 검색될 때마다 호출되는 메서드입니다.
    /// - Parameters:
    ///   - central: central
    ///   - peripheral: peripheral
    ///   - advertisementData: 광고 데이터
    ///   - RSSI: 기기의 신호강도
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // TODO: 기기가 검색될 때마다 필요한 코드를 여기에 작성합니다.
        delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: RSSI)
    }
    
    
    /// 기기가 연결되면 호출되는 메서드입니다.
    /// - Parameters:
    ///   - central: central
    ///   - peripheral: 연결된 peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // 델리게이트 연결
        peripheral.delegate = self
        
        // pendingPeripheral 초기화
        pendingPeripheral = nil
        
        // 연결된 페리퍼럴
        connectedPeripheral = peripheral
        
        // peripheral의 Service들을 검색합니다. 파라미터를 nil로 설정하면 peripheral의 모든 service를 검색합니다.
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error ?? "")
    }
    
}

/// 1. peripheral.discoverServices([serviceUUID])
/// 2. peripheral.discoverCharacteristics([characteristicUUID], for: service)
extension BluetoothSerial: CBPeripheralDelegate {
    
    
    /// service 검색에 성공 시 호출되는 메서드입니다.
    /// - Parameters:
    ///   - peripheral: 페리퍼럴
    ///   - error: 에러
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // 검색된 모든 service에 대해서 characteristic을 검색합니다. 파라미터를 nil로 설정하면 해당 service의 모든 charateristic을 검색합니다.
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    
    /// characteristics 검색에 성공 시 호출되는 메서드입니다.
    /// - Parameters:
    ///   - peripheral: 페리퍼럴
    ///   - service: 서비스
    ///   - error: 에러
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            // 검색된 모든 characteristic에 대해 characteristicUUID를 한번 더 체크하고, 일치한다면 peripheral을 구독하고 통신을 위한 설정을 완료합니다.
            if characteristic.uuid == characteristicUUID {
                // 해당 기기의 데이터를 구독합니다.
                peripheral.setNotifyValue(true, for: characteristic)
                // 데이터를 보내기 위한 characteristic을 저장합니다.
                writeCharacteristic = characteristic
                // 데이터를 보내는 타입을 설정합니다. 이는 주변기기가 어떤 type으로 설정되어 있는지에 따라 변경됩니다.
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                // TODO: 주변 기기와 연결 완료 시 동작하는 코드를 여기에 작성합니다.
                delegate?.serialDidConnectPeripheral(peripheral: peripheral)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // writeType이 .withResponse일 때, 블루투스 기기로부터의 응답이 왔을 때 호출되는 함수입니다.
        // 제가 테스트한 주변 기기는 .withoutResponse이기 때문에 호출되지 않습니다.
        // writeType이 .withResponse인 블루투스 기기로부터 응답이 왔을 때 필요한 코드를 작성합니다.
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // 블루투스 기기의 신호 강도를 요청하는 peripheral.readRSSI()가 호출하는 함수입니다.
        // 신호 강도와 관련된 코드를 작성합니다. (필요하다면 작성해주세요.)
    }
}
