@propertyWrapper
public class AnimationValue {

    private var value: Double

    private var target: Double

    public var speed: Double = 50

    public init(wrappedValue: Double) {
        self.value = wrappedValue
        self.target = wrappedValue
        Context.shared.addAnimationValue(self)
    }

    deinit {
        Context.shared.removeAnimationValue(self)
    }

    public var wrappedValue: Double {
        get {
            return value
        }
        set {
            target = newValue
        }
    }

    public var projectedValue: AnimationValue {
        return self
    }
}

extension AnimationValue {
    func update() {
        if value != target {
            if abs(value - target) < 0.15 {
                value = target
            } else {
                value += (target - value) / (speed / 10.0)
            }
        }
    }
}