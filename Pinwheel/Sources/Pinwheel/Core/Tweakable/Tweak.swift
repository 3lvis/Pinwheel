import UIKit

public protocol Tweak {
    var title: String { set get }
    var description: String? { set get }
}

public struct TextTweak: Tweak {
    public var title: String
    public var description: String?
    public var action: (() -> Void)

    public init(title: String, description: String? = nil, action: @escaping (() -> Void)) {
        self.title = title
        self.description = description
        self.action = action
    }
}

public struct BoolTweak: Tweak  {
    public var title: String
    public var description: String?
    public var isOn: Bool
    public var action: ((Bool) -> Void)

    public init(title: String, description: String? = nil, isOn: Bool = false, action: @escaping ((Bool) -> Void)) {
        self.title = title
        self.description = description
        self.isOn = isOn
        self.action = action
    }
}
