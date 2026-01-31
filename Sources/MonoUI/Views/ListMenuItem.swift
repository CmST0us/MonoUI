import CU8g2

// MARK: - ListMenuItemType

/// Types of menu items that can be displayed in a ListMenu.
public enum ListMenuItemType {
    /// Plain text item (no special behavior).
    case text

    /// Toggle switch item (can be turned on/off).
    case toggle

    /// Radio button item (single selection from a group).
    case radio

    /// Checkbox item (multiple selection).
    case checkbox

    /// Value display item (shows a numeric value).
    case value

    /// Section header (non-selectable title).
    case header

    /// Separator line (non-selectable divider).
    case separator
}

// MARK: - ListMenuItem

/// A base class representing a menu item in a ListMenu.
///
/// Different types of menu items can be displayed in a ListMenu, such as:
/// - Plain text items
/// - Toggle switches
/// - Radio buttons
/// - Checkboxes
/// - Value displays
/// - Section headers
open class ListMenuItem {
    /// The display text for this menu item.
    public var text: String

    /// The type identifier for this menu item.
    public var itemType: ListMenuItemType

    public init(text: String, itemType: ListMenuItemType) {
        self.text = text
        self.itemType = itemType
    }

    /// Draws any additional content for this item (e.g., checkbox, toggle).
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - x: The x position to draw at.
    ///   - y: The y position to draw at.
    ///   - lineHeight: The height of the line.
    ///   - isSelected: Whether this item is currently selected.
    open func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        // Override in subclasses
    }

    /// Handles selection/activation of this item.
    /// - Returns: True if the item handled the selection, false otherwise.
    open func handleSelection() -> Bool {
        return false
    }
}

// MARK: - TextMenuItem

/// A simple text menu item with no special behavior.
public class TextMenuItem: ListMenuItem {
    public init(_ text: String) {
        super.init(text: text, itemType: .text)
    }

    public override func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        // No additional content for plain text items
    }

    public override func handleSelection() -> Bool {
        return false
    }
}

// MARK: - ToggleMenuItem

/// A toggle switch menu item that can be turned on or off.
public class ToggleMenuItem: ListMenuItem {
    /// The current state of the toggle (true = on, false = off).
    public var isOn: Bool {
        didSet {
            onStateChanged?(isOn)
        }
    }

    /// Callback invoked when the toggle state changes.
    public var onStateChanged: ((Bool) -> Void)?

    /// Size of the toggle box (default: 12.0).
    public var boxSize: Double = 12.0

    /// Padding inside the toggle box (default: 2.0).
    public var boxPadding: Double = 2.0

    /// Left margin for the toggle box (default: 95.0).
    public var boxLeftMargin: Double = 95.0

    /// Top margin for the toggle box (default: 2.0).
    public var boxTopMargin: Double = 2.0

    public init(_ text: String, isOn: Bool = false, onStateChanged: ((Bool) -> Void)? = nil) {
        self.isOn = isOn
        self.onStateChanged = onStateChanged
        super.init(text: text, itemType: .toggle)
    }

    public override func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        guard let u8g2 = u8g2 else { return }

        let boxX = x + boxLeftMargin
        let boxY = y + boxTopMargin

        // Only draw if the box is at least partially visible (Y coordinate is valid)
        // The clipping window will handle items that are completely outside the viewport
        guard boxY >= -boxSize && boxY < Double(UInt16.max) else {
            return
        }

        // Calculate actual screen position: if boxY is negative, adjust to show only visible portion
        // boxY is relative to the item's screen position, which may be negative when scrolling
        let actualBoxY = boxY  // This is already in screen coordinates

        // Draw toggle box frame - use original coordinates, let clipping window handle cropping
        // Use bitPattern to allow negative coordinates (clipping window handles boundaries)
        u8g2_SetDrawColor(u8g2, 1)
        let clampedBoxX = max(Int16.min, min(Int16.max, Int16(boxX)))
        let clampedBoxY = max(Int16.min, min(Int16.max, Int16(actualBoxY)))
        u8g2_DrawRFrame(u8g2,
                       u8g2_uint_t(bitPattern: clampedBoxX),
                       u8g2_uint_t(bitPattern: clampedBoxY),
                       u8g2_uint_t(max(0, min(boxSize, Double(UInt16.max)))),
                       u8g2_uint_t(max(0, min(boxSize, Double(UInt16.max)))),
                       u8g2_uint_t(1))

        // Draw filled dot if toggle is on
        if isOn {
            let dotX = boxX + boxPadding + 1
            let dotY = actualBoxY + boxPadding + 1
            let dotSize = boxSize - (boxPadding + 1) * 2

            let clampedDotX = max(Int16.min, min(Int16.max, Int16(dotX)))
            let clampedDotY = max(Int16.min, min(Int16.max, Int16(dotY)))
            u8g2_DrawBox(u8g2,
                         u8g2_uint_t(bitPattern: clampedDotX),
                         u8g2_uint_t(bitPattern: clampedDotY),
                         u8g2_uint_t(max(0, min(dotSize, Double(UInt16.max)))),
                         u8g2_uint_t(max(0, min(dotSize, Double(UInt16.max)))))
        }
    }

    public override func handleSelection() -> Bool {
        isOn.toggle()
        return true
    }
}

// MARK: - RadioValueHolder

/// A simple wrapper class to hold the selected value for a radio button group.
public class RadioValueHolder {
    public var value: Int

    public init(_ value: Int) {
        self.value = value
    }
}

// MARK: - RadioMenuItem

/// A radio button menu item (single selection from a group).
public class RadioMenuItem: ListMenuItem {
    /// The value this radio button represents.
    public let value: Int

    /// The holder for the currently selected value in the radio group.
    public let selectedValueHolder: RadioValueHolder

    /// The currently selected value in the radio group.
    public var selectedValue: Int {
        get {
            return selectedValueHolder.value
        }
        set {
            selectedValueHolder.value = newValue
            onSelectionChanged?(newValue)
        }
    }

    /// The position index of this item in the menu (used for visual indication).
    public var position: Int = 0

    /// Callback invoked when the selection changes.
    public var onSelectionChanged: ((Int) -> Void)?

    /// Size of the radio button circle (default: 12.0).
    public var circleSize: Double = 12.0

    /// Padding inside the circle (default: 2.0).
    public var circlePadding: Double = 2.0

    /// Left margin for the radio button (default: 95.0).
    public var circleLeftMargin: Double = 95.0

    /// Top margin for the radio button (default: 2.0).
    public var circleTopMargin: Double = 2.0

    public init(_ text: String, value: Int, selectedValueHolder: RadioValueHolder, position: Int = 0, onSelectionChanged: ((Int) -> Void)? = nil) {
        self.value = value
        self.selectedValueHolder = selectedValueHolder
        self.position = position
        self.onSelectionChanged = onSelectionChanged
        super.init(text: text, itemType: .radio)
    }

    public override func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        guard let u8g2 = u8g2 else { return }

        let circleX = x + circleLeftMargin
        let circleY = y + circleTopMargin

        // Only draw if the circle is at least partially visible (Y coordinate is valid)
        // The clipping window will handle items that are completely outside the viewport
        guard circleY >= -circleSize && circleY < Double(UInt16.max) else {
            return
        }

        // Calculate actual screen position: if circleY is negative, adjust to show only visible portion
        let actualCircleY = circleY  // This is already in screen coordinates

        // Draw radio button circle frame - use original coordinates, let clipping window handle cropping
        // Use bitPattern to allow negative coordinates (clipping window handles boundaries)
        u8g2_SetDrawColor(u8g2, 1)
        let clampedCircleX = max(Int16.min, min(Int16.max, Int16(circleX)))
        let clampedCircleY = max(Int16.min, min(Int16.max, Int16(actualCircleY)))
        u8g2_DrawRFrame(u8g2,
                       u8g2_uint_t(bitPattern: clampedCircleX),
                       u8g2_uint_t(bitPattern: clampedCircleY),
                       u8g2_uint_t(max(0, min(circleSize, Double(UInt16.max)))),
                       u8g2_uint_t(max(0, min(circleSize, Double(UInt16.max)))),
                       u8g2_uint_t(1))

        // Draw filled dot if this radio is selected
        if selectedValue == value {
            let dotX = circleX + circlePadding + 1
            let dotY = actualCircleY + circlePadding + 1
            let dotSize = circleSize - (circlePadding + 1) * 2

            let clampedDotX = max(Int16.min, min(Int16.max, Int16(dotX)))
            let clampedDotY = max(Int16.min, min(Int16.max, Int16(dotY)))
            u8g2_DrawBox(u8g2,
                         u8g2_uint_t(bitPattern: clampedDotX),
                         u8g2_uint_t(bitPattern: clampedDotY),
                         u8g2_uint_t(max(0, min(dotSize, Double(UInt16.max)))),
                         u8g2_uint_t(max(0, min(dotSize, Double(UInt16.max)))))
        }
    }

    public override func handleSelection() -> Bool {
        selectedValue = value
        return true
    }
}

// MARK: - CheckboxStatesHolder

/// A simple wrapper class to hold the checkbox states array for a checkbox group.
public class CheckboxStatesHolder {
    public var states: [Bool]

    public init(_ states: [Bool]) {
        self.states = states
    }
}

// MARK: - CheckboxMenuItem

/// A checkbox menu item (multiple selection).
public class CheckboxMenuItem: ListMenuItem {
    /// The index of this checkbox in the checkbox array.
    public let index: Int

    /// The holder for the array of checkbox states (shared across all checkboxes in a group).
    public let checkboxStatesHolder: CheckboxStatesHolder

    /// The array of checkbox states (shared across all checkboxes in a group).
    public var checkboxStates: [Bool] {
        get {
            return checkboxStatesHolder.states
        }
        set {
            checkboxStatesHolder.states = newValue
        }
    }

    /// Callback invoked when the checkbox state changes.
    public var onStateChanged: ((Int, Bool) -> Void)?

    /// Size of the checkbox box (default: 12.0).
    public var boxSize: Double = 12.0

    /// Padding inside the checkbox box (default: 2.0).
    public var boxPadding: Double = 2.0

    /// Left margin for the checkbox box (default: 95.0).
    public var boxLeftMargin: Double = 95.0

    /// Top margin for the checkbox box (default: 2.0).
    public var boxTopMargin: Double = 2.0

    public init(_ text: String, index: Int, checkboxStatesHolder: CheckboxStatesHolder, onStateChanged: ((Int, Bool) -> Void)? = nil) {
        self.index = index
        self.checkboxStatesHolder = checkboxStatesHolder
        self.onStateChanged = onStateChanged
        super.init(text: text, itemType: .checkbox)
    }

    public var isChecked: Bool {
        get {
            guard index >= 0 && index < checkboxStates.count else { return false }
            return checkboxStates[index]
        }
        set {
            guard index >= 0 && index < checkboxStates.count else { return }
            checkboxStates[index] = newValue
            onStateChanged?(index, newValue)
        }
    }

    public override func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        guard let u8g2 = u8g2 else { return }

        let boxX = x + boxLeftMargin
        let boxY = y + boxTopMargin

        // Only draw if the box is at least partially visible (Y coordinate is valid)
        // The clipping window will handle items that are completely outside the viewport
        guard boxY >= -boxSize && boxY < Double(UInt16.max) else {
            return
        }

        // Calculate actual screen position: if boxY is negative, adjust to show only visible portion
        let actualBoxY = boxY  // This is already in screen coordinates

        // Draw checkbox frame - use original coordinates, let clipping window handle cropping
        // Use bitPattern to allow negative coordinates (clipping window handles boundaries)
        u8g2_SetDrawColor(u8g2, 1)
        let clampedBoxX = max(Int16.min, min(Int16.max, Int16(boxX)))
        let clampedBoxY = max(Int16.min, min(Int16.max, Int16(actualBoxY)))
        u8g2_DrawRFrame(u8g2,
                       u8g2_uint_t(bitPattern: clampedBoxX),
                       u8g2_uint_t(bitPattern: clampedBoxY),
                       u8g2_uint_t(max(0, min(boxSize, Double(UInt16.max)))),
                       u8g2_uint_t(max(0, min(boxSize, Double(UInt16.max)))),
                       u8g2_uint_t(1))

        // Draw filled dot if checkbox is checked
        if isChecked {
            let dotX = boxX + boxPadding + 1
            let dotY = actualBoxY + boxPadding + 1
            let dotSize = boxSize - (boxPadding + 1) * 2

            let clampedDotX = max(Int16.min, min(Int16.max, Int16(dotX)))
            let clampedDotY = max(Int16.min, min(Int16.max, Int16(dotY)))
            u8g2_DrawBox(u8g2,
                         u8g2_uint_t(bitPattern: clampedDotX),
                         u8g2_uint_t(bitPattern: clampedDotY),
                         u8g2_uint_t(max(0, min(dotSize, Double(UInt16.max)))),
                         u8g2_uint_t(max(0, min(dotSize, Double(UInt16.max)))))
        }
    }

    public override func handleSelection() -> Bool {
        isChecked.toggle()
        return true
    }
}

// MARK: - ValueMenuItem

/// A menu item that displays a numeric value.
public class ValueMenuItem: ListMenuItem {
    /// The value to display.
    public var value: Int {
        didSet {
            onValueChanged?(value)
        }
    }

    /// Callback invoked when the value changes.
    public var onValueChanged: ((Int) -> Void)?

    /// Left margin for the value display (default: 95.0).
    public var valueLeftMargin: Double = 95.0

    public init(_ text: String, value: Int, onValueChanged: ((Int) -> Void)? = nil) {
        self.value = value
        self.onValueChanged = onValueChanged
        super.init(text: text, itemType: .value)
    }

    public override func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        guard let u8g2 = u8g2 else { return }

        let valueX = x + valueLeftMargin
        let valueY = y + lineHeight / 2

        // Draw the value as text
        u8g2_SetDrawColor(u8g2, 1)
        let valueStr = String(value)
        u8g2_SetFont(u8g2, u8g2_font_6x10_tf)
        u8g2_DrawStr(u8g2,
                    u8g2_uint_t(max(0, min(valueX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(valueY, Double(UInt16.max)))),
                    valueStr)
    }

    public override func handleSelection() -> Bool {
        return false
    }
}

// MARK: - HeaderMenuItem

/// A section header menu item (non-selectable title).
public class HeaderMenuItem: ListMenuItem {
    public init(_ text: String) {
        super.init(text: text, itemType: .header)
    }

    public override func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        // No additional content for headers
    }

    public override func handleSelection() -> Bool {
        return false
    }
}

// MARK: - SeparatorMenuItem

/// A separator line menu item (non-selectable divider).
public class SeparatorMenuItem: ListMenuItem {
    public init(_ text: String = "--------------------------") {
        super.init(text: text, itemType: .separator)
    }

    public override func drawAdditionalContent(u8g2: UnsafeMutablePointer<u8g2_t>?, x: Double, y: Double, lineHeight: Double, isSelected: Bool) {
        // Separators are drawn as text, no additional content needed
    }

    public override func handleSelection() -> Bool {
        return false
    }
}
