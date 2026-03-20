//
//  DeviceServiceProtocol.swift
//  EKGx
//

import Foundation

// Raw 12-lead ECG data batch: [[I], [II], ... [V6]]
typealias ECGLeads = [[NSNumber]]

protocol DeviceServiceProtocol: AnyObject {
    var onConnectionStateChanged: ((DeviceConnectionState) -> Void)? { get set }
    var onECGData: ((ECGLeads) -> Void)? { get set }
    var currentState: DeviceConnectionState { get }

    func connect()
    func disconnect()
}
