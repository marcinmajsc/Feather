import Foundation
import UIKit
import Vapor

/// Serves only the public CA profile, without requiring an already trusted TLS certificate.
final class LocalCAProfileServer {
	let url: URL
	private let _application: Application
	private var _backgroundTask: UIBackgroundTaskIdentifier = .invalid
	private var _stopped = false

	init(profile: Data) throws {
		let port = Int.random(in: 49152...65535)
		let filename = "\(UUID().uuidString).mobileconfig"
		guard let url = URL(string: "http://127.0.0.1:\(port)/\(filename)") else {
			throw CocoaError(.fileReadInvalidFileName)
		}
		self.url = url

		let application = Application(ServerInstaller.env)
		_application = application
		application.threadPool = .init(numberOfThreads: 1)
		application.http.server.configuration.address = .hostname("127.0.0.1", port: port)
		application.get(PathComponent(stringLiteral: filename)) { request -> Response in
			Response(status: .ok, headers: [
				"Content-Type": "application/x-apple-aspen-config",
				"Content-Disposition": "attachment; filename=\"FeatherLocalCA.mobileconfig\"",
				"Cache-Control": "no-store"
			], body: .init(data: profile))
		}

		// Keep serving while the browser downloads the profile after Feather enters the background.
		_backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Local CA profile") { [weak self] in
			self?.stop()
		}
		do {
			try application.server.start()
		} catch {
			stop()
			throw error
		}
	}

	func stop() {
		guard !_stopped else { return }
		_stopped = true
		_application.server.shutdown()
		_application.shutdown()
		if _backgroundTask != .invalid {
			UIApplication.shared.endBackgroundTask(_backgroundTask)
			_backgroundTask = .invalid
		}
	}

	deinit {
		stop()
	}
}
