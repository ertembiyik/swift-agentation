import XCTest
@testable import Agentation

final class AgentationTests: XCTestCase {

    func testElementInfoDisplayName() {
        // Test with accessibility label
        let elementWithLabel = ElementInfo(
            accessibilityLabel: "Submit Button",
            typeName: "UIButton",
            frame: .zero,
            path: ".View"
        )
        XCTAssertEqual(elementWithLabel.displayName, "Submit Button")

        // Test with accessibility identifier
        let elementWithId = ElementInfo(
            accessibilityIdentifier: "submitBtn",
            typeName: "UIButton",
            frame: .zero,
            path: ".View"
        )
        XCTAssertEqual(elementWithId.displayName, "submitBtn")

        // Test with agentation tag
        let elementWithTag = ElementInfo(
            typeName: "UIButton",
            frame: .zero,
            path: ".View",
            agentationTag: "SubmitButton"
        )
        XCTAssertEqual(elementWithTag.displayName, "SubmitButton")

        // Test fallback to type name
        let elementPlain = ElementInfo(
            typeName: "UIButton",
            frame: .zero,
            path: ".View"
        )
        XCTAssertEqual(elementPlain.displayName, "UIButton")
    }

    func testElementInfoShortType() {
        let button = ElementInfo(typeName: "UIButton", frame: .zero, path: "")
        XCTAssertEqual(button.shortType, "button")

        let label = ElementInfo(typeName: "UILabel", frame: .zero, path: "")
        XCTAssertEqual(label.shortType, "text")

        let textField = ElementInfo(typeName: "UITextField", frame: .zero, path: "")
        XCTAssertEqual(textField.shortType, "input")

        let image = ElementInfo(typeName: "UIImageView", frame: .zero, path: "")
        XCTAssertEqual(image.shortType, "image")
    }

    func testElementInfoFlattening() {
        let child1 = ElementInfo(typeName: "UILabel", frame: .zero, path: ".Parent > .Child1")
        let child2 = ElementInfo(typeName: "UIButton", frame: .zero, path: ".Parent > .Child2")
        let parent = ElementInfo(
            typeName: "UIView",
            frame: .zero,
            path: ".Parent",
            children: [child1, child2]
        )

        let flattened = parent.flattened()
        XCTAssertEqual(flattened.count, 3)
        XCTAssertEqual(flattened[0].typeName, "UIView")
        XCTAssertEqual(flattened[1].typeName, "UILabel")
        XCTAssertEqual(flattened[2].typeName, "UIButton")
    }

    func testElementInfoElementAtPoint() {
        let child = ElementInfo(
            typeName: "UIButton",
            frame: CGRect(x: 100, y: 100, width: 100, height: 50),
            path: ".Parent > .Button"
        )
        let parent = ElementInfo(
            typeName: "UIView",
            frame: CGRect(x: 0, y: 0, width: 300, height: 300),
            path: ".Parent",
            children: [child]
        )

        // Point inside child
        let foundChild = parent.elementAt(point: CGPoint(x: 150, y: 125))
        XCTAssertEqual(foundChild?.typeName, "UIButton")

        // Point outside child but inside parent
        let foundParent = parent.elementAt(point: CGPoint(x: 250, y: 250))
        XCTAssertEqual(foundParent?.typeName, "UIView")

        // Point outside everything
        let notFound = parent.elementAt(point: CGPoint(x: 400, y: 400))
        XCTAssertNil(notFound)
    }

    func testFeedbackItemCreation() {
        let element = ElementInfo(
            accessibilityLabel: "Test Label",
            typeName: "UILabel",
            frame: CGRect(x: 10, y: 20, width: 100, height: 30),
            path: ".View > .Label"
        )

        let item = FeedbackItem(element: element, feedback: "Change the text color")

        XCTAssertEqual(item.element.accessibilityLabel, "Test Label")
        XCTAssertEqual(item.feedback, "Change the text color")
        XCTAssertNotNil(item.timestamp)
    }

    func testPageFeedbackMarkdown() {
        var pageFeedback = PageFeedback(
            pageName: "/Home",
            viewportSize: CGSize(width: 375, height: 812)
        )

        let element1 = ElementInfo(
            accessibilityLabel: "Welcome Message",
            typeName: "UILabel",
            frame: CGRect(x: 20, y: 100, width: 335, height: 44),
            path: ".HomeView > .Header > .WelcomeLabel"
        )

        let element2 = ElementInfo(
            accessibilityIdentifier: "loginButton",
            typeName: "UIButton",
            frame: CGRect(x: 20, y: 500, width: 335, height: 50),
            path: ".HomeView > .Actions > #loginButton"
        )

        pageFeedback.items.append(FeedbackItem(element: element1, feedback: "Make this larger"))
        pageFeedback.items.append(FeedbackItem(element: element2, feedback: "Change to green"))

        let markdown = pageFeedback.toMarkdown()

        XCTAssertTrue(markdown.contains("## Page Feedback: /Home"))
        XCTAssertTrue(markdown.contains("**Viewport:** 375×812"))
        XCTAssertTrue(markdown.contains("### 1. text \"Welcome Message\""))
        XCTAssertTrue(markdown.contains("### 2. button #loginButton"))
        XCTAssertTrue(markdown.contains("Make this larger"))
        XCTAssertTrue(markdown.contains("Change to green"))
    }

    func testPageFeedbackJSON() throws {
        var pageFeedback = PageFeedback(
            pageName: "/Settings",
            viewportSize: CGSize(width: 414, height: 896)
        )

        let element = ElementInfo(
            accessibilityLabel: "Dark Mode",
            typeName: "UISwitch",
            frame: CGRect(x: 300, y: 200, width: 51, height: 31),
            path: ".Settings > .ThemeSection > .DarkModeToggle"
        )

        pageFeedback.items.append(FeedbackItem(element: element, feedback: "Enable by default"))

        let jsonData = try pageFeedback.toJSON()
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        XCTAssertEqual(json["page"] as? String, "/Settings")

        let viewport = json["viewport"] as! [String: Int]
        XCTAssertEqual(viewport["width"], 414)
        XCTAssertEqual(viewport["height"], 896)

        let items = json["items"] as! [[String: Any]]
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0]["type"] as? String, "toggle")
        XCTAssertEqual(items[0]["label"] as? String, "Dark Mode")
    }
}
