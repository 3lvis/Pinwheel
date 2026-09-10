import UIKit
import SwiftUI

@resultBuilder
public enum PinwheelSectionBuilder {
    public static func buildExpression(_ expression: PinwheelSection) -> [PinwheelSection] {
        return [expression]
    }

    public static func buildExpression(_ expression: [PinwheelSection]) -> [PinwheelSection] {
        return expression
    }

    public static func buildBlock(_ components: [PinwheelSection]...) -> [PinwheelSection] {
        return components.flatMap { $0 }
    }

    public static func buildArray(_ components: [[PinwheelSection]]) -> [PinwheelSection] {
        return components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [PinwheelSection]?) -> [PinwheelSection] {
        return component ?? []
    }

    public static func buildEither(first component: [PinwheelSection]) -> [PinwheelSection] {
        return component
    }

    public static func buildEither(second component: [PinwheelSection]) -> [PinwheelSection] {
        return component
    }
}

public struct PinwheelSection {
    public let title: String
    public let items: [PinwheelItem]

    /// Slugified title; must be unique within a catalog since persistence keys off it.
    public var id: String {
        title.pinwheelGeneratedID
    }

    public init(title: String, items: [PinwheelItem]) {
        self.title = title
        self.items = items
    }

    public init(_ title: String, @PinwheelItemBuilder items: () -> [PinwheelItem]) {
        self.title = title
        self.items = items()
    }
}

extension PinwheelSection: Identifiable {}
