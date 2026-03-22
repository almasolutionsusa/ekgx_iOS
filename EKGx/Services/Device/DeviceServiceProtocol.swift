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
    var onLeadStatus: (([Bool]) -> Void)? { get set }
    /// Battery level 0–100. Nil if device doesn't report it.
    var onBattery: ((Int) -> Void)? { get set }
    var currentState: DeviceConnectionState { get }
    var sampleRate: Int { get }

    func connect()
    func disconnect()
}
