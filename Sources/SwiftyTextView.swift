//
//  SwiftyTextView.swift
//  SwiftyTextView
//
//  Created by SwiftyKit on 07/06/2018.
//  Copyright © 2018 com.swiftykit.SwiftyTextView. All rights reserved.
//

import UIKit


@IBDesignable
public class SwiftyTextView: UITextView {

    // MARK: - IBInspectables
    @IBInspectable open var placeholderColor: UIColor = UIColor.lightGray {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var placeholder: String = "Please input text..." {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var minNumberOfWords: Int = 0 {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var maxNumberOfWords: Int = 30 {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var showTextCountView: Bool = false {
        didSet { setNeedsLayout() }
    }

    // MARK: - Layers
    private var placeHolderTextLayer: CATextLayer?
    private var countdownTextLayer: CATextLayer?

    // MARK: - Delegate
    public weak var textDelegate: SwiftyTextViewDelegate?

    // MARK: - Override text
    public override var text: String? {
        get { return super.text }
        set {
            super.text = newValue ?? ""   // forward safely to UITextView
            updatePlaceholder()
            updateCountdown()
            NotificationCenter.default.post(
                name: UITextView.textDidChangeNotification,
                object: self
            )
        }
    }

    // MARK: - Init
    override open func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        updatePlaceholder()
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }

    // MARK: - Layout
    override open func layoutSubviews() {
        super.layoutSubviews()

        let defaultFont = font ?? UIFont.systemFont(ofSize: 17.0)

        // Placeholder layer
        if placeHolderTextLayer == nil {
            let layer = CATextLayer()
            layer.contentsScale = UIScreen.main.scale
            layer.alignmentMode = .left
            layer.backgroundColor = UIColor.clear.cgColor
            layer.foregroundColor = placeholderColor.cgColor
            layer.font = defaultFont
            layer.fontSize = defaultFont.pointSize
            layer.string = placeholder
            layer.frame = CGRect(origin: CGPoint(x: 5, y: bounds.minY + 8), size: bounds.size)
            self.layer.insertSublayer(layer, at: 0)
            placeHolderTextLayer = layer
        }

        // Countdown layer
        if showTextCountView {
            if countdownTextLayer == nil {
                let layer = CATextLayer()
                layer.contentsScale = UIScreen.main.scale
                layer.alignmentMode = .right
                layer.backgroundColor = UIColor.clear.cgColor
                layer.foregroundColor = placeholderColor.cgColor
                layer.font = defaultFont
                layer.fontSize = defaultFont.pointSize

                let tempLabel = UILabel()
                tempLabel.text = "\(maxNumberOfWords)/\(maxNumberOfWords)"
                tempLabel.font = font
                tempLabel.sizeToFit()
                layer.frame = tempLabel.frame
                layer.string = "\(minNumberOfWords)/\(maxNumberOfWords)"
                self.layer.addSublayer(layer)
                countdownTextLayer = layer
            }

            if let countdown = countdownTextLayer {
                countdown.frame.origin = CGPoint(
                    x: bounds.size.width - countdown.bounds.size.width,
                    y: bounds.size.height - countdown.bounds.size.height + contentOffset.y
                )
            }
        }

        updatePlaceholder()
        updateCountdown()
    }

    // MARK: - Helpers
    private func updatePlaceholder() {
        placeHolderTextLayer?.isHidden = !(text?.isEmpty ?? true)
    }

    private func updateCountdown() {
        if showTextCountView {
            countdownTextLayer?.string = "\(text?.count ?? 0)/\(maxNumberOfWords)"
        }
    }
}

// MARK: - UITextViewDelegate
extension SwiftyTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        updatePlaceholder()
        updateCountdown()
        textDelegate?.textViewDidChange?(textView)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        updatePlaceholder()
        textDelegate?.textViewDidChangeSelection?(textView)
    }

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText replacement: String) -> Bool {
        let oldText = textView.text as NSString
        let newText = oldText.replacingCharacters(in: range, with: replacement)

        if let delegate = textDelegate,
           delegate.responds(to: #selector(SwiftyTextViewDelegate.textView(_:shouldChangeTextIn:replacementText:))) {
            if !delegate.textView!(textView, shouldChangeTextIn: range, replacementText: replacement) {
                return false
            }
        }

        if showTextCountView, newText.count > maxNumberOfWords {
            return false
        }
        return true
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        textDelegate?.textViewDidBeginEditing?(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        textDelegate?.textViewDidEndEditing?(textView)
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return textDelegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return textDelegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textView(_ textView: UITextView,
                         shouldInteractWith URL: URL,
                         in characterRange: NSRange) -> Bool {
        return textDelegate?.textView?(textView, shouldInteractWith: URL, in: characterRange) ?? true
    }
}

//MARK: -
//MARK: delegate


@objc public protocol SwiftyTextViewDelegate: NSObjectProtocol {
    @objc optional func textViewDidChange(_ textView: UITextView)
    @objc optional func textViewDidChangeSelection(_ textView: UITextView)
    @objc optional func textViewDidBeginEditing(_ textView: UITextView)
    @objc optional func textViewDidEndEditing(_ textView: UITextView)
    @objc optional func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    @objc optional func textViewShouldEndEditing(_ textView: UITextView) -> Bool
    @objc optional func textView(_ textView: UITextView,
                                 shouldChangeTextIn range: NSRange,
                                 replacementText text: String) -> Bool
    @objc optional func textView(_ textView: UITextView,
                                 shouldInteractWith URL: URL,
                                 in characterRange: NSRange) -> Bool
}

