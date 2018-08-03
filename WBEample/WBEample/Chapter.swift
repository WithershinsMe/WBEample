//
//  Chapter.swift
//  WBEample
//
//  Created by GK on 2018/8/3.
//  Copyright © 2018年 com.gk. All rights reserved.
//

import Foundation
import AVKit

struct Chapter {
    let time: CMTime
    let title: String
    let image: UIImage
}


extension UIView{
    
    var screenshot: UIImage{
        UIGraphicsBeginImageContext(self.bounds.size);
        let context = UIGraphicsGetCurrentContext();
        self.layer.render(in: context!)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return screenShot!
    }
}
