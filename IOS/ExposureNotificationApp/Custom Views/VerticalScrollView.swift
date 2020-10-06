/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A vertical scroll view.
*/

import UIKit

class VerticalScollView: UIScrollView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NSLayoutConstraint.activate([
            contentLayoutGuide.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor)
        ])
    }
}
