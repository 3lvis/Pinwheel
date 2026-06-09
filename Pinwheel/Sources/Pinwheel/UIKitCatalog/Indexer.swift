import UIKit

struct Indexer {
    var indexAndValues = [String: [String]]()

    var initialNames: [String]

    var sections: [String] {
        return Array(indexAndValues.keys.sorted(by: <))
    }

    init(names: [String]) {
        self.initialNames = names

        for name in names {
            let firstLetter = String(name.prefix(1))
            var values = [String]()
            if let existingValues = indexAndValues[firstLetter] {
                values = existingValues
            }
            values.append(name)
            indexAndValues[firstLetter] = values
        }
    }

    func value(for indexPath: IndexPath) -> String {
        let index = sections[indexPath.section]
        if let values = indexAndValues[index] {
            return values[indexPath.row]
        } else {
            return ""
        }
    }

    func evaluateRealIndexPath(for indexPath: IndexPath, originalSection: Int) -> IndexPath? {
        let value = value(for: indexPath)
        for (index, name) in initialNames.enumerated() {
            if value == name {
                return IndexPath(row: index, section: originalSection)
            }
        }

        return nil
    }

    func numberOfRowsInSection(section: Int) -> Int {
        let index = sections[section]
        if let values = indexAndValues[index] {
            return values.count
        } else {
            return 0
        }
    }
}
