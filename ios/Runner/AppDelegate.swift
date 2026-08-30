import AuthenticationServices
import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  UIDocumentPickerDelegate, ASWebAuthenticationPresentationContextProviding,
  ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

  private let googleChannelName = "diyar/google_auth"
  private let documentChannelName = "diyar/document_picker"
  private let appleChannelName = "diyar/apple_auth"

  private var googleChannel: FlutterMethodChannel?
  private var documentChannel: FlutterMethodChannel?
  private var appleChannel: FlutterMethodChannel?
  private var googleSession: ASWebAuthenticationSession?
  private var appleController: ASAuthorizationController?
  private var pendingGoogleCallback: String?
  private var pendingDocumentResult: FlutterResult?
  private var pendingAppleResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    googleChannel = FlutterMethodChannel(name: googleChannelName, binaryMessenger: messenger)
    documentChannel = FlutterMethodChannel(name: documentChannelName, binaryMessenger: messenger)
    appleChannel = FlutterMethodChannel(name: appleChannelName, binaryMessenger: messenger)

    googleChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleGoogle(call: call, result: result)
    }
    documentChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleDocument(call: call, result: result)
    }
    appleChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleApple(call: call, result: result)
    }
  }

  // MARK: Google OAuth

  private func handleGoogle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "consumeInitialGoogleCallback":
      let callback = pendingGoogleCallback
      pendingGoogleCallback = nil
      result(callback)
    case "startGoogleLogin":
      guard let arguments = call.arguments as? [String: Any],
            let rawURL = arguments["url"] as? String,
            let url = URL(string: rawURL) else {
        result(false)
        return
      }

      googleSession = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: "diyar"
      ) { [weak self] callbackURL, error in
        self?.googleSession = nil
        if let callbackURL {
          self?.googleChannel?.invokeMethod("onGoogleCallback", arguments: callbackURL.absoluteString)
        } else {
          // The Dart side will translate this callback into a localized error. This
          // also handles user cancellation without leaving the completer hanging.
          self?.googleChannel?.invokeMethod(
            "onGoogleCallback",
            arguments: "diyar://auth/google-callback?error=oauth_failed"
          )
        }
      }
      googleSession?.presentationContextProvider = self
      googleSession?.prefersEphemeralWebBrowserSession = false
      result(googleSession?.start() == true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "diyar" {
      pendingGoogleCallback = url.absoluteString
      googleChannel?.invokeMethod("onGoogleCallback", arguments: url.absoluteString)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  // MARK: Native document picker (profile images, verification documents, attachments)

  private func handleDocument(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickDocument" || call.method == "pickMultipleDocuments" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard pendingDocumentResult == nil else {
      result(FlutterError(code: "PICKER_BUSY", message: "A document picker is already open.", details: nil))
      return
    }

    pendingDocumentResult = result
    let allowsMultiple = call.method == "pickMultipleDocuments"
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [UTType.image, UTType.pdf],
        asCopy: true
      )
    } else {
      picker = UIDocumentPickerViewController(
        documentTypes: ["public.image", "com.adobe.pdf"],
        in: .import
      )
    }
    picker.allowsMultipleSelection = allowsMultiple
    picker.delegate = self
    guard let presenter = topViewController() else {
      pendingDocumentResult = nil
      result(FlutterError(code: "PICKER_UNAVAILABLE", message: "Unable to open the document picker.", details: nil))
      return
    }
    presenter.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let result = pendingDocumentResult
    pendingDocumentResult = nil
    let documents = urls.compactMap(copyPickedDocument)
    DispatchQueue.main.async {
      if controller.allowsMultipleSelection {
        result?(documents)
      } else {
        result?(documents.first)
      }
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pendingDocumentResult
    pendingDocumentResult = nil
    result?(controller.allowsMultipleSelection ? [] : nil)
  }

  private func copyPickedDocument(from sourceURL: URL) -> [String: Any]? {
    let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing { sourceURL.stopAccessingSecurityScopedResource() }
    }

    let fileManager = FileManager.default
    let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("picked_documents", isDirectory: true)
    do {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
      let filename = sourceURL.lastPathComponent.isEmpty ? "document" : sourceURL.lastPathComponent
      let destination = directory.appendingPathComponent(UUID().uuidString + "_" + filename)
      if fileManager.fileExists(atPath: destination.path) {
        try fileManager.removeItem(at: destination)
      }
      try fileManager.copyItem(at: sourceURL, to: destination)
      let attributes = try fileManager.attributesOfItem(atPath: destination.path)
      let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
      return [
        "path": destination.path,
        "name": filename,
        "contentType": mimeType(for: filename),
        "size": size,
      ]
    } catch {
      return nil
    }
  }

  private func mimeType(for filename: String) -> String {
    switch URL(fileURLWithPath: filename).pathExtension.lowercased() {
    case "jpg", "jpeg": return "image/jpeg"
    case "png": return "image/png"
    case "heic": return "image/heic"
    case "webp": return "image/webp"
    case "gif": return "image/gif"
    case "pdf": return "application/pdf"
    default: return "application/octet-stream"
    }
  }

  // MARK: Sign in with Apple

  private func handleApple(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "signIn" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard pendingAppleResult == nil else {
      result(FlutterError(code: "APPLE_BUSY", message: "An Apple sign-in request is already running.", details: nil))
      return
    }

    pendingAppleResult = result
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]
    appleController = ASAuthorizationController(authorizationRequests: [request])
    appleController?.delegate = self
    appleController?.presentationContextProvider = self
    appleController?.performRequests()
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    guard let result = pendingAppleResult else { return }
    pendingAppleResult = nil
    appleController = nil
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      result(FlutterError(code: "APPLE_INVALID_CREDENTIAL", message: "Apple returned an invalid credential.", details: nil))
      return
    }

    var response: [String: Any] = ["userIdentifier": credential.user]
    if let token = credential.identityToken,
       let tokenString = String(data: token, encoding: .utf8) {
      response["identityToken"] = tokenString
    }
    if let code = credential.authorizationCode,
       let codeString = String(data: code, encoding: .utf8) {
      response["authorizationCode"] = codeString
    }
    if let email = credential.email { response["email"] = email }
    if let givenName = credential.fullName?.givenName { response["givenName"] = givenName }
    if let familyName = credential.fullName?.familyName { response["familyName"] = familyName }
    result(response)
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    guard let result = pendingAppleResult else { return }
    pendingAppleResult = nil
    appleController = nil
    let nsError = error as NSError
    // ASAuthorizationError.Code.canceled is 1001 on all supported iOS versions.
    if nsError.code == 1001 {
      result(FlutterError(code: "APPLE_CANCELED", message: "Sign in with Apple was canceled.", details: nil))
    } else {
      result(FlutterError(code: "APPLE_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: Presentation helpers

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return keyWindow() ?? UIWindow()
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return keyWindow() ?? UIWindow()
  }

  private func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })
  }

  private func topViewController() -> UIViewController? {
    guard let root = keyWindow()?.rootViewController else { return nil }
    return topViewController(from: root)
  }

  private func topViewController(from controller: UIViewController) -> UIViewController {
    if let presented = controller.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigation = controller as? UINavigationController,
       let visible = navigation.visibleViewController {
      return topViewController(from: visible)
    }
    if let tab = controller as? UITabBarController,
       let selected = tab.selectedViewController {
      return topViewController(from: selected)
    }
    return controller
  }
}
