//
//  InlineMessagingBar.swift
//  ReelViewer
//
//  Created by Jazz Siddiqui on 2025-12-09.
//

import SwiftUI
import UIKit

struct InlineMessagingBar: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var isLiked: Bool
    
    var onFocusChange: (Bool) -> Void = { _ in }
    var onSend: (String) -> Void = { _ in }

    @State private var editorHeight: CGFloat = Constants.baseHeight
    
    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        // Dynamic spacing ensures text view is centered when no reaction buttons are showing
        HStack(spacing: !isFocused ? Constants.iconSpacing : 0) {
            ZStack(alignment: .leading) {
                textView
            }

            ZStack(alignment: .trailing) {
                if !isFocused {
                    HStack(spacing: Constants.iconSpacing) {
                        likeButton
                        shareButton
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            // Z-Stack frame to ensure smooth animations for reaction buttons
            .frame(
                width: !isFocused ? Constants.reactionsWidth : 0,
                height: Constants.baseHeight,
                alignment: .trailing
            )
        }
        .padding(.horizontal, Constants.outerPadding)
        .contentShape(Rectangle()) // absorb taps in message bar so they don't hit the video
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .animation(.easeOut(duration: 0.2), value: hasText)
        .animation(.easeOut(duration: 0.2), value: editorHeight)
    }
    
    var textView: some View {
        GrowingTextView(
            text: $text,
            isFirstResponder: $isFocused,
            minHeight: Constants.baseHeight,
            maxHeight: Constants.maxHeight,
            onHeightChange: { editorHeight = $0 },
            onFocusChange: { focused in
                DispatchQueue.main.async {
                    isFocused = focused
                    onFocusChange(focused)
                }
            }
        )
        .frame(height: max(Constants.baseHeight, editorHeight))
        .background(isFocused ? .white.opacity(0.1) : .black.opacity(0.6))
        .overlay(alignment: .leading) {
            if text.isEmpty {
                placeholder
            }
        }
        .overlay(alignment: .trailing) {
            sendMessageButton
        }
        .overlay(RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke(.white, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .padding(.horizontal, Constants.paddingH)
        .accessibilityLabel("Message input")
    }
    
    var placeholder: some View {
        Text("Send Message")
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, Constants.placeholderPaddingH)
    }
    
    var sendMessageButton: some View {
        let visible = hasText
        return Button {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            onSend(trimmed)
            text = ""
            isFocused = false
        } label: {
            Image(systemName: "paperplane.fill")
                .foregroundColor(.white)
                .font(.title2)
                .frame(width: Constants.sendButtonIconSize, height: editorHeight - 10)
                .background(Color.blue.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                .offset(x: -Constants.sendButtonPadding)
        }
        .opacity(visible ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: visible)
        .accessibilityLabel("Send message")
    }
    
    var likeButton: some View {
        Button {
            isLiked.toggle()
        } label: {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .resizable()
                .scaledToFit()
                .frame(width: Constants.reactionsIconSize, height: Constants.reactionsIconSize)
                .foregroundColor(isLiked ? .red : .white)
                .scaleEffect(isLiked ? 1.2 : 1.0)
                .padding(Constants.reactionsIconPadding)
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isLiked)
        }
    }
    
    var shareButton: some View {
        Button { /* TODO: share action */ } label: {
            Image(systemName: "paperplane")
                .resizable()
                .scaledToFit()
                .frame(width: Constants.reactionsIconSize, height: Constants.reactionsIconSize)
                .foregroundColor(.white)
                .padding(Constants.reactionsIconPadding)
        }
        .accessibilityLabel("Share reel")
    }

    private struct Constants {
        /// Messaging bar constants
        static let paddingV: CGFloat = 5
        static let paddingH: CGFloat = 5
        
        static let lineHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight
        static var baseHeight: CGFloat { Constants.lineHeight * 1 + Constants.paddingV * 2 }
        // Cap to 5 lines of text
        static var maxHeight: CGFloat { Constants.lineHeight * 5 + Constants.paddingV * 2 }
        
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
    
    /// A UIKit-backed text view that reports its height and focus state to SwiftUI.
    private struct GrowingTextView: UIViewRepresentable {
        @Binding var text: String
        @Binding var isFirstResponder: Bool
        var minHeight: CGFloat
        var maxHeight: CGFloat
        var onHeightChange: (CGFloat) -> Void
        var onFocusChange: (Bool) -> Void

        func makeUIView(context: Context) -> UITextView {
            let textView = UITextView()
            textView.delegate = context.coordinator
            textView.backgroundColor = .clear
            textView.textColor = .white
            textView.font = UIFont.preferredFont(forTextStyle: .body)
            textView.isScrollEnabled = true
            // Adjust insets to align the first line of typed text with the placeholder
            // while ensuring the last character is to the left of the send message button
            textView.textContainerInset = UIEdgeInsets(
                top: Constants.textViewInsetV,
                left: Constants.placeholderPaddingH,
                bottom: Constants.textViewInsetV,
                right: Constants.sendButtonIconSize + Constants.sendButtonPadding
            )
            textView.textContainer.lineFragmentPadding = 0
            textView.keyboardDismissMode = .interactive
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return textView
        }
        
        @MainActor
        func updateUIView(_ uiView: UITextView, context: Context) {
            DispatchQueue.main.async {
                if uiView.text != text {
                    uiView.text = text
                }

                if isFirstResponder, !uiView.isFirstResponder {
                    uiView.becomeFirstResponder()
                } else if !isFirstResponder, uiView.isFirstResponder {
                    uiView.resignFirstResponder()
                }
                
                updateHeight(uiView)
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        private func updateHeight(_ textView: UITextView) {
            guard textView.bounds.width > 0 else { return }
            let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
            let size = textView.sizeThatFits(fittingSize)
            let clamped = min(maxHeight, max(minHeight, size.height))
            if abs(clamped - textView.bounds.height) > 0.5 {
                onHeightChange(clamped)
            }
            textView.isScrollEnabled = size.height > maxHeight
        }

        class Coordinator: NSObject, UITextViewDelegate {
            var parent: GrowingTextView

            init(parent: GrowingTextView) {
                self.parent = parent
            }

            func textViewDidChange(_ textView: UITextView) {
                parent.text = textView.text
                parent.updateHeight(textView)
            }

            func textViewDidBeginEditing(_ textView: UITextView) {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.isFirstResponder = true
                    self?.parent.onFocusChange(true)
                }
            }

            func textViewDidEndEditing(_ textView: UITextView) {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.isFirstResponder = false
                    self?.parent.onFocusChange(false)
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
