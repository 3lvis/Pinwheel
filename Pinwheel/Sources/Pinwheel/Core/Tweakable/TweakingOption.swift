import UIKit

public typealias TweakCompletion<T: Any> = ((T) -> Void)

public protocol Tweak {
    var title: String { set get }
    var description: String? { set get }
    var action: TweakCompletion<Any> { set get }
}

public struct TextTweak: Tweak {
    public var title: String
    public var description: String?
    public var action: TweakCompletion<Any>

    public init(title: String, description: String? = nil, action: @escaping TweakCompletion<Any>) {
        self.title = title
        self.description = description
        self.action = action
    }
}

public struct BoolTweak: Tweak  {
    public var title: String
    public var description: String?
    public var defaultValue: Bool
    public var action: TweakCompletion<Any>

    public init(title: String, description: String? = nil, defaultValue: Bool = false, action: @escaping TweakCompletion<Any>) {
        self.title = title
        self.description = description
        self.defaultValue = defaultValue
        self.action = action
    }
}
