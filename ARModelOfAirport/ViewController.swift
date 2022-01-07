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
    
    
    // MARK: - IB Outlets
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    
    // MARK: - IB Actions
    @IBAction func resetButtonPressed(_ sender: Any) {
        self.resetARSession()
    }
    
    @IBAction func tapGestureHandler(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initScene()
        self.initARSession()
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
extension ViewController {
    
    // Add code here...
    
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
    // call once for every frame update
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateStatus()
        }
    }
    
}

// MARK: - Focus Node Management
extension ViewController {
    
    // Add code here...
    
}
