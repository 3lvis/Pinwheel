import UIKit

public struct State {
    private static let lastSelectedIndexPathRowKey = "lastSelectedIndexPathRowKey"
    private static let lastSelectedIndexPathSectionKey = "lastSelectedIndexPathSectionKey"
    private static let lastCornerForTweakingButtonKey = "lastCornerForTweakingButtonKey"
    private static let lastSelectedSectionKey = "lastSelectedSectionKey"
    private static let lastSelectedDeviceKey = "lastSelectedDeviceKey"

    public static var lastSelectedIndexPath: IndexPath? {
        get {
            guard let row = UserDefaults.standard.object(forKey: lastSelectedIndexPathRowKey) as? Int else { return nil }
            guard let section = UserDefaults.standard.object(forKey: lastSelectedIndexPathSectionKey) as? Int else { return nil }
            return IndexPath(row: row, section: section)
        }
        set {
            if let row = newValue?.row {
                UserDefaults.standard.set(row, forKey: lastSelectedIndexPathRowKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSelectedIndexPathRowKey)
            }

            if let section = newValue?.section {
                UserDefaults.standard.set(section, forKey: lastSelectedIndexPathSectionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSelectedIndexPathSectionKey)
            }
            UserDefaults.standard.synchronize()
        }
    }

    static var lastCornerForTweakingButton: Int? {
        get {
            return UserDefaults.standard.object(forKey: lastCornerForTweakingButtonKey) as? Int
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastCornerForTweakingButtonKey)
            UserDefaults.standard.synchronize()
        }
    }

    static var lastSelectedSection: Int {
        get {
            return UserDefaults.standard.integer(forKey: lastSelectedSectionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastSelectedSectionKey)
            UserDefaults.standard.synchronize()
        }
    }

    static var selectedDeviceForCurrentIndexPath: Int? {
        get {
            if let options = UserDefaults.standard.value(forKey: lastSelectedDeviceKey) as? [IndexPath : Int], let indexPath = lastSelectedIndexPath {
                return options[indexPath]
            } else {
                return nil
            }
        }
        set {
            if let indexPath = lastSelectedIndexPath, let selectedDevice = newValue {
                if var options = UserDefaults.standard.value(forKey: lastSelectedDeviceKey) as? [IndexPath : Int] {
                    options[indexPath] = selectedDevice
                    UserDefaults.standard.set(options, forKey: lastSelectedDeviceKey)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
}
