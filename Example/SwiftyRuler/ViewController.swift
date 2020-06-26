//
//  ViewController.swift
//  SwiftyRuler
//
//  Created by Fatih Balsoy on 06/21/2020.
//  Copyright (c) 2020 Fatih Balsoy. All rights reserved.
//

import UIKit
import SwiftyRuler
import SnapKit

class ViewController: UIViewController, RulerDelegate {
    
    let ruler: Ruler = {
        let ruler = Ruler()
        ruler.longTickLength = 30
        ruler.shortTickLength = 10
        ruler.midTickLength = ruler.midLineLength(2)
        ruler.pixelAccurate = true
        ruler.doubleUnits = true
        ruler.direction = .vertical
        return ruler
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ruler.delegate = self
        
        ruler.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        ruler.tickColor = .black
        ruler.labelColor = .black
        
        view.addSubview(ruler)
        ruler.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(view)
            make.centerX.equalTo(view)
            make.width.equalTo(200)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        ruler.setNeedsDisplay()
    }

}

