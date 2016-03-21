//
//  FTFListLayout.swift
//  FiftyTwoFrames
//
//  Created by Josh Siegel on 3/12/16.
//  Copyright © 2016 Gershy Lev. All rights reserved.
//

import UIKit

@objc class FTFListLayout: UICollectionViewFlowLayout {
    var numberOfColumns: CGFloat = 1.0
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()

    }
    
    func setup() {
        let width = (UIScreen.mainScreen().bounds.size.width) / numberOfColumns
        self.itemSize = CGSizeMake(width, width / 1.32)
    }
    
    override func prepareLayout() {
        setup()
    }
}