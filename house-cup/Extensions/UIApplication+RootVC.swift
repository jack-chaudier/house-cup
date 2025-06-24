//
//  UIApplication+RootVC.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//

import UIKit

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
