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

    @State private var editorHeight: CGFloat = UIConstants.MessagingBar.baseHeight
    
    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        // Dynamic spacing ensures text view is centered when no reaction buttons are showing
        HStack(spacing: !isFocused ? UIConstants.MessagingBar.iconSpacing : 0) {
            ZStack(alignment: .leading) {
                textView
            }

            ZStack(alignment: .trailing) {
                if !isFocused {
                    HStack(spacing: UIConstants.MessagingBar.iconSpacing) {
                        likeButton
                        shareButton
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            // Z-Stack frame to ensure smooth animations for reaction buttons
            .frame(
                width: !isFocused ? UIConstants.MessagingBar.reactionsWidth : 0,
                height: UIConstants.MessagingBar.baseHeight,
                alignment: .trailing
            )
        }
        .padding(.horizontal, UIConstants.MessagingBar.outerPadding)
        .contentShape(Rectangle()) // absorb taps in message bar so they don't hit the video
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .animation(.easeOut(duration: 0.2), value: hasText)
        .animation(.easeOut(duration: 0.2), value: editorHeight)
    }
    
    var textView: some View {
        GrowingTextView(
            text: $text,
            isFirstResponder: $isFocused,
            minHeight: UIConstants.MessagingBar.baseHeight,
            maxHeight: UIConstants.MessagingBar.maxHeight,
            onHeightChange: { editorHeight = $0 },
            onFocusChange: { focused in
                DispatchQueue.main.async {
                    onFocusChange(focused)
                }
            }
        )
        .frame(height: max(UIConstants.MessagingBar.baseHeight, editorHeight))
        .background(isFocused ? .white.opacity(0.1) : .black.opacity(0.6))
        .overlay(alignment: .leading) {
            if text.isEmpty {
                placeholder
            }
        }
        .overlay(alignment: .trailing) {
            sendMessageButton
        }
        .overlay(RoundedRectangle(cornerRadius: UIConstants.MessagingBar.cornerRadius).stroke(.white, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.MessagingBar.cornerRadius))
        .padding(.horizontal, UIConstants.MessagingBar.paddingH)
        .accessibilityLabel("Message input")
    }
    
    var placeholder: some View {
        Text("Send Message")
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, UIConstants.MessagingBar.placeholderPaddingH)
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
                .frame(width: UIConstants.MessagingBar.sendButtonIconSize, height: editorHeight - 10)
                .background(Color.blue.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: UIConstants.MessagingBar.cornerRadius))
                .offset(x: -UIConstants.MessagingBar.sendButtonPadding)
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
                .frame(width: UIConstants.MessagingBar.reactionsIconSize, height: UIConstants.MessagingBar.reactionsIconSize)
                .foregroundColor(isLiked ? .red : .white)
                .scaleEffect(isLiked ? 1.2 : 1.0)
                .padding(UIConstants.MessagingBar.reactionsIconPadding)
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isLiked)
        }
    }
    
    var shareButton: some View {
        Button { /* TODO: share action */ } label: {
            Image(systemName: "paperplane")
                .resizable()
                .scaledToFit()
                .frame(width: UIConstants.MessagingBar.reactionsIconSize, height: UIConstants.MessagingBar.reactionsIconSize)
                .foregroundColor(.white)
                .padding(UIConstants.MessagingBar.reactionsIconPadding)
        }
        .accessibilityLabel("Share reel")
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
                top: UIConstants.MessagingBar.textViewInsetV,
                left: UIConstants.MessagingBar.placeholderPaddingH,
                bottom: UIConstants.MessagingBar.textViewInsetV,
                right: UIConstants.MessagingBar.sendButtonIconSize + UIConstants.MessagingBar.sendButtonPadding
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
