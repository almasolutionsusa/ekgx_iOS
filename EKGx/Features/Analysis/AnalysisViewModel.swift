//
//  AnalysisViewModel.swift
//  EKGx
//

import Foundation
import SwiftUI

private extension Patient {
    var genderSDK: vhECGPatientGender {
        switch gender.lowercased() {
        case "f", "female": return .female
        default:            return .male
        }
    }
}

// MARK: - Visualization Mode

enum VisualizationMode {
    case standard       // normal 3×4 grid
    case table          // lead params table overlay
    case layers         // merged/overlay waveform
}

// MARK: - AnalysisViewModel

@Observable
@MainActor
final class AnalysisViewModel {

    // MARK: - Analysis state

    enum AnalysisState { case analyzing, success, failed }
    private(set) var state: AnalysisState = .analyzing

    // MARK: - UI state

    var showControlsMenu: Bool = false
    var showDiagnosisPanel: Bool = false
    var showVisualizationMenu: Bool = false
    var showRejectConfirm: Bool = false
    var visualizationMode: VisualizationMode = .standard

    // Editable diagnosis — user can add/remove items
    var diagnosisLines: [String] = []

    // MARK: - Data

    let patient: Patient
    let ecgData: ECGLeads
    let sampleRate: Int

    private(set) var analysis: vhECGAnalysisObject?
    private(set) var measurements: vhMeasurements?
    private(set) var leadParameters: vhParameters?
    private(set) var templateData: ECGLeads = []
    // Plain Swift strings — @Observable tracks these natively, updated after every re-analysis.
    // vhMeasurements is an ObjC object mutated in-place, so SwiftUI can't observe it directly.
    var mergeHR:     String = "—"
    var mergePR:     String = "—"
    var mergeQRS:    String = "—"
    var mergeQT:     String = "—"
    var mergeQTc:    String = "—"
    var mergePaxis:  String = "—"
    var mergeQRSaxis:String = "—"
    var mergeTaxis:  String = "—"

    private let router: AppRouter

    // MARK: - Init

    init(patient: Patient, ecgData: ECGLeads, sampleRate: Int = 660, router: AppRouter) {
        self.patient    = patient
        self.ecgData    = ecgData
        self.sampleRate = sampleRate
        self.router     = router
    }

    // MARK: - Analysis

    func runAnalysis() {
        guard state == .analyzing else { return }

        let data   = ecgData
        let rate   = sampleRate
        let age    = patient.ageYears
        let gender = patient.genderSDK

        Task.detached(priority: .userInitiated) { [weak self] in
            let obj     = vhECGAnalysisObject()
            let success = obj.analysisECG(data, withRate: rate, withPatientAge: age, with: gender)

            await MainActor.run { [weak self] in
                guard let self else { return }
                let template: ECGLeads = obj.templateAnalysisResult.templateData() as? [[NSNumber]] ?? []
                if success, !template.isEmpty {
                    self.analysis        = obj
                    self.diagnosisLines  = obj.interpretation as? [String] ?? []
                    self.measurements    = obj.measurementsResult
                    self.leadParameters  = obj.parametersResult
                    self.templateData    = template
                    self.copyMergeStrings(from: obj.measurementsResult)
                    self.state             = .success
                } else {
                    self.state = .failed
                }
            }
        }
    }

    // MARK: - Navigation

    func goBack() {
        router.navigate(to: .dashboard)
    }

    func confirmReject() {
        router.navigate(to: .dashboard)
    }

    // MARK: - Helpers

    var leadNames: [String] {
        ["I","II","III","aVR","aVL","aVF","V1","V2","V3","V4","V5","V6"]
    }

    var orderedLeadParams: [vhLeadParameter] {
        guard let p = leadParameters else { return [] }
        return p.leadsParameterArray() as [vhLeadParameter]
    }

    // MARK: - Manual re-analysis (called after dragging beat markers)

    func reanalyseLead(_ lead: vhLeadTemplate) {
        guard let obj = analysis else { return }
        if obj.manualAnalisysLead(lead) {
            measurements   = obj.measurementsResult
            leadParameters = obj.parametersResult
            copyMergeStrings(from: obj.measurementsResult)
        }
    }

    func reanalyseAllLeads() {
        guard let obj = analysis else { return }
        if obj.manualAnalysisAllLead() {
            measurements   = obj.measurementsResult
            leadParameters = obj.parametersResult
            copyMergeStrings(from: obj.measurementsResult)
        }
    }

    private func copyMergeStrings(from m: vhMeasurements) {
        let c = m.merge
        mergeHR      = c.hr.isEmpty      ? "—" : c.hr
        mergePR      = c.pr.isEmpty      ? "—" : c.pr
        mergeQRS     = c.qrs.isEmpty     ? "—" : c.qrs
        mergeQT      = c.qt.isEmpty      ? "—" : c.qt
        mergeQTc     = c.qTc.isEmpty     ? "—" : c.qTc
        mergePaxis   = c.paxis.isEmpty   ? "—" : c.paxis
        mergeQRSaxis = c.qrSaxis.isEmpty ? "—" : c.qrSaxis
        mergeTaxis   = c.taxis.isEmpty   ? "—" : c.taxis
    }
}
