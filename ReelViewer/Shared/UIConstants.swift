//
//  UIConstants.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-10.
//

import SwiftUI
import UIKit

enum UIConstants {
    enum MessagingBar {
        /// Messaging bar constants
        static let paddingV: CGFloat = 5
        static let paddingH: CGFloat = 5
        
        static let lineHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight
        static var baseHeight: CGFloat { lineHeight * 1 + paddingV * 2 }
        // Cap to 5 lines of text
        static var maxHeight: CGFloat { lineHeight * 5 + paddingV * 2 }
        
        // Distance of swipe in text box before keyboard is dismissed
        static let scrollOffsetToDismiss: CGFloat = 50
        
        static let cornerRadius: CGFloat = 30
        
        static let outerPadding: CGFloat = 12
        
        /// Send button constants
        static let sendButtonIconSize: CGFloat = 50
        static let sendButtonPadding: CGFloat = 5
        
        /// Align placeholder to UITextView inset
        static let placeholderPaddingH: CGFloat = 17
        static let textViewInsetV: CGFloat = 12
        
        /// Reaction button constants
        static let iconSpacing: CGFloat = 20
        static var reactionsIconSize: CGFloat = 25
        static var reactionsIconPadding: CGFloat = 3
        static var reactionsWidth: CGFloat {
            reactionsIconSize * 2 + iconSpacing
        }
    }
}
