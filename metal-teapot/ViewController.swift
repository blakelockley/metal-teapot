//
//  ViewController.swift
//  metal-teapot
//
//  Created by Blake Lockley on 11/12/18.
//  Copyright © 2018 Blake Lockley. All rights reserved.
//

import Metal
import MetalKit

class ViewController: NSViewController {
    
    var renderer: Renderer!
    
    var mtkView: MTKView {
        return self.view as! MTKView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device = MTLCreateSystemDefaultDevice()!
        renderer = Renderer(device: device)
        
        mtkView.device = device
        mtkView.delegate = renderer
        mtkView.colorPixelFormat = .bgra8Unorm
    }

}
