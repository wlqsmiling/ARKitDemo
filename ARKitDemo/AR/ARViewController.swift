//
//  ViewController.swift
//  helloworld
//
//  Created by Liqun Wu on 2021/11/8.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController {
        
    @IBOutlet var sceneView: ARSCNView!
        
    @IBOutlet weak var addBtn: UIButton!
    
    var animations = [String: CAAnimation]()
    
    var idle:Bool = true
    
    var peopleNodeAnchor: ARAnchor? = nil
    
    let coachingOverlay = ARCoachingOverlayView()
        
    var focusSquare = FocusSquare()
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView, viewController: self)
    
    var peopleNode:SCNReferenceNode? = nil
    
    var audioSource:SCNAudioSource? = nil
    var helloAudioSource:SCNAudioSource? = nil
    var hobbiesAudioSource:SCNAudioSource? = nil
    var singAudioSource:SCNAudioSource? = nil
    var danceAudioSource:SCNAudioSource? = nil
    
    var textNode: SCNNode? = nil
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let name = "放置"
        self.addBtn.setTitle(name, for: .normal)
        self.addBtn.sizeToFit()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        // Set up coaching overlay.
        setupCoachingOverlay()
        
        // Set up scene content.
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        loadPeopleNode()
        // Load the DAE animations
//        loadAnimation(withKey: "talking", sceneName: "art.scnassets/Talking", animationIdentifier: "Talking-1")
//        loadAnimation(withKey: "idle", sceneName: "art.scnassets/Orc_Idle", animationIdentifier: "Orc_Idle-1")
//        loadAnimation(withKey: "sing", sceneName: "art.scnassets/Singing", animationIdentifier: "Singing-1")
//        loadAnimation(withKey: "dance", sceneName: "art.scnassets/Breakdance Ending 2", animationIdentifier: "Breakdance Ending 2-1")

        loadVoiceSouces()
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        sceneView.autoenablesDefaultLighting = true
        
        virtualObjectInteraction.selectedObject = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    private func loadPeopleNode() {
        //scn dae
        let idleScene = SCNScene(named: "art.scnassets/ship.scn")!
        let node = SCNReferenceNode()
        
        node.loadingPolicy = .immediate
        node.load()
        
        // Add all the child nodes to the parent node
        for child in idleScene.rootNode.childNodes {
            node.addChildNode(child)
        }
        
        // Set up some properties
//        node.scale = SCNVector3(0.001, 0.001, 0.001)
        
        self.peopleNode = node
    }
    
    private func loadVoiceSouces() {
        let source:SCNAudioSource = SCNAudioSource(fileNamed: "art.scnassets/voice.wav")!
        source.loops = false
        source.load()
        self.audioSource = source
        
        self.helloAudioSource = SCNAudioSource(fileNamed: "art.scnassets/hello.mp3")!
        self.helloAudioSource?.loops = false
        self.helloAudioSource?.load()
        
        self.hobbiesAudioSource = SCNAudioSource(fileNamed: "art.scnassets/hobbies.mp3")!
        self.hobbiesAudioSource?.loops = false
        self.hobbiesAudioSource?.load()
        
        self.singAudioSource = SCNAudioSource(fileNamed: "art.scnassets/sing.mp3")!
        self.singAudioSource?.loops = false
        self.singAudioSource?.load()
        
        self.danceAudioSource = SCNAudioSource(fileNamed: "art.scnassets/dance.mp3")!
        self.danceAudioSource?.loops = false
        self.danceAudioSource?.load()
    }
    
    func loadAnimation(withKey key: String, sceneName: String, animationIdentifier: String) {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            // The animation will only play once
            animationObject.repeatCount = 100000
            // To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(1)
            animationObject.fadeOutDuration = CGFloat(0.5)
            animationObject.autoreverses = true
            // Store the animation for later use
            animations[key] = animationObject
        }
    }
    
    func playAnimation(key: String) {
        // Add the animation to start playing it right away
        sceneView.scene.rootNode.addAnimation(animations[key]!, forKey: key)
    }
    
    func stopAnimations() {
        // Stop the animation with a smooth transition
        for key in animations.keys {
            sceneView.scene.rootNode.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
        }
    }
    
    func updateFocusSquare() {
        
        if self.peopleNode?.parent != nil {
            self.focusSquare.hide()
            addBtn.isHidden = true
            self.coachingOverlay.activatesAutomatically = false
            self.coachingOverlay.setActive(false, animated: false)
            return
        }
        
        if coachingOverlay.isActive {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
        }
        
        // Perform ray casting only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
           let query = self.sceneView.getRaycastQuery(),
           let result = sceneView.castRay(for: query).first {

            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
            }
            if !coachingOverlay.isActive {
                addBtn.isHidden = false
            }
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addBtn.isHidden = true
        }
    }
    
    // - Tag: GetTrackedRaycast
    func createTrackedRaycastAndSet3DPosition(from query: ARRaycastQuery) -> ARTrackedRaycast? {
        
        return self.sceneView.session.trackedRaycast(query) { (results) in
            self.setVirtualObject3DPosition(results)
        }
    }
    
    // - Tag: ProcessRaycastResults
    private func setVirtualObject3DPosition(_ results: [ARRaycastResult]) {
        
        guard let result = results.first else {
            fatalError("Unexpected case: the update handler is always supposed to return at least one result.")
        }
                
        
        // If the virtual object is not yet in the scene, add it.
        if self.peopleNode!.parent == nil {
            self.sceneView.scene.rootNode.addChildNode(self.peopleNode!)
        }

        let t = result.worldTransform
        self.peopleNode!.position = SCNVector3(x: t.columns.3.x, y: t.columns.3.y, z: t.columns.3.z)
        
        self.addOrUpdateAnchor()
    }
    
    func addOrUpdateAnchor() {
        // If the anchor is not nil, remove it from the session.
        if let anchor = self.peopleNodeAnchor {
            session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: self.peopleNode!.simdWorldTransform)
        self.peopleNodeAnchor = newAnchor
        self.sceneView.session.add(anchor: newAnchor)
    }
    
    @IBAction func onAddBtnClicked(_ sender: Any) {
        if let sender = sender as? UIButton {
            sender.isHidden = true
        }
        
        let point = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        let query = self.sceneView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any)
        let _ = createTrackedRaycastAndSet3DPosition(from: query!)
        
        peopleNode!.isHidden = false
    }
    
    @IBAction func dismissButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
        
    func generate3DText(text: String) {
        let scnText = SCNText(string: text, extrusionDepth: 1)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        scnText.materials = [material]
        let changeColor = SCNAction.customAction(duration: 8) { (node, elapsedTime) -> () in
            let percentage = elapsedTime / 8
            let color = UIColor.init(white: 1.0, alpha: 1 - percentage)
            node.geometry!.firstMaterial!.diffuse.contents = color
        }
        if textNode == nil {
            textNode = SCNNode()
            let x = self.peopleNode?.position.x ?? 0.0
            let y = self.peopleNode?.position.y ?? 0.0
            let z = self.peopleNode?.position.z ?? 0.0
            textNode!.position = SCNVector3(x: x - 0.06, y: y + 0.18, z: z)
            textNode!.scale = SCNVector3(0.001, 0.001, 0.001)
            textNode!.geometry = scnText
            sceneView.scene.rootNode.addChildNode(textNode!)
            textNode!.runAction(changeColor)
        } else {
            textNode!.geometry = scnText
            textNode!.runAction(changeColor)
        }
    }
}

extension ARViewController : UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let message = textView.text {
                textView.text = "点这里跟我聊天"
                textView.layoutIfNeeded()
                // TODO: send text to server and/or show it on the ar scene.
                if message != "" {
                    generate3DText(text: message)
                    stopAnimations()
                    self.peopleNode!.removeAllAudioPlayers()
                    if message.contains("你好") || message.contains("hello") || message.contains("介绍一下吧") {
//                        generate3DText(text: "你好，我是" + character!.name!)
                        self.peopleNode!.addAudioPlayer(SCNAudioPlayer(source: helloAudioSource!))
                        playAnimation(key: "talking")
                    } else if message.contains("爱好") || message.contains("平时") || message.contains("兴趣") {
                        self.peopleNode!.addAudioPlayer(SCNAudioPlayer(source: hobbiesAudioSource!))
                        playAnimation(key: "talking")
                    } else if message.contains("唱") || message.contains("首") || message.contains("歌") {
                        playAnimation(key: "sing")
                        self.peopleNode!.addAudioPlayer(SCNAudioPlayer(source: singAudioSource!))
                    } else if message.contains("跳舞") || message.contains("跳一段") || message.contains("一段舞") {
                        self.peopleNode!.addAudioPlayer(SCNAudioPlayer(source: danceAudioSource!))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            self.playAnimation(key: "dance")
                        }
                    }
                }
                textView.textAlignment = .center
                textView.resignFirstResponder()
            }
            return false
        }
        return true
    }
}
