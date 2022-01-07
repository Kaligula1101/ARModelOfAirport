//
//  ViewController.swift
//  ARModelOfAirport
//
//  Created by Kaligula on 07.01.2022.
//

import UIKit
import SceneKit
import ARKit

// MARK: - App State Management
enum AppState: Int {
    case detectSurface
    case pointAtSurface
    case tapToStart
    case started
}


// MARK: - UIViewController

class ViewController: UIViewController {
    
    // MARK: - Properties
    var trackingStatus: String = ""
    var statusMessage: String = ""
    var appState: AppState = .detectSurface
    
    var focusPoint: CGPoint!
    
    var focusNode: SCNNode!
    
    var modelNode: SCNNode!
    
    
    // MARK: - IB Outlets
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    
    // MARK: - IB Actions
    @IBAction func resetButtonPressed(_ sender: Any) {
        self.resetARSession()
    }
    
    @IBAction func tapGestureHandler(_ sender: Any) {
        guard appState == .tapToStart else {
            return
        }
        
        self.modelNode.isHidden = false
        self.focusNode.isHidden = true
        self.modelNode.position = self.focusNode.position
        
        appState = .started
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initScene()
        self.initCoachingOverlayView()
        self.initARSession()
        self.initFocusNode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("*** ViewWillAppear()")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("*** ViewWillDisappear()")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("*** DidReceiveMemoryWarning()")
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - App Management
extension ViewController {
    
    func startApp() {
        DispatchQueue.main.async {
            self.appState = .detectSurface
        }
    }
    
    func resetApp() {
        DispatchQueue.main.async {
            self.resetARSession()
            self.appState = .detectSurface
        }
    }
    
}

// MARK: - AR Coaching Overlay
extension ViewController: ARCoachingOverlayViewDelegate {
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        self.startApp()
    }
    
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        self.resetApp()
    }
    
    func initCoachingOverlayView() {
        let coachingOverlay = ARCoachingOverlayView()
        // Set the overlay’s session to the same session as the scene view
        coachingOverlay.session = self.sceneView.session
        coachingOverlay.delegate = self
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
        
        self.sceneView.addSubview(coachingOverlay)
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: coachingOverlay, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: coachingOverlay, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: coachingOverlay, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: coachingOverlay, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        ])
    }
    
}

// MARK: - AR Session Management
extension ViewController: ARSCNViewDelegate {
    
    func initARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("*** ARConfig: ARWorld Trackinng Not supported")
            return
        }
        
        let config = ARWorldTrackingConfiguration()
        
        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.planeDetection = .horizontal
        config.isLightEstimationEnabled = true
        config.environmentTexturing = .automatic
        
        sceneView.session.run(config)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            self.trackingStatus = "Tracking: Not Available"
        case .normal:
            self.trackingStatus = ""
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                self.trackingStatus = "Tracking: Limited due to excessive motion"
            case .insufficientFeatures:
                self.trackingStatus = "Tracking: Limited due to insufficient features"
            case .relocalizing:
                self.trackingStatus = "Tracking: Relocalizing..."
            case .initializing:
                self.trackingStatus = "Tracking: Initializing..."
            @unknown default:
                self.trackingStatus = "Tracking: Unknown..."
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        self.trackingStatus = "AR Session Failure: \(error)"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        self.trackingStatus = "AR Session Was Interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        self.trackingStatus = "AR Session Interrupted Ended"
    }
    
    func resetARSession() {
        let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
        config.planeDetection = .horizontal
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
}

// MARK: - Scene Management
extension ViewController {
    
    func initScene() {
        let scene = SCNScene()
        sceneView.scene = scene
        //set view controller as scene view’s delegate
        sceneView.delegate = self
        
        let modelScene = SCNScene(named: "art.scnassets/Scenes/AirportScene.scn")!
        modelNode = modelScene.rootNode.childNode(withName: "Airport", recursively: false)!
        
        modelNode.isHidden = true
        sceneView.scene.rootNode.addChildNode(modelNode)
    }
    
    func updateStatus() {
        switch appState {
        case .detectSurface:
            statusMessage = "Scan available flat surfaces..."
        case .pointAtSurface:
            statusMessage = "Point at designated surface first"
        case .tapToStart:
            statusMessage = "Tap to start"
        case .started:
            statusMessage = "Tap object for more info"
        }
        
        self.statusLabel.text = trackingStatus != "" ? "\(trackingStatus)" : "\(statusMessage)"
    }
    // Call once for every frame update
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusNode()
            self.updateStatus()
        }
    }
    
}

// MARK: - Focus Node Management
extension ViewController {
    
    func initFocusNode() {
        let focusScene = SCNScene(named: "art.scnassets/Scenes/FocusScene.scn")!
        focusNode = focusScene.rootNode.childNode(withName: "Focus", recursively: false)!
        
        focusNode.isHidden = true
        sceneView.scene.rootNode.addChildNode(focusNode)
        
        focusPoint = CGPoint(x: view.center.x, y: view.center.y + view.center.y * 0.1)
        // Notifie the app every time the orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc // Available to the NotificationCenter
    func orientationChanged() {
        focusPoint = CGPoint(x: view.center.x, y: view.center.y + view.center.y * 0.1)
    }
    
    func updateFocusNode() {
        guard appState != .started else {
            focusNode.isHidden = true
            return
        }
        
        if let query = self.sceneView.raycastQuery(from: self.focusPoint, allowing: .estimatedPlane, alignment: .horizontal) {
            let results = self.sceneView.session.raycast(query)
            if results.count == 1 {
                if let match = results.first {
                    // Contains position, orientation and scale information
                    let hit = match.worldTransform
                    
                    self.focusNode.position = SCNVector3(x: hit.columns.3.x, y: hit.columns.3.y, z: hit.columns.3.z)
                    self.appState = .tapToStart
                    focusNode.isHidden = false
                }
            } else {
                self.appState = .pointAtSurface
                focusNode.isHidden = true
            }
        }
    }
}
