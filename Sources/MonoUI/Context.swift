
import U8g2Kit
import CU8g2
import Glibc

public class Context {

    public static var shared: Context!

    let driver: Driver

    private var animationValues: [AnimationValue] = []

    public init(driver: Driver) {
        self.driver = driver
        Context.shared = self
    }

    func setup() {
        // Do something
    }

    func loop() {
        updateAnimationValues()
    }

}

extension Context {
    public func addAnimationValue(_ animationValue: AnimationValue) {
        animationValues.append(animationValue)
    }

    public func removeAnimationValue(_ animationValue: AnimationValue) {
        animationValues.removeAll { ObjectIdentifier($0) == ObjectIdentifier(animationValue) }
    }

    public func updateAnimationValues() {
        for animationValue in animationValues {
            animationValue.update()
        }
    }
}