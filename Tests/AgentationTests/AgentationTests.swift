import XCTest
@testable import Agentation

final class AgentationTests: XCTestCase {

    func testViewElementInfoDisplayName() {
        let elementWithLabel = ViewElementInfo(
            id: UUID(), typeName: "UIButton", frame: .zero,
            accessibilityLabel: "Submit Button", accessibilityIdentifier: "",
            accessibilityHint: "", accessibilityValue: "", agentationTag: "",
            children: [], path: ".View"
        )
        XCTAssertEqual(elementWithLabel.displayName, "Submit Button")

        let elementWithId = ViewElementInfo(
            id: UUID(), typeName: "UIButton", frame: .zero,
            accessibilityLabel: "", accessibilityIdentifier: "submitBtn",
            accessibilityHint: "", accessibilityValue: "", agentationTag: "",
            children: [], path: ".View"
        )
        XCTAssertEqual(elementWithId.displayName, "submitBtn")

        let elementWithTag = ViewElementInfo(
            id: UUID(), typeName: "UIButton", frame: .zero,
            accessibilityLabel: "", accessibilityIdentifier: "",
            accessibilityHint: "", accessibilityValue: "", agentationTag: "SubmitButton",
            children: [], path: ".View"
        )
        XCTAssertEqual(elementWithTag.displayName, "SubmitButton")

        let elementPlain = ViewElementInfo(
            id: UUID(), typeName: "UIButton", frame: .zero,
            accessibilityLabel: "", accessibilityIdentifier: "",
            accessibilityHint: "", accessibilityValue: "", agentationTag: "",
            children: [], path: ".View"
        )
        XCTAssertEqual(elementPlain.displayName, "UIButton")
    }

    func testViewElementInfoShortType() {
        func makeElement(typeName: String) -> ViewElementInfo {
            ViewElementInfo(
                id: UUID(), typeName: typeName, frame: .zero,
                accessibilityLabel: "", accessibilityIdentifier: "",
                accessibilityHint: "", accessibilityValue: "", agentationTag: "",
                children: [], path: ""
            )
        }

        XCTAssertEqual(makeElement(typeName: "UIButton").shortType, "button")
        XCTAssertEqual(makeElement(typeName: "UILabel").shortType, "text")
        XCTAssertEqual(makeElement(typeName: "UITextField").shortType, "input")
        XCTAssertEqual(makeElement(typeName: "UIImageView").shortType, "image")
    }

    func testViewElementInfoLeafElements() {
        let child1 = ViewElementInfo(
            id: UUID(), typeName: "UILabel", frame: .zero,
            accessibilityLabel: "", accessibilityIdentifier: "",
            accessibilityHint: "", accessibilityValue: "", agentationTag: "",
            children: [], path: ".Parent > .Child1"
        )
        let child2 = ViewElementInfo(
            id: UUID(), typeName: "UIButton", frame: .zero,
            accessibilityLabel: "", accessibilityIdentifier: "",
            accessibilityHint: "", accessibilityValue: "", agentationTag: "",
            children: [], path: ".Parent > .Child2"
        )
        let parent = ViewElementInfo(
            id: UUID(), typeName: "UIView", frame: .zero,
            accessibilityLabel: "", accessibilityIdentifier: "",
            accessibilityHint: "", accessibilityValue: "", agentationTag: "",
            children: [child1, child2], path: ".Parent"
        )

        let leaves = parent.leafElements()
        XCTAssertEqual(leaves.count, 2)
        XCTAssertEqual(leaves[0].path, ".Parent > .Child1")
        XCTAssertEqual(leaves[1].path, ".Parent > .Child2")
    }

    @MainActor
    func testSnapshotElementHitTest() {
        let elements = [
            SnapshotElement(id: UUID(), displayName: "Button", shortType: "button",
                           frame: CGRect(x: 100, y: 100, width: 100, height: 50), path: ".Button"),
            SnapshotElement(id: UUID(), displayName: "Parent", shortType: "view",
                           frame: CGRect(x: 0, y: 0, width: 300, height: 300), path: ".Parent"),
        ]

        let snapshot = HierarchySnapshot(
            leafElements: elements,
            capturedAt: Date(),
            sourceType: .viewHierarchy,
            viewportSize: CGSize(width: 375, height: 812),
            pageName: "Test"
        )

        let session = CaptureSession(
            dataSource: MockDataSource(),
            snapshot: snapshot,
        )

        let foundSmall = session.hitTest(point: CGPoint(x: 150, y: 125))
        XCTAssertEqual(foundSmall?.displayName, "Button")

        let foundLarge = session.hitTest(point: CGPoint(x: 250, y: 250))
        XCTAssertEqual(foundLarge?.displayName, "Parent")

        let notFound = session.hitTest(point: CGPoint(x: 400, y: 400))
        XCTAssertNil(notFound)
    }

    func testFeedbackItemCreation() {
        let item = FeedbackItem(
            elementId: UUID(),
            text: "Change the text color",
            elementDisplayName: "Test Label",
            elementShortType: "text",
            elementFrame: CGRect(x: 10, y: 20, width: 100, height: 30),
            elementPath: ".View > .Label"
        )

        XCTAssertEqual(item.elementDisplayName, "Test Label")
        XCTAssertEqual(item.text, "Change the text color")
    }

    @MainActor
    func testCaptureSessionMarkdownFormatting() {
        let snapshot = HierarchySnapshot(
            leafElements: [],
            capturedAt: Date(),
            sourceType: .viewHierarchy,
            viewportSize: CGSize(width: 375, height: 812),
            pageName: "/Home"
        )

        let session = CaptureSession(
            dataSource: MockDataSource(),
            snapshot: snapshot,
        )

        let element1 = SnapshotElement(
            id: UUID(), displayName: "Welcome Message", shortType: "text",
            frame: CGRect(x: 20, y: 100, width: 335, height: 44),
            path: ".HomeView > .Header > .WelcomeLabel"
        )

        let element2 = SnapshotElement(
            id: UUID(), displayName: "loginButton", shortType: "button",
            frame: CGRect(x: 20, y: 500, width: 335, height: 50),
            path: ".HomeView > .Actions > #loginButton"
        )

        session.addFeedback("Make this larger", for: element1)
        session.addFeedback("Change to green", for: element2)

        let markdown = session.formatAsMarkdown()

        XCTAssertTrue(markdown.contains("## Page Feedback: /Home"))
        XCTAssertTrue(markdown.contains("**Viewport:** 375×812"))
        XCTAssertTrue(markdown.contains("Make this larger"))
        XCTAssertTrue(markdown.contains("Change to green"))
    }

    @MainActor
    func testCaptureSessionJSONFormatting() throws {
        let snapshot = HierarchySnapshot(
            leafElements: [],
            capturedAt: Date(),
            sourceType: .viewHierarchy,
            viewportSize: CGSize(width: 414, height: 896),
            pageName: "/Settings"
        )

        let session = CaptureSession(
            dataSource: MockDataSource(),
            snapshot: snapshot,
        )

        let element = SnapshotElement(
            id: UUID(), displayName: "Dark Mode", shortType: "toggle",
            frame: CGRect(x: 300, y: 200, width: 51, height: 31),
            path: ".Settings > .ThemeSection > .DarkModeToggle"
        )

        session.addFeedback("Enable by default", for: element)

        let jsonData = try session.formatAsJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        XCTAssertEqual(json["page"] as? String, "/Settings")

        let viewport = json["viewport"] as! [String: Int]
        XCTAssertEqual(viewport["width"], 414)
        XCTAssertEqual(viewport["height"], 896)

        let items = json["items"] as! [[String: Any]]
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0]["type"] as? String, "toggle")
        XCTAssertEqual(items[0]["displayName"] as? String, "Dark Mode")
    }
}

@MainActor
private final class MockDataSource: HierarchyDataSource {
    func capture() async -> HierarchySnapshot {
        HierarchySnapshot(
            leafElements: [],
            capturedAt: Date(),
            sourceType: .viewHierarchy,
            viewportSize: .zero,
            pageName: "Mock"
        )
    }

    func resolve(elementId: UUID) -> ElementResolution? {
        nil
    }
}
