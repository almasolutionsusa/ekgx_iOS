//
//  AnalysisViewModel.swift
//  EKGx
//

import Foundation
import SwiftUI
import UIKit

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

    // MARK: - Upload state

    var isUploading: Bool = false
    var uploadSuccess: Bool = false
    var uploadError: String? = nil
    var showUploadResult: Bool = false

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
    private let uploadService: EKGUploadService
    private let checkinService: AppCheckinService

    // MARK: - Init

    init(
        patient: Patient,
        ecgData: ECGLeads,
        sampleRate: Int = 660,
        router: AppRouter,
        uploadService: EKGUploadService,
        checkinService: AppCheckinService
    ) {
        self.patient        = patient
        self.ecgData        = ecgData
        self.sampleRate     = sampleRate
        self.router         = router
        self.uploadService  = uploadService
        self.checkinService = checkinService
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

    // MARK: - Upload

    func uploadEKG() {
        guard !isUploading else { return }
        isUploading = true
        uploadError = nil
        showUploadResult = false

        // Render the ECG image on @MainActor before entering the async Task
        let imageData = renderECGImage()

        Task {
            do {
                let appUuid = checkinService.appUuid
                let fileData = EKGUploadService.serialise(ecgData: ecgData)
                let m = measurements?.merge

                var payload = EKGUploadPayload(
                    patientUuid: patient.patientId ?? patient.uniqueId ?? "",
                    appUuid: appUuid
                )
                payload.heartRate   = nilIfEmpty(m?.hr)
                payload.rrInterval  = nilIfEmpty(m?.rr)
                payload.prInterval  = nilIfEmpty(m?.pr)
                payload.qrsDuration = nilIfEmpty(m?.qrs)
                payload.pDuration   = nilIfEmpty(m?.pd)
                payload.qtInterval  = nilIfEmpty(m?.qt)
                payload.qtCorrected = nilIfEmpty(m?.qTc)
                payload.qtDistance  = nilIfEmpty(m?.qTd)
                payload.qtMax       = nilIfEmpty(measurements?.qTmaxLeadValue)
                payload.qtMin       = nilIfEmpty(measurements?.qTminLeadValue)
                payload.pAxis       = nilIfEmpty(m?.paxis)
                payload.qrsAxis     = nilIfEmpty(m?.qrSaxis)
                payload.rv1         = nilIfEmpty(m?.rv1)
                payload.rv5         = nilIfEmpty(m?.rv5)
                payload.sv1         = nilIfEmpty(m?.sv1)
                payload.sv5         = nilIfEmpty(m?.sv5)
                payload.diagnosis   = diagnosisLines.isEmpty ? nil : diagnosisLines.joined(separator: "; ")
                payload.duration    = String(ecgData.first?.count ?? 0)
                payload.recordedAt  = Date()
                payload.appVersion  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                payload.fileData    = fileData
                payload.imageData   = imageData

                print("── EKG Upload Payload ──────────────────")
                print("  patientUuid : \(payload.patientUuid)")
                print("  appUuid     : \(payload.appUuid)")
                print("  heartRate   : \(payload.heartRate ?? "nil")")
                print("  rrInterval  : \(payload.rrInterval ?? "nil")")
                print("  prInterval  : \(payload.prInterval ?? "nil")")
                print("  qrsDuration : \(payload.qrsDuration ?? "nil")")
                print("  pDuration   : \(payload.pDuration ?? "nil")")
                print("  qtInterval  : \(payload.qtInterval ?? "nil")")
                print("  qtCorrected : \(payload.qtCorrected ?? "nil")")
                print("  qtDistance  : \(payload.qtDistance ?? "nil")")
                print("  qtMax       : \(payload.qtMax ?? "nil")")
                print("  qtMin       : \(payload.qtMin ?? "nil")")
                print("  pAxis       : \(payload.pAxis ?? "nil")")
                print("  qrsAxis     : \(payload.qrsAxis ?? "nil")")
                print("  rv1         : \(payload.rv1 ?? "nil")")
                print("  rv5         : \(payload.rv5 ?? "nil")")
                print("  sv1         : \(payload.sv1 ?? "nil")")
                print("  sv5         : \(payload.sv5 ?? "nil")")
                print("  diagnosis   : \(payload.diagnosis ?? "nil")")
                print("  duration    : \(payload.duration ?? "nil")")
                print("  appVersion  : \(payload.appVersion ?? "nil")")
                print("  recordedAt  : \(payload.recordedAt?.description ?? "nil")")
                print("  fileData    : \(payload.fileData?.count ?? 0) bytes")
                print("  imageData   : \(payload.imageData?.count ?? 0) bytes")
                print("────────────────────────────────────────")

                try await uploadService.upload(payload: payload)
                uploadSuccess = true
            } catch let error as APIError {
                switch error {
                case .sessionExpired, .invalidCredentials:
                    uploadError = L10n.Auth.Login.errorSessionExpired
                default:
                    uploadError = error.errorDescription ?? L10n.Auth.Login.errorGeneric
                }
                uploadSuccess = false
            } catch {
                uploadError = L10n.Auth.Login.errorGeneric
                uploadSuccess = false
            }
            isUploading = false
            showUploadResult = true
        }
    }

    private func renderECGImage() -> Data? {
        let view = ECGPrintView(
            patient: patient,
            templateData: templateData,
            ecgData: ecgData,
            sampleRate: sampleRate,
            measurements: measurements,
            diagnosisLines: diagnosisLines
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.uiImage.flatMap { $0.jpegData(compressionQuality: 0.85) }
    }

    private func nilIfEmpty(_ s: String?) -> String? {
        guard let s, !s.isEmpty, s != "—" else { return nil }
        return s
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
