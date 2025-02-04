//
//  ScanOrPasteCodeViewModel.swift
//  DuckDuckGo
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public protocol ScanOrPasteCodeViewModelDelegate: AnyObject {

    var pasteboardString: String? { get }

    func startConnectMode() async -> String?

    /// Returns true if the code is valid format and should stop scanning
    func syncCodeEntered(code: String) -> Bool
    func codeCollectionCancelled()
    func gotoSettings()

}

public class ScanOrPasteCodeViewModel: ObservableObject {

    public enum VideoPermission {
        case unknown, authorised, denied
    }

    public enum State {
        case showScanner, manualEntry, showQRCode
    }

    public enum StartConnectModeResult {
        case authorised(code: String), denied, failed
    }

    @Published public var videoPermission: VideoPermission = .unknown

    @Published var showCamera = true
    @Published var state = State.showScanner
    @Published var manuallyEnteredCode: String?
    @Published var isValidating = false
    @Published var codeError: String?

    var canSubmitManualCode: Bool {
        manuallyEnteredCode?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    public weak var delegate: ScanOrPasteCodeViewModelDelegate?

    var showQRCodeModel: ShowQRCodeViewModel?

    let isInRecoveryMode: Bool

    public init(isInRecoveryMode: Bool) {
        self.isInRecoveryMode = isInRecoveryMode
    }

    func codeScanned(_ code: String) -> Bool {
        return delegate?.syncCodeEntered(code: code) ?? false
    }

    func cameraUnavailable() {
        showCamera = false
    }

    func pasteCode() {
        guard let string = delegate?.pasteboardString else { return }
        self.manuallyEnteredCode = string
        isValidating = true

        Task { @MainActor in

            if #available(iOS 16.0, *) {
                try await Task.sleep(for: .seconds(4))
            }

            // Tidy this up when wiring up to the backend
            if manuallyEnteredCode == "wrong" {
                isValidating = false
                codeError = "Invalid code"
            } else if let code = manuallyEnteredCode {
                isValidating = false
                _ = delegate?.syncCodeEntered(code: code)
            }
        }

    }

    func cancel() {
        delegate?.codeCollectionCancelled()
    }

    func submitAction() {
        // what to do here??
        _ = delegate?.syncCodeEntered(code: manuallyEnteredCode ?? "")
    }

    func startConnectMode() -> ShowQRCodeViewModel {
        let model = ShowQRCodeViewModel()
        showQRCodeModel = model
        Task { @MainActor in
            showQRCodeModel?.code = await delegate?.startConnectMode()
        }
        return model
    }

    func gotoSettings() {
        delegate?.gotoSettings()
    }

}
