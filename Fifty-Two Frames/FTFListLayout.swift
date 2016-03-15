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
        let width = (UIScreen.mainScreen().bounds.size.width - CGFloat(28.0)) / numberOfColumns
        self.itemSize = CGSizeMake(width, width);
        self.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6);
        self.minimumInteritemSpacing = 8.0;
        self.minimumLineSpacing = 8.0;
    }
    
    override func prepareLayout() {
        let width = (UIScreen.mainScreen().bounds.size.width - CGFloat(28.0)) / numberOfColumns
        self.itemSize = CGSizeMake(width, width);
        self.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6);
        self.minimumInteritemSpacing = 8.0;
        self.minimumLineSpacing = 8.0;
    }
}
