import SwiftUI
import UIKit

// 代码编辑器：UITextView 封装，带语法高亮与中文输入法保护

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = SyntaxHighlighter.font
        tv.textColor = UIColor(Theme.textPrimary)
        tv.autocapitalizationType = .none
        tv.autocorrectionType = .no
        tv.spellCheckingType = .no
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.smartInsertDeleteType = .no
        tv.keyboardType = .asciiCapable
        tv.tintColor = UIColor(Theme.accent)
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 80, right: 12)
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = .interactive
        tv.indicatorStyle = .white
        tv.delegate = context.coordinator
        tv.typingAttributes = [
            .font: SyntaxHighlighter.font,
            .foregroundColor: UIColor(Theme.textPrimary),
        ]
        tv.attributedText = SyntaxHighlighter.highlight(text)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text {
            let ns = text as NSString
            let sel = tv.selectedRange
            tv.attributedText = SyntaxHighlighter.highlight(text)
            tv.selectedRange = NSRange(location: min(sel.location, ns.length), length: 0)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditorView
        private var work: DispatchWorkItem?

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textViewDidChange(_ tv: UITextView) {
            parent.text = tv.text
            work?.cancel()
            // 输入法组合期间不重排，避免打断候选词
            guard tv.markedTextRange == nil else { return }
            let w = DispatchWorkItem { [weak tv] in
                guard let tv else { return }
                let source = tv.text
                let highlighted = SyntaxHighlighter.highlight(source)
                DispatchQueue.main.async {
                    guard tv.text == source else { return }
                    let sel = tv.selectedRange
                    tv.attributedText = highlighted
                    tv.selectedRange = sel
                }
            }
            work = w
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.12, execute: w)
        }
    }
}
