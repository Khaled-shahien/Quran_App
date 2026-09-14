import Flutter
import UIKit
import workmanager
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var qiblaCompass: QiblaCompass?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SakinaQibla") {
      let compass = QiblaCompass()
      FlutterEventChannel(name: "sakina/qibla_heading", binaryMessenger: registrar.messenger())
        .setStreamHandler(compass)
      qiblaCompass = compass
    }
  }
}

private final class QiblaCompass: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  override init() {
    super.init()
    manager.delegate = self
    manager.headingFilter = 1
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    NotificationCenter.default.addObserver(self, selector: #selector(stop),
      name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(resume),
      name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    guard CLLocationManager.headingAvailable() else {
      events(FlutterError(code: "SENSOR_UNAVAILABLE", message: "Compass sensor unavailable", details: nil))
      return nil
    }
    resume()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stop()
    sink = nil
    return nil
  }

  @objc private func resume() {
    guard sink != nil else { return }
    // Core Location needs location updates to produce geographic trueHeading.
    manager.startUpdatingLocation()
    manager.startUpdatingHeading()
  }

  @objc private func stop() {
    manager.stopUpdatingHeading()
    manager.stopUpdatingLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
    guard heading.trueHeading >= 0, heading.headingAccuracy >= 0 else { return }
    let orientation = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }.first?.interfaceOrientation
    // Core Location reports the portrait top edge; adjust to the screen's top.
    let offset: Double
    switch orientation {
    case .landscapeLeft: offset = 90
    case .landscapeRight: offset = -90
    case .portraitUpsideDown: offset = 180
    default: offset = 0
    }
    sink?(["heading": (heading.trueHeading + offset + 360).truncatingRemainder(dividingBy: 360),
           "needsCalibration": heading.headingAccuracy > 15])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if (error as? CLError)?.code == .denied {
      stop()
      sink?(FlutterError(code: "LOCATION_DENIED", message: "Location permission denied", details: nil))
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    manager.stopUpdatingHeading()
    manager.stopUpdatingLocation()
  }
}
