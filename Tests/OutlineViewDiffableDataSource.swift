import XCTest
import OutlineViewDiffableDataSource

final class OutlineViewDiffableDataSourceTests: XCTestCase {

  struct OutlineItem: Equatable, Identifiable { let id: String }

  private lazy var outlineView: NSOutlineView = {
    let firstColumn = NSTableColumn()
    let outlineView = NSOutlineView()
    outlineView.addTableColumn(firstColumn)
    outlineView.outlineTableColumn = firstColumn
    return outlineView
  }()

  func testEmptyOutlineView() {

    // GIVEN: Empty data source
    let dataSource: OutlineViewDiffableDataSource<OutlineItem> = .init(outlineView: outlineView)
    XCTAssertTrue(outlineView.dataSource === dataSource)

    // WHEN: Outline view is loaded
    outlineView.layoutSubtreeIfNeeded()

    // THEN: Outline view is empty
    XCTAssertEqual(outlineView.numberOfRows, 0)
  }

  func testRootItems() {

    // GIVEN: Some items
    let a = OutlineItem(id: "a")
    let b = OutlineItem(id: "b")
    let c = OutlineItem(id: "c")

    // WHEN: They are added to the snapshot
    let dataSource: OutlineViewDiffableDataSource<OutlineItem> = .init(outlineView: outlineView)
    var snapshot = dataSource.snapshot()
    snapshot.appendItems([a, b, c])
    dataSource.applySnapshot(snapshot, animatingDifferences: false)

    // THEN: They appear in the outline view
    XCTAssertEqual(outlineView.numberOfRows, 3)
  }

  func testAnimatedInsertionsAndDeletions() {

    // GIVEN: Some items
    let a = OutlineItem(id: "a")
    let a1 = OutlineItem(id: "a1")
    let a2 = OutlineItem(id: "a2")
    let a3 = OutlineItem(id: "a3")
    let b = OutlineItem(id: "b")
    let b1 = OutlineItem(id: "b1")
    let b2 = OutlineItem(id: "b2")

    // GIVEN: Some items in the outline view
    let dataSource: OutlineViewDiffableDataSource<OutlineItem> = .init(outlineView: outlineView)
    var initialSnapshot = dataSource.snapshot()
    initialSnapshot.appendItems([a, b])
    initialSnapshot.appendItems([a1], into: a)
    initialSnapshot.appendItems([b2], into: b)
    dataSource.applySnapshot(initialSnapshot, animatingDifferences: false)

    // WHEN: Items are inserted with animation
    var finalSnapshot = dataSource.snapshot()
    finalSnapshot.insertItems([a2, a3], afterItem: a1)
    finalSnapshot.insertItems([b1], beforeItem: b2)
    finalSnapshot.deleteItems([a1, b2])

    // Wait while animation is completed
    let e = expectation(description: "Animation")
    dataSource.applySnapshot(finalSnapshot, animatingDifferences: true) {
      e.fulfill()
    }
    waitForExpectations(timeout: 0.5, handler: nil)

    // THEN: Outline view is updated
    outlineView.expandItem(nil, expandChildren: true)
    let expandedItems = (0 ..< outlineView.numberOfRows)
      .map(outlineView.item(atRow:)).compactMap { $0 as? OutlineItem }
    XCTAssertEqual(expandedItems, [a, a2, a3, b, b1])
  }

  func testAnimatedMoves() {

    // GIVEN: Some items
    let a = OutlineItem(id: "a")
    let a1 = OutlineItem(id: "a1")
    let a2 = OutlineItem(id: "a2")
    let a3 = OutlineItem(id: "a3")
    let b = OutlineItem(id: "b")
    let b1 = OutlineItem(id: "b1")
    let b2 = OutlineItem(id: "b2")

    // GIVEN: Thes items in the outline view
    let dataSource: OutlineViewDiffableDataSource<OutlineItem> = .init(outlineView: outlineView)
    var initialSnapshot = dataSource.snapshot()
    initialSnapshot.appendItems([a, b])
    initialSnapshot.appendItems([a1, b2, a3], into: a)
    initialSnapshot.appendItems([b1, a2], into: b)
    dataSource.applySnapshot(initialSnapshot, animatingDifferences: false)

    // WHEN: Items are moved
    var finalSnapshot = dataSource.snapshot()
    finalSnapshot.moveItem(a2, beforeItem: b2)
    finalSnapshot.moveItem(b2, afterItem: b1)

    // Wait while animation is completed
    let e = expectation(description: "Animation")
    dataSource.applySnapshot(finalSnapshot, animatingDifferences: true) {
      e.fulfill()
    }
    waitForExpectations(timeout: 0.5, handler: nil)

    // THEN: Outline view is updated
    outlineView.expandItem(nil, expandChildren: true)
    let expandedItems = (0 ..< outlineView.numberOfRows)
      .map(outlineView.item(atRow:)).compactMap { $0 as? OutlineItem }
    XCTAssertEqual(expandedItems, [a, a1, a2, a3, b, b1, b2])
  }
}
