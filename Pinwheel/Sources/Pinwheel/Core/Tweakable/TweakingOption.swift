import UIKit

public struct TweakingOption {
    public var title: String
    public var description: String?
    public var action: ((() -> Void)?)

    public init(title: String, description: String? = nil, action: ((() -> Void))? = nil) {
        self.title = title
        self.description = description
        self.action = action
    }
}
