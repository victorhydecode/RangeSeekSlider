//
//  RangeSeekSlider.swift
//  RangeSeekSlider
//
//  Created by Keisuke Shoji on 2017/03/09.
//
//

import UIKit

@IBDesignable open class RangeSeekSlider: UIControl {

    // MARK: - initializers

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    public required override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public convenience init(frame: CGRect = .zero, completion: ((RangeSeekSlider) -> Void)? = nil) {
        self.init(frame: frame)
        completion?(self)
    }


    // MARK: - open stored properties

    open weak var delegate: RangeSeekSliderDelegate?

    /// Enables the shadows under the slider handles. true = shadows will be shown. false = shadows will be hidden. Default is false.
    @IBInspectable open var enableHandleShadows: Bool = false {
        didSet {
            if enableHandleShadows {
                applySketchShadow(leftHandle, alpha: 0.2, blur: 5)
                applySketchShadow(rightHandle, alpha: 0.2, blur: 5)
            } else {
                applySketchShadow(leftHandle, alpha: 0)
                applySketchShadow(rightHandle, alpha: 0)
            }
        }
    }

    /// Enables the shadows and corner raddius under the labels. true = will be shown. false = will be hidden. Default is false.
    @IBInspectable open var enableLabelsShadowsAndCorners: Bool = false {
        didSet {
            if enableLabelsShadowsAndCorners {
                minLabel.cornerRadius = minLabel.frame.height / 2
                maxLabel.cornerRadius = maxLabel.frame.height / 2
                applySketchShadow(minLabel, alpha: 0.2, y: 0, blur: 3)
                applySketchShadow(maxLabel, alpha: 0.2, y: 0, blur: 3)
                minLabel.backgroundColor = UIColor.white.cgColor
                maxLabel.backgroundColor = UIColor.white.cgColor
            } else {
                minLabel.cornerRadius = 0
                maxLabel.cornerRadius = 0
                applySketchShadow(minLabel, alpha: 0)
                applySketchShadow(maxLabel, alpha: 0)
                minLabel.backgroundColor = UIColor.clear.cgColor
                maxLabel.backgroundColor = UIColor.clear.cgColor
            }
        }
    }

    /// Labels vertical padding
    @IBInspectable open var labelsVerticalPadding: CGFloat = 4.0 {
        didSet {
            refresh()
        }
    }

    /// Labels horizontal padding
    @IBInspectable open var labelsHorizontalPadding: CGFloat = 8.0 {
        didSet {
            refresh()
        }
    }


    /// The minimum possible value to select in the range
    @IBInspectable open var minValue: CGFloat = 0.0 {
        didSet {
            refresh()
        }
    }

    /// The maximum possible value to select in the range
    @IBInspectable open var maxValue: CGFloat = 100.0 {
        didSet {
            refresh()
        }
    }

    /// The preselected minumum value
    /// (note: This should be less than the selectedMaxValue)
    @IBInspectable open var selectedMinValue: CGFloat = 0.0 {
        didSet {
            if selectedMinValue < minValue {
                selectedMinValue = minValue
            }
        }
    }

    /// The preselected maximum value
    /// (note: This should be greater than the selectedMinValue)
    @IBInspectable open var selectedMaxValue: CGFloat = 100.0 {
        didSet {
            if selectedMaxValue > maxValue {
                selectedMaxValue = maxValue
            }
        }
    }

    /// The font of the minimum value text label. If not set, the default is system font size 12.0.
    open var minLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0) {
        didSet {
            minLabel.font = minLabelFont as CFTypeRef
            minLabel.fontSize = minLabelFont.pointSize
        }
    }

    /// The font of the maximum value text label. If not set, the default is system font size 12.0.
    open var maxLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0) {
        didSet {
            maxLabel.font = maxLabelFont as CFTypeRef
            maxLabel.fontSize = maxLabelFont.pointSize
        }
    }

    /// Each handle in the slider has a label above it showing the current selected value. By default, this is displayed as a decimal format.
    /// You can update this default here by updating properties of NumberFormatter. For example, you could supply a currency style, or a prefix or suffix.
    open var numberFormatter: NumberFormatter = {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Hides the labels above the slider controls. true = labels will be hidden. false = labels will be shown. Default is false.
    @IBInspectable open var hideLabels: Bool = false {
        didSet {
            minLabel.isHidden = hideLabels
            maxLabel.isHidden = hideLabels
        }
    }

    /// fixes the labels above the slider controls. true: labels will be fixed to both ends. false: labels will move with the handles. Default is false.
    @IBInspectable open var labelsFixed: Bool = false

    /// The minimum distance the two selected slider values must be apart. Default is 0.
    @IBInspectable open var minDistance: CGFloat = 0.0 {
        didSet {
            if minDistance < 0.0 {
                minDistance = 0.0
            }
        }
    }

    /// The maximum distance the two selected slider values must be apart. Default is CGFloat.greatestFiniteMagnitude.
    @IBInspectable open var maxDistance: CGFloat = .greatestFiniteMagnitude {
        didSet {
            if maxDistance < 0.0 {
                maxDistance = .greatestFiniteMagnitude
            }
        }
    }

    /// The color of the minimum value text label. If not set, the default is the tintColor.
    @IBInspectable open var minLabelColor: UIColor?

    /// The color of the maximum value text label. If not set, the default is the tintColor.
    @IBInspectable open var maxLabelColor: UIColor?

    /// Handle slider with custom color, you can set custom color for your handle
    @IBInspectable open var handleColor: UIColor?

    /// Handle slider with custom border color, you can set custom border color for your handle
    @IBInspectable open var handleBorderColor: UIColor?

    /// Set slider line tint color between handles
    @IBInspectable open var colorBetweenHandles: UIColor?

    /// The color of the entire slider when the handle is set to the minimum value and the maximum value. Default is nil.
    @IBInspectable open var initialColor: UIColor?

    /// If true, the control will mimic a normal slider and have only one handle rather than a range.
    /// In this case, the selectedMinValue will be not functional anymore. Use selectedMaxValue instead to determine the value the user has selected.
    @IBInspectable open var disableRange: Bool = false {
        didSet {
            leftHandle.isHidden = disableRange
            minLabel.isHidden = disableRange
        }
    }

    /// If true the control will snap to point at each step between minValue and maxValue. Default is false.
    @IBInspectable open var enableStep: Bool = false

    /// The step value, this control the value of each step. If not set the default is 0.0.
    /// (note: this is ignored if <= 0.0)
    @IBInspectable open var step: CGFloat = 0.0

    /// Handle slider with custom image, you can set custom image for your handle
    @IBInspectable open var handleImage: UIImage? {
        didSet {
            guard let image = handleImage else {
                return
            }

            var handleFrame = CGRect.zero
            handleFrame.size = image.size

            leftHandle.frame = handleFrame
            leftHandle.contents = image.cgImage

            rightHandle.frame = handleFrame
            rightHandle.contents = image.cgImage
        }
    }

    /// Handle diameter (default 16.0)
    @IBInspectable open var handleDiameter: CGFloat = 16.0 {
        didSet {
            leftHandle.cornerRadius = handleDiameter / 2.0
            rightHandle.cornerRadius = handleDiameter / 2.0
            leftHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
            rightHandle.frame = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        }
    }

    /// Selected handle diameter multiplier (default 1.7)
    @IBInspectable open var selectedHandleDiameterMultiplier: CGFloat = 1.7

    /// Set the slider line height (default 1.0)
    @IBInspectable open var lineHeight: CGFloat = 1.0 {
        didSet {
            updateLineHeight()
        }
    }

    /// Set the slider line border (default 1.0)
    @IBInspectable open var lineBorder: CGFloat = 1.0 {
        didSet {
            updateLineHeight()
        }
    }

    /// The color of the line border. If not set, the default is the clear.
    @IBInspectable open var lineBorderColor: UIColor = UIColor.clear

    /// Handle border width (default 0.0)
    @IBInspectable open var handleBorderWidth: CGFloat = 0.0 {
        didSet {
            leftHandle.borderWidth = handleBorderWidth
            rightHandle.borderWidth = handleBorderWidth
        }
    }

    /// Set padding between label and handle (default 8.0)
    @IBInspectable open var labelPadding: CGFloat = 8.0 {
        didSet {
            updateLabelPositions()
        }
    }

    /// The label displayed in accessibility mode for minimum value handler. If not set, the default is empty String.
    @IBInspectable open var minLabelAccessibilityLabel: String?

    /// The label displayed in accessibility mode for maximum value handler. If not set, the default is empty String.
    @IBInspectable open var maxLabelAccessibilityLabel: String?

    /// The brief description displayed in accessibility mode for minimum value handler. If not set, the default is empty String.
    @IBInspectable open var minLabelAccessibilityHint: String?

    /// The brief description displayed in accessibility mode for maximum value handler. If not set, the default is empty String.
    @IBInspectable open var maxLabelAccessibilityHint: String?


    // MARK: - private stored properties

    private enum HandleTracking { case none, left, right }
    private var handleTracking: HandleTracking = .none

    private let sliderLine: CALayer = CALayer()
    private let sliderLineBetweenHandles: CALayer = CALayer()

    private let leftHandle: CALayer = CALayer()
    private let rightHandle: CALayer = CALayer()

    fileprivate let minLabel: LCTextLayer = LCTextLayer()
    fileprivate let maxLabel: LCTextLayer = LCTextLayer()

    private var minLabelTextSize: CGSize = .zero
    private var maxLabelTextSize: CGSize = .zero

    // UIFeedbackGenerator
    private var previousStepMinValue: CGFloat?
    private var previousStepMaxValue: CGFloat?

    // strong reference needed for UIAccessibilityContainer
    // see http://stackoverflow.com/questions/13462046/custom-uiview-not-showing-accessibility-on-voice-over
    private var accessibleElements: [UIAccessibilityElement] = []


    // MARK: - private computed properties

    private var leftHandleAccessibilityElement: UIAccessibilityElement {
        let element: RangeSeekSliderLeftElement = RangeSeekSliderLeftElement(accessibilityContainer: self)
        element.isAccessibilityElement = true
        element.accessibilityLabel = minLabelAccessibilityLabel
        element.accessibilityHint = minLabelAccessibilityHint
        element.accessibilityValue = minLabel.string as? String
        element.accessibilityFrame = convert(leftHandle.frame, to: nil)
        element.accessibilityTraits = UIAccessibilityTraitAdjustable
        return element
    }

    private var rightHandleAccessibilityElement: UIAccessibilityElement {
        let element: RangeSeekSliderRightElement = RangeSeekSliderRightElement(accessibilityContainer: self)
        element.isAccessibilityElement = true
        element.accessibilityLabel = maxLabelAccessibilityLabel
        element.accessibilityHint = maxLabelAccessibilityHint
        element.accessibilityValue = maxLabel.string as? String
        element.accessibilityFrame = convert(rightHandle.frame, to: nil)
        element.accessibilityTraits = UIAccessibilityTraitAdjustable
        return element
    }


    // MARK: - UIView

    open override func layoutSubviews() {
        super.layoutSubviews()

        if handleTracking == .none {
            updateLineHeight()
            updateLabelValues()
            updateColors()
            updateHandlePositions()
            updateLabelPositions()
        }
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 65.0)
    }


    // MARK: - UIControl

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchLocation: CGPoint = touch.location(in: self)
        let insetExpansion: CGFloat = -30.0
        let isTouchingLeftHandle: Bool = leftHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)
        let isTouchingRightHandle: Bool = rightHandle.frame.insetBy(dx: insetExpansion, dy: insetExpansion).contains(touchLocation)

        guard isTouchingLeftHandle || isTouchingRightHandle else { return false }


        // the touch was inside one of the handles so we're definitely going to start movign one of them. But the handles might be quite close to each other, so now we need to find out which handle the touch was closest too, and activate that one.
        let distanceFromLeftHandle: CGFloat = touchLocation.distance(to: leftHandle.frame.center)
        let distanceFromRightHandle: CGFloat = touchLocation.distance(to: rightHandle.frame.center)

        if distanceFromLeftHandle < distanceFromRightHandle && !disableRange {
            handleTracking = .left
        } else if selectedMaxValue == maxValue && leftHandle.frame.midX == rightHandle.frame.midX {
            handleTracking = .left
        } else {
            handleTracking = .right
        }
        let handle: CALayer = (handleTracking == .left) ? leftHandle : rightHandle
        animate(handle: handle, selected: true)

        delegate?.didStartTouches(in: self)

        return true
    }

    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard handleTracking != .none else { return false }

        let location: CGPoint = touch.location(in: self)

        // find out the percentage along the line we are in x coordinate terms (subtracting half the frames width to account for moving the middle of the handle, not the left hand side)
        let percentage: CGFloat = (location.x - sliderLine.frame.minX - handleDiameter / 2.0) / (sliderLine.frame.maxX - sliderLine.frame.minX)

        // multiply that percentage by self.maxValue to get the new selected minimum value
        let selectedValue: CGFloat = percentage * (maxValue - minValue) + minValue

        switch handleTracking {
        case .left:
            selectedMinValue = min(selectedValue, selectedMaxValue)
        case .right:
            // don't let the dots cross over, (unless range is disabled, in which case just dont let the dot fall off the end of the screen)
            if disableRange && selectedValue >= minValue {
                selectedMaxValue = selectedValue
            } else {
                selectedMaxValue = max(selectedValue, selectedMinValue)
            }
        case .none:
            // no need to refresh the view because it is done as a side-effect of setting the property
            break
        }

        refresh()

        return true
    }

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        let handle: CALayer = (handleTracking == .left) ? leftHandle : rightHandle
        animate(handle: handle, selected: false)
        handleTracking = .none

        delegate?.didEndTouches(in: self)
    }


    // MARK: - UIAccessibility

    open override func accessibilityElementCount() -> Int {
        return accessibleElements.count
    }

    open override func accessibilityElement(at index: Int) -> Any? {
        return accessibleElements[index]
    }

    open override func index(ofAccessibilityElement element: Any) -> Int {
        guard let element = element as? UIAccessibilityElement else { return 0 }
        return accessibleElements.index(of: element) ?? 0
    }


    // MARK: - open methods

    /// When subclassing **RangeSeekSlider** and setting each item in **setupStyle()**, the design is reflected in Interface Builder as well.
    open func setupStyle() {}


    // MARK: - private methods

    private func setup() {
        isAccessibilityElement = false
        accessibleElements = [leftHandleAccessibilityElement, rightHandleAccessibilityElement]

        // draw the slider line
        layer.addSublayer(sliderLine)

        // draw the track distline
        layer.addSublayer(sliderLineBetweenHandles)

        // draw the minimum slider handle
        leftHandle.cornerRadius = handleDiameter / 2.0
        leftHandle.borderWidth = handleBorderWidth
        layer.addSublayer(leftHandle)

        // draw the maximum slider handle
        rightHandle.cornerRadius = handleDiameter / 2.0
        rightHandle.borderWidth = handleBorderWidth
        layer.addSublayer(rightHandle)

        let handleFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: handleDiameter, height: handleDiameter)
        leftHandle.frame = handleFrame
        rightHandle.frame = handleFrame

        // draw the text labels
        let labelFontSize: CGFloat = 12.0
        let labelFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: 75.0, height: 14.0)

        minLabelFont = UIFont.systemFont(ofSize: labelFontSize)
        minLabel.alignmentMode = kCAAlignmentCenter
        minLabel.frame = labelFrame
        minLabel.contentsScale = UIScreen.main.scale
        layer.addSublayer(minLabel)

        maxLabelFont = UIFont.systemFont(ofSize: labelFontSize)
        maxLabel.alignmentMode = kCAAlignmentCenter
        maxLabel.frame = labelFrame
        maxLabel.contentsScale = UIScreen.main.scale
        layer.addSublayer(maxLabel)

        setupStyle()

        refresh()
    }

    private func percentageAlongLine(for value: CGFloat) -> CGFloat {
        // stops divide by zero errors where maxMinDif would be zero. If the min and max are the same the percentage has no point.
        guard minValue < maxValue else { return 0.0 }

        // get the difference between the maximum and minimum values (e.g if max was 100, and min was 50, difference is 50)
        let maxMinDif: CGFloat = maxValue - minValue

        // now subtract value from the minValue (e.g if value is 75, then 75-50 = 25)
        let valueSubtracted: CGFloat = value - minValue

        // now divide valueSubtracted by maxMinDif to get the percentage (e.g 25/50 = 0.5)
        return valueSubtracted / maxMinDif
    }

    private func xPositionAlongLine(for value: CGFloat) -> CGFloat {
        // first get the percentage along the line for the value
        let percentage: CGFloat = percentageAlongLine(for: value)

        // get the difference between the maximum and minimum coordinate position x values (e.g if max was x = 310, and min was x=10, difference is 300)
        let maxMinDif: CGFloat = sliderLine.frame.maxX - sliderLine.frame.minX

        // now multiply the percentage by the minMaxDif to see how far along the line the point should be, and add it onto the minimum x position.
        let offset: CGFloat = percentage * maxMinDif

        return sliderLine.frame.minX + offset
    }

    private func updateLineHeight() {
        let barSidePadding: CGFloat = 16.0
        let yMiddle: CGFloat = frame.height / 2.0
        let lineLeftSide: CGPoint = CGPoint(x: barSidePadding, y: yMiddle)
        let lineRightSide: CGPoint = CGPoint(x: frame.width - barSidePadding,
                                             y: yMiddle)
        sliderLine.frame = CGRect(x: lineLeftSide.x,
                                  y: lineLeftSide.y,
                                  width: lineRightSide.x - lineLeftSide.x,
                                  height: lineHeight)
        sliderLine.cornerRadius = lineHeight / 2.0
        sliderLine.borderWidth = lineBorder
        sliderLineBetweenHandles.cornerRadius = sliderLine.cornerRadius
    }

    private func updateLabelValues() {
        minLabel.isHidden = hideLabels || disableRange
        maxLabel.isHidden = hideLabels

        if let replacedString = delegate?.rangeSeekSlider(self, stringForMinValue: selectedMinValue) {
            minLabel.string = replacedString
        } else {
            minLabel.string = numberFormatter.string(from: selectedMinValue as NSNumber)
        }

        if let replacedString = delegate?.rangeSeekSlider(self, stringForMaxValue: selectedMaxValue) {
            maxLabel.string = replacedString
        } else {
            maxLabel.string = numberFormatter.string(from: selectedMaxValue as NSNumber)
        }

        if let nsstring = minLabel.string as? NSString {
            var size = nsstring.size(withAttributes: [.font: minLabelFont])
            if size.width < size.height {
                size = CGSize(width: size.height, height: size.height)
            }
            minLabelTextSize = CGSize(width: size.width + 2 * labelsHorizontalPadding, height: size.height + 2 * labelsVerticalPadding)
        }

        if let nsstring = maxLabel.string as? NSString {
            var size = nsstring.size(withAttributes: [.font: maxLabelFont])
            if size.width < size.height {
                size = CGSize(width: size.height, height: size.height)
            }
            maxLabelTextSize = CGSize(width: size.width + 2 * labelsHorizontalPadding, height: size.height + 2 * labelsVerticalPadding)
        }
    }

    private func updateColors() {
        let isInitial: Bool = selectedMinValue == minValue && selectedMaxValue == maxValue
        if let initialColor = initialColor?.cgColor, isInitial {
            minLabel.foregroundColor = initialColor
            maxLabel.foregroundColor = initialColor
            sliderLineBetweenHandles.backgroundColor = initialColor
            sliderLine.backgroundColor = initialColor

            let color: CGColor = (handleImage == nil) ? initialColor : UIColor.clear.cgColor
            leftHandle.backgroundColor = color
            leftHandle.borderColor = color
            rightHandle.backgroundColor = color
            rightHandle.borderColor = color
        } else {
            let tintCGColor: CGColor = tintColor.cgColor
            minLabel.foregroundColor = minLabelColor?.cgColor ?? tintCGColor
            maxLabel.foregroundColor = maxLabelColor?.cgColor ?? tintCGColor
            sliderLineBetweenHandles.backgroundColor = colorBetweenHandles?.cgColor ?? tintCGColor
            sliderLine.backgroundColor = tintCGColor
            sliderLine.borderColor = lineBorderColor.cgColor

            let color: CGColor
            if let _ = handleImage {
                color = UIColor.clear.cgColor
            } else {
                color = handleColor?.cgColor ?? tintCGColor
            }
            leftHandle.backgroundColor = color
            leftHandle.borderColor = handleBorderColor.map { $0.cgColor }
            rightHandle.backgroundColor = color
            rightHandle.borderColor = handleBorderColor.map { $0.cgColor }
        }
    }

    private func updateAccessibilityElements() {
        accessibleElements = [leftHandleAccessibilityElement, rightHandleAccessibilityElement]
    }

    private func updateHandlePositions() {
        leftHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMinValue),
                                      y: sliderLine.frame.midY)

        rightHandle.position = CGPoint(x: xPositionAlongLine(for: selectedMaxValue),
                                       y: sliderLine.frame.midY)

        // positioning for the dist slider line
        sliderLineBetweenHandles.frame = CGRect(x: leftHandle.position.x,
                                                y: sliderLine.frame.minY,
                                                width: rightHandle.position.x - leftHandle.position.x,
                                                height: lineHeight)
    }

    private func updateLabelPositions() {
        // the center points for the labels are X = the same x position as the relevant handle. Y = the y position of the handle minus half the height of the text label, minus some padding.

        minLabel.frame.size = minLabelTextSize
        maxLabel.frame.size = maxLabelTextSize

        if enableLabelsShadowsAndCorners {
            minLabel.cornerRadius = minLabel.frame.height / 2
            maxLabel.cornerRadius = maxLabel.frame.height / 2
        }

        if labelsFixed {
            updateFixedLabelPositions()
            return
        }

        let minSpacingBetweenLabels: CGFloat = 8.0

        let newMinLabelCenter: CGPoint = CGPoint(x: leftHandle.frame.midX,
                                                 y: leftHandle.frame.minY - (minLabelTextSize.height / 2.0) - labelPadding)

        let newMaxLabelCenter: CGPoint = CGPoint(x: rightHandle.frame.midX,
                                                 y: rightHandle.frame.minY - (maxLabelTextSize.height / 2.0) - labelPadding)

        let newLeftMostXInMaxLabel: CGFloat = newMaxLabelCenter.x - maxLabelTextSize.width / 2.0
        let newRightMostXInMinLabel: CGFloat = newMinLabelCenter.x + minLabelTextSize.width / 2.0
        let newSpacingBetweenTextLabels: CGFloat = newLeftMostXInMaxLabel - newRightMostXInMinLabel

        if disableRange || newSpacingBetweenTextLabels > minSpacingBetweenLabels {
            minLabel.position = newMinLabelCenter
            maxLabel.position = newMaxLabelCenter

            if minLabel.frame.minX < 0.0 {
                minLabel.frame.origin.x = 0.0
            }

            if maxLabel.frame.maxX > frame.width {
                maxLabel.frame.origin.x = frame.width - maxLabel.frame.width
            }
        } else {
            let increaseAmount: CGFloat = minSpacingBetweenLabels - newSpacingBetweenTextLabels
            minLabel.position = CGPoint(x: newMinLabelCenter.x - increaseAmount / 2.0, y: newMinLabelCenter.y)
            maxLabel.position = CGPoint(x: newMaxLabelCenter.x + increaseAmount / 2.0, y: newMaxLabelCenter.y)

            // Update x if they are still in the original position
            if minLabel.position.x == maxLabel.position.x {
                minLabel.position.x = leftHandle.frame.midX
                maxLabel.position.x = leftHandle.frame.midX + minLabel.frame.width / 2.0 + minSpacingBetweenLabels + maxLabel.frame.width / 2.0
            }

            if minLabel.frame.minX < 0.0 {
                minLabel.frame.origin.x = 0.0
                maxLabel.frame.origin.x = minSpacingBetweenLabels + minLabel.frame.width
            }

            if maxLabel.frame.maxX > frame.width {
                maxLabel.frame.origin.x = frame.width - maxLabel.frame.width
                minLabel.frame.origin.x = maxLabel.frame.origin.x - minSpacingBetweenLabels - minLabel.frame.width
            }
        }
    }

    private func updateFixedLabelPositions() {
        minLabel.position = CGPoint(x: xPositionAlongLine(for: minValue),
                                    y: sliderLine.frame.minY - (minLabelTextSize.height / 2.0) - (handleDiameter / 2.0) - labelPadding)
        maxLabel.position = CGPoint(x: xPositionAlongLine(for: maxValue),
                                    y: sliderLine.frame.minY - (maxLabelTextSize.height / 2.0) - (handleDiameter / 2.0) - labelPadding)
        if minLabel.frame.minX < 0.0 {
            minLabel.frame.origin.x = 0.0
        }

        if maxLabel.frame.maxX > frame.width {
            maxLabel.frame.origin.x = frame.width - maxLabel.frame.width
        }
    }

    fileprivate func refresh() {
        if enableStep && step > 0.0 {
            selectedMinValue = CGFloat(roundf(Float(selectedMinValue / step))) * step
            if let previousStepMinValue = previousStepMinValue, previousStepMinValue != selectedMinValue {
                TapticEngine.selection.feedback()
            }
            previousStepMinValue = selectedMinValue

            selectedMaxValue = CGFloat(roundf(Float(selectedMaxValue / step))) * step
            if let previousStepMaxValue = previousStepMaxValue, previousStepMaxValue != selectedMaxValue {
                TapticEngine.selection.feedback()
            }
            previousStepMaxValue = selectedMaxValue
        }

        let diff: CGFloat = selectedMaxValue - selectedMinValue

        if diff < minDistance {
            switch handleTracking {
            case .left:
                selectedMinValue = selectedMaxValue - minDistance
            case .right:
                selectedMaxValue = selectedMinValue + minDistance
            case .none:
                break
            }
        } else if diff > maxDistance {
            switch handleTracking {
            case .left:
                selectedMinValue = selectedMaxValue - maxDistance
            case .right:
                selectedMaxValue = selectedMinValue + maxDistance
            case .none:
                break
            }
        }

        // ensure the minimum and maximum selected values are within range. Access the values directly so we don't cause this refresh method to be called again (otherwise changing the properties causes a refresh)
        if selectedMinValue < minValue {
            selectedMinValue = minValue
        }
        if selectedMaxValue > maxValue {
            selectedMaxValue = maxValue
        }

        // update the frames in a transaction so that the tracking doesn't continue until the frame has moved.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateHandlePositions()
        updateLabelPositions()
        CATransaction.commit()

        updateLabelValues()
        updateColors()
        updateAccessibilityElements()

        // update the delegate
        if let delegate = delegate, handleTracking != .none {
            delegate.rangeSeekSlider(self, didChange: selectedMinValue, maxValue: selectedMaxValue)
        }
    }

    private func animate(handle: CALayer, selected: Bool) {
        let transform: CATransform3D
        if selected {
            transform = CATransform3DMakeScale(selectedHandleDiameterMultiplier, selectedHandleDiameterMultiplier, 1.0)
        } else {
            transform = CATransform3DIdentity
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        handle.transform = transform

        // the label above the handle will need to move too if the handle changes size
        updateLabelPositions()

        CATransaction.commit()
    }

    private func applySketchShadow(_ layer: CALayer,
                                   color: UIColor = .black,
                                   alpha: Float = 0.5,
                                   x: CGFloat = 0,
                                   y: CGFloat = 2,
                                   blur: CGFloat = 4,
                                   spread: CGFloat = 0) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = alpha
        layer.shadowOffset = CGSize(width: x, height: y)
        layer.shadowRadius = blur / 2.0
        if spread == 0 {
            layer.shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            layer.shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }

}


// MARK: - RangeSeekSliderLeftElement

private final class RangeSeekSliderLeftElement: UIAccessibilityElement {

    override func accessibilityIncrement() {
        guard let slider = accessibilityContainer as? RangeSeekSlider else { return }
        slider.selectedMinValue += slider.step
        accessibilityValue = slider.minLabel.string as? String
    }

    override func accessibilityDecrement() {
        guard let slider = accessibilityContainer as? RangeSeekSlider else { return }
        slider.selectedMinValue -= slider.step
        accessibilityValue = slider.minLabel.string as? String
    }
}


// MARK: - RangeSeekSliderRightElement

private final class RangeSeekSliderRightElement: UIAccessibilityElement {

    override func accessibilityIncrement() {
        guard let slider = accessibilityContainer as? RangeSeekSlider else { return }
        slider.selectedMaxValue += slider.step
        slider.refresh()
        accessibilityValue = slider.maxLabel.string as? String
    }

    override func accessibilityDecrement() {
        guard let slider = accessibilityContainer as? RangeSeekSlider else { return }
        slider.selectedMaxValue -= slider.step
        slider.refresh()
        accessibilityValue = slider.maxLabel.string as? String
    }
}


// MARK: - CGRect

private extension CGRect {

    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}


// MARK: - CGPoint

private extension CGPoint {

    func distance(to: CGPoint) -> CGFloat {
        let distX: CGFloat = to.x - x
        let distY: CGFloat = to.y - y
        return sqrt(distX * distX + distY * distY)
    }
}

public class LCTextLayer : CATextLayer {

    // REF: http://lists.apple.com/archives/quartz-dev/2008/Aug/msg00016.html
    // CREDIT: David Hoerl - https://github.com/dhoerl
    // USAGE: To fix the vertical alignment issue that currently exists within the CATextLayer class. Change made to the yDiff calculation.

    override init() {
        super.init()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(layer: aDecoder)
    }

    override public func draw(in ctx: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10

        ctx.saveGState()
        ctx.translateBy(x: 0, y: yDiff)
        super.draw(in: ctx)
        ctx.restoreGState()
    }
}
