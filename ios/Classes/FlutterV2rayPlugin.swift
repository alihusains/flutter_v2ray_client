import Flutter
import UIKit

public class FlutterV2rayPlugin: NSObject, FlutterPlugin {
  private var delaySink: FlutterEventSink?
  private var statusSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_v2ray_client", binaryMessenger: registrar.messenger())
    let instance = FlutterV2rayPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let delayChannel = FlutterEventChannel(name: "flutter_v2ray_client/delay", binaryMessenger: registrar.messenger())
    delayChannel.setStreamHandler(instance)

    let statusChannel = FlutterEventChannel(name: "flutter_v2ray_client/status", binaryMessenger: registrar.messenger())
    statusChannel.setStreamHandler(StatusStreamHandler(plugin: instance))
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getCoreVersion":
      result("N/A (iOS Unsupported)")
    case "initializeV2Ray":
      result(nil)
    case "startV2Ray", "stopV2Ray":
      // Return success but do nothing as it's unsupported
      result(nil)
    case "getServerDelay", "getConnectedServerDelay":
      result(-1) // Return -1 indicating failure/unsupported
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// Separate handler for Status Channel
class StatusStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: FlutterV2rayPlugin?
    init(plugin: FlutterV2rayPlugin) { self.plugin = plugin }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Since iOS is unsupported, we can send a disconnected status immediately
        events("DISCONNECTED")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

extension FlutterV2rayPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.delaySink = events

        guard let args = arguments as? [String: Any],
              let configs = args["configs"] as? [String] else {
            events(FlutterEndOfEventStream)
            return nil
        }

        // Start a mock/fallback test on iOS since native core is missing
        // This prevents the UI from hanging on iOS
        DispatchQueue.global().async {
            for (index, _) in configs.enumerated() {
                // If we don't have the native core, we just return -1 for each
                // Alternatively, you could implement a simple URLSession ping here
                Thread.sleep(forTimeInterval: 0.1) // Simulate work

                DispatchQueue.main.async {
                    self.delaySink?([index, -1])
                }
            }

            DispatchQueue.main.async {
                self.delaySink?(FlutterEndOfEventStream)
            }
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.delaySink = nil
        return nil
    }
}
