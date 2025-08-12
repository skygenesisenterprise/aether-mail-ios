@testable import ProtonMail
import XCTest

class DateFormatter_ContactBirthdayFormatterTests: XCTestCase {

    var sut: DateFormatter!

    override func setUp() {
        super.setUp()

        sut = .contactBirthdayFormatter
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func testContactBirthdayFormatter() {
        XCTAssertEqual(sut.string(from: .fixture("2021-02-02 00:00:00")), "Feb 2, 2021")
        XCTAssertEqual(sut.string(from: .fixture("2021-02-01 00:00:00")), "Feb 1, 2021")
        XCTAssertEqual(sut.string(from: .fixture("2021-01-02 01:00:00")), "Jan 2, 2021")
    }

}
