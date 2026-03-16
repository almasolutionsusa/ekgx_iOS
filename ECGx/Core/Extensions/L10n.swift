//
//  L10n.swift
//  ECGx
//
//  Type-safe localized string access.
//  Usage: L10n.Auth.Login.title  (instead of "auth.login.title".localized)
//

import Foundation

enum L10n {

    // MARK: - Auth

    enum Auth {

        enum Login {
            static let title                   = "auth.login.title".localized
            static let subtitle                = "auth.login.subtitle".localized
            static let emailLabel              = "auth.login.emailLabel".localized
            static let emailPlaceholder        = "auth.login.emailPlaceholder".localized
            static let passwordLabel           = "auth.login.passwordLabel".localized
            static let passwordPlaceholder     = "auth.login.passwordPlaceholder".localized
            static let loginButton             = "auth.login.loginButton".localized
            static let registerButton          = "auth.login.registerButton".localized
            static let forgotPassword          = "auth.login.forgotPassword".localized
            static let noAccount               = "auth.login.noAccount".localized
            static let errorInvalidCredentials = "auth.login.errorInvalidCredentials".localized
            static let errorNetwork            = "auth.login.errorNetwork".localized
            static let errorGeneric            = "auth.login.errorGeneric".localized
            static let pinButton               = "auth.login.pinButton".localized
            static let pinTitle                = "auth.login.pinTitle".localized
            static let pinSubtitle             = "auth.login.pinSubtitle".localized
            static let pinPlaceholder          = "auth.login.pinPlaceholder".localized
            static let pinErrorEmpty           = "auth.login.pinErrorEmpty".localized
            static let pinErrorInvalid         = "auth.login.pinErrorInvalid".localized
            static let pinBackToEmail          = "auth.login.pinBackToEmail".localized
        }

        enum Register {
            static let title                    = "auth.register.title".localized
            static let subtitle                 = "auth.register.subtitle".localized
            static let firstNameLabel           = "auth.register.firstNameLabel".localized
            static let firstNamePlaceholder     = "auth.register.firstNamePlaceholder".localized
            static let lastNameLabel            = "auth.register.lastNameLabel".localized
            static let lastNamePlaceholder      = "auth.register.lastNamePlaceholder".localized
            static let facilityLabel            = "auth.register.facilityLabel".localized
            static let facilityPlaceholder      = "auth.register.facilityPlaceholder".localized
            static let roleLabel                = "auth.register.roleLabel".localized
            static let rolePlaceholder          = "auth.register.rolePlaceholder".localized
            static let departmentLabel          = "auth.register.departmentLabel".localized
            static let departmentPlaceholder    = "auth.register.departmentPlaceholder".localized
            static let npiLabel                 = "auth.register.npiLabel".localized
            static let npiPlaceholder           = "auth.register.npiPlaceholder".localized
            static let titleLabel               = "auth.register.titleLabel".localized
            static let titlePlaceholder         = "auth.register.titlePlaceholder".localized
            static let degreeLabel              = "auth.register.degreeLabel".localized
            static let degreePlaceholder        = "auth.register.degreePlaceholder".localized
            static let emailLabel               = "auth.register.emailLabel".localized
            static let emailPlaceholder         = "auth.register.emailPlaceholder".localized
            static let confirmEmailLabel        = "auth.register.confirmEmailLabel".localized
            static let confirmEmailPlaceholder  = "auth.register.confirmEmailPlaceholder".localized
            static let passwordLabel            = "auth.register.passwordLabel".localized
            static let passwordPlaceholder      = "auth.register.passwordPlaceholder".localized
            static let confirmPasswordLabel     = "auth.register.confirmPasswordLabel".localized
            static let confirmPasswordPlaceholder = "auth.register.confirmPasswordPlaceholder".localized
            static let registerButton           = "auth.register.registerButton".localized
            static let haveAccount              = "auth.register.haveAccount".localized
            static let signInLink               = "auth.register.signInLink".localized
            static let errorEmailInUse          = "auth.register.errorEmailInUse".localized
            static let sectionPersonal          = "auth.register.sectionPersonal".localized
            static let sectionProfessional      = "auth.register.sectionProfessional".localized
            static let sectionCredentials       = "auth.register.sectionCredentials".localized
            static let optionalBadge            = "auth.register.optionalBadge".localized
        }
    }

    // MARK: - Validation

    enum Validation {
        static let emailEmpty       = "validation.email.empty".localized
        static let emailInvalid     = "validation.email.invalid".localized
        static let emailMismatch    = "validation.email.mismatch".localized
        static let passwordEmpty    = "validation.password.empty".localized
        static let passwordTooShort = "validation.password.tooShort".localized
        static let passwordMismatch = "validation.password.mismatch".localized
        static let nameEmpty        = "validation.name.empty".localized
        static let required         = "validation.required".localized
    }

    // MARK: - Branding

    enum Branding {
        static let appName   = "branding.appName".localized
        static let tagline   = "branding.tagline".localized
        static let poweredBy = "branding.poweredBy".localized
    }

    // MARK: - Common

    enum Common {
        static let loading       = "common.loading".localized
        static let cancel        = "common.cancel".localized
        static let ok            = "common.ok".localized
        static let retry         = "common.retry".localized
        static let dismiss       = "common.dismiss".localized
        static let showPassword  = "common.showPassword".localized
        static let hidePassword  = "common.hidePassword".localized
        static let error         = "common.error".localized
        static let success       = "common.success".localized
        static let back          = "common.back".localized
        static let open          = "common.open".localized
    }

    // MARK: - Home

    enum Home {
        enum Nav {
            static let menuButton = "home.nav.menuButton".localized
        }
        enum Greeting {
            static let morning   = "home.greeting.morning".localized
            static let afternoon = "home.greeting.afternoon".localized
            static let evening   = "home.greeting.evening".localized
        }
        static let subtitle = "home.subtitle".localized

        enum Device {
            static let connect      = "home.device.connect".localized
            static let connected    = "home.device.connected".localized
            static let disconnected = "home.device.disconnected".localized
            static let searching    = "home.device.searching".localized
            static let tapToConnect = "home.device.tapToConnect".localized
        }

        enum Card {
            enum Recording {
                static let title    = "home.card.recording.title".localized
                static let subtitle = "home.card.recording.subtitle".localized
            }
            enum Patients {
                static let title    = "home.card.patients.title".localized
                static let subtitle = "home.card.patients.subtitle".localized
            }
            enum Cloud {
                static let title    = "home.card.cloud.title".localized
                static let subtitle = "home.card.cloud.subtitle".localized
            }
        }

        enum Profile {
            static let rolePhysician     = "home.profile.rolePhysician".localized
            static let roleNurse         = "home.profile.roleNurse".localized
            static let roleTechnician    = "home.profile.roleTechnician".localized
            static let roleAdministrator = "home.profile.roleAdministrator".localized
        }
    }

    // MARK: - Menu

    enum Menu {
        static let title              = "menu.title".localized
        static let settings           = "menu.settings".localized
        static let myAccount          = "menu.myAccount".localized
        static let support            = "menu.support".localized
        static let faq                = "menu.faq".localized
        static let indicationsForUse  = "menu.indicationsForUse".localized
        static let logout             = "menu.logout".localized
        static let logoutConfirm      = "menu.logoutConfirm".localized
        static let logoutConfirmButton = "menu.logoutConfirmButton".localized
    }

    // MARK: - Cloud & Reports

    enum Cloud {
        enum Nav {
            static let title       = "cloud.nav.title".localized
            static let subtitle    = "cloud.nav.subtitle".localized
            static let allSynced   = "cloud.nav.allSynced".localized
        }
        enum Patients {
            static let header      = "cloud.patients.header".localized
            static let searchPH    = "cloud.patients.searchPH".localized
            static let emptyTitle  = "cloud.patients.emptyTitle".localized
        }
        enum Recordings {
            static let selectTitle    = "cloud.recordings.selectTitle".localized
            static let selectSubtitle = "cloud.recordings.selectSubtitle".localized
            static let emptyTitle     = "cloud.recordings.emptyTitle".localized
            static let emptySubtitle  = "cloud.recordings.emptySubtitle".localized
            static let examSingular   = "cloud.recordings.examSingular".localized
            static let examPlural     = "cloud.recordings.examPlural".localized
        }
    }

    // MARK: - Patient List

    enum Patients {
        enum Nav {
            static let title        = "patients.nav.title".localized
            static let addButton    = "patients.nav.addButton".localized
            static func totalCount(_ n: Int) -> String {
                String(format: "patients.nav.totalCount".localized, n)
            }
        }
        enum Search {
            static let placeholder  = "patients.search.placeholder".localized
        }
        enum Empty {
            static let noPatients         = "patients.empty.noPatients".localized
            static let noResults          = "patients.empty.noResults".localized
            static let noPatientsSubtitle = "patients.empty.noPatientsSubtitle".localized
            static let clearSearch        = "patients.empty.clearSearch".localized
            static func noResultsSubtitle(_ query: String) -> String {
                String(format: "patients.empty.noResultsSubtitle".localized, query)
            }
        }
        enum Add {
            static let sheetTitle   = "patients.add.sheetTitle".localized
            static let sheetSubtitle = "patients.add.sheetSubtitle".localized
            static let firstName    = "patients.add.firstName".localized
            static let firstNamePH  = "patients.add.firstNamePH".localized
            static let lastName     = "patients.add.lastName".localized
            static let lastNamePH   = "patients.add.lastNamePH".localized
            static let dateOfBirth  = "patients.add.dateOfBirth".localized
            static let dateOfBirthPH = "patients.add.dateOfBirthPH".localized
            static let gender       = "patients.add.gender".localized
            static let mrn          = "patients.add.mrn".localized
            static let mrnPH        = "patients.add.mrnPH".localized
            static let cancelButton = "patients.add.cancelButton".localized
            static let submitButton = "patients.add.submitButton".localized
        }
    }

    // MARK: - Settings

    enum Settings {
        enum Nav {
            static let title          = "settings.nav.title".localized
            static let subtitle       = "settings.nav.subtitle".localized
            static let unsavedChanges = "settings.nav.unsavedChanges".localized
            static let discardChanges = "settings.nav.discardChanges".localized
            static let saveChanges    = "settings.nav.saveChanges".localized
        }
        enum Panel {
            static let categories     = "settings.panel.categories".localized
        }
        enum ECG {
            static let sectionTitle    = "settings.ecg.sectionTitle".localized
            static let sectionSubtitle = "settings.ecg.sectionSubtitle".localized
            static let minnesotaTitle  = "settings.ecg.minnesotaTitle".localized
            static let minnesotaSubtitle = "settings.ecg.minnesotaSubtitle".localized
            static let leadV5Title     = "settings.ecg.leadV5Title".localized
            static let leadV5Subtitle  = "settings.ecg.leadV5Subtitle".localized
            static let emgTitle        = "settings.ecg.emgTitle".localized
            static let emgSubtitle     = "settings.ecg.emgSubtitle".localized
            static let highPassTitle   = "settings.ecg.highPassTitle".localized
            static let highPassSubtitle = "settings.ecg.highPassSubtitle".localized
            static let lowPassTitle    = "settings.ecg.lowPassTitle".localized
            static let lowPassSubtitle = "settings.ecg.lowPassSubtitle".localized
            static let acNotchTitle    = "settings.ecg.acNotchTitle".localized
            static let acNotchSubtitle = "settings.ecg.acNotchSubtitle".localized
        }
        enum Display {
            static let sectionTitle    = "settings.display.sectionTitle".localized
            static let sectionSubtitle = "settings.display.sectionSubtitle".localized
            static let darkModeTitle   = "settings.display.darkModeTitle".localized
            static let darkModeSubtitle = "settings.display.darkModeSubtitle".localized
        }
        enum Privacy {
            static let sectionTitle      = "settings.privacy.sectionTitle".localized
            static let sectionSubtitle   = "settings.privacy.sectionSubtitle".localized
            static let promoEmailTitle   = "settings.privacy.promoEmailTitle".localized
            static let promoEmailSubtitle = "settings.privacy.promoEmailSubtitle".localized
        }
        enum Security {
            static let sectionTitle      = "settings.security.sectionTitle".localized
            static let sectionSubtitle   = "settings.security.sectionSubtitle".localized
            static let autoLockTitle     = "settings.security.autoLockTitle".localized
            static let autoLockSubtitle  = "settings.security.autoLockSubtitle".localized
            static let demoTitle         = "settings.security.demoTitle".localized
            static let demoActiveBadge   = "settings.security.demoActiveBadge".localized
            static let demoSubtitle      = "settings.security.demoSubtitle".localized
            static let demoError         = "settings.security.demoError".localized
        }
        enum Demo {
            static let sheetTitle    = "settings.demo.sheetTitle".localized
            static let sheetSubtitle = "settings.demo.sheetSubtitle".localized
            static let fieldLabel    = "settings.demo.fieldLabel".localized
            static let fieldPH       = "settings.demo.fieldPH".localized
            static let unlockButton  = "settings.demo.unlockButton".localized
        }
    }

    // MARK: - Placeholder

    enum Placeholder {
        static let comingSoon         = "placeholder.comingSoon".localized
        static let comingSoonSubtitle = "placeholder.comingSoonSubtitle".localized
    }

    // MARK: - My Account

    enum Account {

        enum Nav {
            static let title          = "account.nav.title".localized
            static let subtitle       = "account.nav.subtitle".localized
            static let unsavedChanges = "account.nav.unsavedChanges".localized
            static let discardChanges = "account.nav.discardChanges".localized
            static let saveChanges    = "account.nav.saveChanges".localized
        }

        enum Profile {
            static let changePhoto    = "account.profile.changePhoto".localized
        }

        enum Personal {
            static let sectionTitle    = "account.personal.sectionTitle".localized
            static let sectionSubtitle = "account.personal.sectionSubtitle".localized
            static let firstName       = "account.personal.firstName".localized
            static let firstNamePH     = "account.personal.firstNamePH".localized
            static let lastName        = "account.personal.lastName".localized
            static let lastNamePH      = "account.personal.lastNamePH".localized
            static let workEmail       = "account.personal.workEmail".localized
            static let workEmailPH     = "account.personal.workEmailPH".localized
            static let phone           = "account.personal.phone".localized
            static let phonePH         = "account.personal.phonePH".localized
            static let errorFirstName  = "account.personal.errorFirstName".localized
            static let errorLastName   = "account.personal.errorLastName".localized
            static let errorEmail      = "account.personal.errorEmail".localized
        }

        enum Address {
            static let sectionTitle    = "account.address.sectionTitle".localized
            static let sectionSubtitle = "account.address.sectionSubtitle".localized
            static let line1           = "account.address.line1".localized
            static let line1PH         = "account.address.line1PH".localized
            static let line2           = "account.address.line2".localized
            static let line2PH         = "account.address.line2PH".localized
            static let city            = "account.address.city".localized
            static let cityPH          = "account.address.cityPH".localized
            static let state           = "account.address.state".localized
            static let statePH         = "account.address.statePH".localized
            static let zip             = "account.address.zip".localized
            static let zipPH           = "account.address.zipPH".localized
            static let country         = "account.address.country".localized
            static let countryPH       = "account.address.countryPH".localized
        }

        enum Facility {
            static let sectionTitle    = "account.facility.sectionTitle".localized
            static let sectionSubtitle = "account.facility.sectionSubtitle".localized
            static let currentFacility = "account.facility.currentFacility".localized
            static let department      = "account.facility.department".localized
            static let departmentPH    = "account.facility.departmentPH".localized
            static let role            = "account.facility.role".localized
            static let rolePH          = "account.facility.rolePH".localized
        }

        enum Security {
            static let sectionTitle      = "account.security.sectionTitle".localized
            static let sectionSubtitle   = "account.security.sectionSubtitle".localized
            static let setPinTitle       = "account.security.setPinTitle".localized
            static let setPinSubtitle    = "account.security.setPinSubtitle".localized
            static let changePassTitle   = "account.security.changePassTitle".localized
            static let changePassSubtitle = "account.security.changePassSubtitle".localized
        }

        enum Danger {
            static let sectionTitle      = "account.danger.sectionTitle".localized
            static let sectionSubtitle   = "account.danger.sectionSubtitle".localized
            static let deactivateTitle   = "account.danger.deactivateTitle".localized
            static let deactivateSubtitle = "account.danger.deactivateSubtitle".localized
            static let deactivateButton  = "account.danger.deactivateButton".localized
            static let alertTitle        = "account.danger.alertTitle".localized
            static let alertMessage      = "account.danger.alertMessage".localized
            static let alertCancel       = "account.danger.alertCancel".localized
            static let alertConfirm      = "account.danger.alertConfirm".localized
        }

        enum Pin {
            static let sheetTitle    = "account.pin.sheetTitle".localized
            static let sheetSubtitle = "account.pin.sheetSubtitle".localized
            static let fieldNew      = "account.pin.fieldNew".localized
            static let fieldNewPH    = "account.pin.fieldNewPH".localized
            static let fieldConfirm  = "account.pin.fieldConfirm".localized
            static let fieldConfirmPH = "account.pin.fieldConfirmPH".localized
            static let submitButton  = "account.pin.submitButton".localized
            static let errorDigits   = "account.pin.errorDigits".localized
            static let errorMismatch = "account.pin.errorMismatch".localized
        }

        enum Password {
            static let sheetTitle      = "account.password.sheetTitle".localized
            static let sheetSubtitle   = "account.password.sheetSubtitle".localized
            static let fieldCurrent    = "account.password.fieldCurrent".localized
            static let fieldCurrentPH  = "account.password.fieldCurrentPH".localized
            static let fieldNew        = "account.password.fieldNew".localized
            static let fieldNewPH      = "account.password.fieldNewPH".localized
            static let fieldConfirm    = "account.password.fieldConfirm".localized
            static let fieldConfirmPH  = "account.password.fieldConfirmPH".localized
            static let submitButton    = "account.password.submitButton".localized
            static let errorCurrent    = "account.password.errorCurrent".localized
            static let errorTooShort   = "account.password.errorTooShort".localized
            static let errorMismatch   = "account.password.errorMismatch".localized
        }
    }
}
