//
//  ServerView.swift
//  Feather
//
//  Created by samara on 6.05.2025.
//

import SwiftUI
import NimbleJSON
import NimbleViews
import UIKit

// MARK: - View
struct ServerView: View {
	@Environment(\.openURL) private var openURL
	@State private var _certificateServer: LocalCAProfileServer?
	
	@AppStorage("Feather.ipFix") private var _ipFix: Bool = false
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	private let _serverMethods: [String] = [.localized("Fully Local"), .localized("Semi Local")]
	
	// MARK: Body
	var body: some View {
		Group {
			Section {
				Picker(
					.localized("Server Type"), 
					systemImage: "server.rack", 
					selection: $_serverMethod
				) {
					ForEach(_serverMethods.indices, id: \.description) { index in
						Text(_serverMethods[index]).tag(index)
					}
				}
				Toggle(
					.localized("Only use localhost address"), 
					systemImage: "lifepreserver", 
					isOn: $_ipFix
				)
				.disabled(_serverMethod != 1)
			}
			
			Section {
				Button(.localized("Install Local CA"), systemImage: "folder") {
					do {
						try ServerInstaller.createServerCert()
						_certificateServer?.stop()
						_certificateServer = nil
						let server = try LocalCAProfileServer(
							profile: ServerInstaller.rootCertificateProfileData()
						)
						_certificateServer = server
						openURL(server.url) { accepted in
							guard !accepted else { return }
							server.stop()
							_certificateServer = nil
							UIAlertController.showAlertWithOk(
								title: .localized("Error"),
								message: .localized("Unable to open the browser to download the CA profile.")
							)
						}
					} catch {
						UIAlertController.showAlertWithOk(title: .localized("Error"), message: String(describing: error))
					}
				}
				.disabled(_serverMethod != 0)

				Button(.localized("Install Downloaded Profile"), systemImage: "gear") {
					_openSettings(path: "ManagedConfigurationList")
				}
				Button(.localized("Trust Local CA"), systemImage: "checkmark.shield") {
					_openSettings(path: "About/CERT_TRUST_SETTINGS")
				}
			} footer: {
				Text(.localized("Allow the profile download in Safari. Then open Settings > General > VPN & Device Management and install Feather Local CA. Finally, open General > About > Certificate Trust Settings and enable full trust for Feather Local Root CA."))
			}
		}
	}

	private func _openSettings(path: String) {
		guard let url = URL(string: "App-prefs:root=General&path=\(path)") else { return }
		openURL(url) { accepted in
			guard !accepted else { return }
			UIAlertController.showAlertWithOk(
				title: .localized("Open Settings"),
				message: .localized("Open Settings manually. Install the downloaded profile in General > VPN & Device Management, then enable full trust in General > About > Certificate Trust Settings.")
			)
		}
	}
}
