//
//  DocumentRuler.swift
//  SwiftyRuler_Example
//
//  Created by Fatih Balsoy on 7/17/20.
//  Copyright © 2020 Fatih Balsoy. All rights reserved.
//

import UIKit
import SwiftyRuler
import SnapKit

class DocumentRuler: UIViewController {
    
    let topRuler: Ruler = {
        let ruler = Ruler()
        ruler.longTickLength = 20
        ruler.shortTickLength = 5
        ruler.midTickLength = ruler.midLineLength(2)
        ruler.pixelAccurate = true
        ruler.direction = .horizontal
        ruler.accuracyWarnings = false
        ruler.hasLabels = false
        return ruler
    }()
    
    let leftRuler: Ruler = {
        let ruler = Ruler()
        ruler.longTickLength = 20
        ruler.shortTickLength = 5
        ruler.midTickLength = ruler.midLineLength(2)
        ruler.pixelAccurate = true
        ruler.direction = .vertical
        ruler.accuracyWarnings = false
        ruler.hasLabels = false
        return ruler
    }()
    
    let document: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.05)
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topRuler.setNeedsDisplay()
        leftRuler.setNeedsDisplay()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topRuler.backgroundColor = UIColor.label.withAlphaComponent(0.05)
        topRuler.tickColor = .label
        topRuler.labelColor = .label
        
        leftRuler.backgroundColor = UIColor.label.withAlphaComponent(0.05)
        leftRuler.tickColor = .label
        leftRuler.labelColor = .label
        
        let height = 40
        let top = 150
        
        view.addSubview(topRuler)
        topRuler.snp.makeConstraints { (make) in
            make.right.equalTo(view)
            make.top.equalTo(view).offset(top)
            make.left.equalTo(view).offset(height)
            make.height.equalTo(height)
        }
        
        view.addSubview(leftRuler)
        leftRuler.snp.makeConstraints { (make) in
            make.bottom.left.equalTo(view)
            make.top.equalTo(view).offset(top + height)
            make.width.equalTo(height)
        }
        
        view.addSubview(document)
        document.snp.makeConstraints { (make) in
            make.top.equalTo(topRuler.snp.bottom).offset(20)
            make.bottom.equalTo(view).offset(-20)
            make.left.equalTo(leftRuler.snp.right).offset(top / 2)
            make.right.equalTo(view).offset(-top / 2)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        topRuler.setNeedsDisplay()
        leftRuler.setNeedsDisplay()
    }

}

