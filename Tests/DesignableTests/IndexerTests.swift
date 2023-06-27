import XCTest
@testable import Designable

final class IndexerTests: XCTestCase {
    func testSectionsOrdered() {
        let indexer = Indexer(names: ["Abel", "Bernard"])
        XCTAssertEqual(indexer.sections, ["A", "B"])
    }

    func testSectionsUnordered() {
        let indexer = Indexer(names: ["Bernard", "Abel"])
        XCTAssertEqual(indexer.sections, ["A", "B"])
    }

    func testValueForIndexPath() {
        let indexer = Indexer(names: ["Bernard", "Abel"])
        let indexPath = IndexPath(row: 0, section: 0)
        XCTAssertEqual(indexer.value(for: indexPath), "Abel")
    }

    func testNumberOfRowsInSection() {
        let indexer = Indexer(names: ["Bernard", "Anuel", "Abel"])
        XCTAssertEqual(indexer.numberOfRowsInSection(section: 0), 2)
    }

    func testEvaluateRealIndexPath() {
        let indexer = Indexer(names: ["Bernard", "Anuel", "Abel"])
        let evaluatedIndexPath = IndexPath(row: 1, section: 0)
        let realIndexPath = IndexPath(row: 2, section: 0)
        XCTAssertEqual(indexer.evaluateRealIndexPath(for: evaluatedIndexPath, originalSection: 0), realIndexPath)
    }
}
