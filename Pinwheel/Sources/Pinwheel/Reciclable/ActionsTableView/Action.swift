import UIKit

public struct Action {
    let title: String
    let action: (() -> (Void))
    let isCritical: Bool

    public init(title: String, isCritical: Bool = false, action: @escaping (() -> (Void))) {
        self.title = title
        self.isCritical = isCritical
        self.action = action
    }
}
