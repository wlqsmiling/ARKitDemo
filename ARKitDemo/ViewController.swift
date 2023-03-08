//
//  ViewController.swift
//  ARKitDemo
//
//  Created by Nreal on 2023/3/8.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func arSceneBtnClicked(_ sender: Any) {
        let arVC = ARViewController()
        
        arVC.modalPresentationStyle = .fullScreen
        self.present(arVC, animated: true)
        
    }
    
}
