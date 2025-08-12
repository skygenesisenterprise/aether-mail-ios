//
//  String+ExtensionTests.swift
//  ProtonMailTests - Created on 28/09/2018.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import ProtonMail

final class String_ExtensionTests: XCTestCase {

    func testHasRe() {
        XCTAssertTrue("Re: Test mail".hasRe())
        XCTAssertFalse("Test mail".hasRe())
    }

    func testHasFw() {
        XCTAssertTrue("Fw: Test mail".hasFw())
        XCTAssertFalse("Test mail".hasFw())
    }

    func testHasFwd() {
        XCTAssertTrue("Fw: Test mail".hasFwd())
        XCTAssertFalse("Test mail".hasFwd())
    }

    func testTrim() {
        XCTAssertEqual("  abc ".trim(), "abc")
        XCTAssertEqual("　　 abc 　　".trim(), "abc")
    }

    func testLn2Br() {
        XCTAssertEqual("a\r\nbc\n".ln2br(), "a<br />bc<br />")
        XCTAssertEqual("abc".ln2br(), "abc")
    }

    func testRmln() {
        XCTAssertEqual("a\nb".rmln(), "ab")
        XCTAssertEqual(#"a\b"#.rmln(), #"a\b"#)
    }

    func testlr2lrln() {
        XCTAssertEqual("\r\n".lr2lrln(), "\r\n")
        XCTAssertEqual("\r".lr2lrln(), "\r\n")
        XCTAssertEqual("\r\t".lr2lrln(), "\r\n\t")
    }

    func testDecodeHTML() {
        XCTAssertEqual("abc".decodeHtml(), "abc")
        XCTAssertEqual("&amp;&quot;&#039;&#39;&lt;&gt;".decodeHtml(), "&\"''<>")
    }

    func testEncodeHTML() {
        XCTAssertEqual("abc".encodeHtml(), "abc")
        XCTAssertEqual("&\"''<><br />".encodeHtml(), "&amp;&quot;&#039;&#039;&lt;&gt;<br />")
    }

    func testPreg_match() {
        XCTAssertFalse("abc".preg_match("ccc"))
        XCTAssertTrue("abccdew".preg_match("cc"))
    }

    func testPreg_match_resultInGroup() throws {
        var text = "src=\"cid:abcde\""
        var result = try XCTUnwrap(text.preg_match(resultInGroup: 1, "src=(['|\"])cid:abcde"))
        XCTAssertEqual(result, "\"")

        text = "src='cid:abcde'"
        result = try XCTUnwrap(text.preg_match(resultInGroup: 1, "src=(['|\"])cid:abcde"))
        XCTAssertEqual(result, "'")

        XCTAssertNil(text.preg_match(resultInGroup: 2, "src=(['|\"])cid:abcde"))
    }

    func testHasImage() {
        let testSrc1 = "<embed type=\"image/svg+xml\" src=\"cid:5d13cdcaf81f4108654c36fc.svg@www.emailprivacytester.com\"/>"
        XCTAssertFalse(testSrc1.hasRemoteImage())
        let testSrc2 = "<embed type=\"image/svg+xml\" src='cid:5d13cdcaf81f4108654c36fc.svg@www.emailprivacytester.com'/>"
        XCTAssertFalse(testSrc2.hasRemoteImage())
        let testSrc3 = "<img width=\"16\" height=\"16\" src=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=img\"/><img src=\"#\" width=\"16\" height=\"16\"/>"
        XCTAssertTrue(testSrc3.hasRemoteImage())
        let testSrc4 = "<script type=\"text/javascript\" src=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=js\">"
         XCTAssertTrue(testSrc4.hasRemoteImage())
        let testSrc5 = "<video src=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=video\" width=\"1\" height=\"1\"></video>"
        XCTAssertTrue(testSrc5.hasRemoteImage())
        let testSrc6 = "<iframe width=\"1\" height=\"1\" src=\"data:text/html;charset=utf-8,&amp;lt;html&amp;gt;&amp;lt;head&amp;gt;&amp;lt;meta http-equiv=&amp;quot;Refresh&amp;quot; content=&amp;quot;1; URLhttps://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=iframeRefresh&amp;quot;&amp;gt;&amp;lt;/head&amp;gt;&amp;lt;body&amp;gt;&amp;lt;/body&amp;gt;&amp;lt;/html&amp;gt;\"></iframe>"
        XCTAssertTrue(testSrc6.hasRemoteImage())
        let testUrl1 = "<p style=\"background-image:url(&#x27;https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=backgroundImage&#x27;);\"></p>"
        XCTAssertTrue(testUrl1.hasRemoteImage())
        let testUrl2 = "<p style=\"content:url(&#x27;https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=cssContent&#x27;);\"></p>"
        XCTAssertTrue(testUrl2.hasRemoteImage())
        let testposter = "<video poster=\"https://api.emailprivacytester.com/callback?code=5d13cdcaf81f4108654c36fc&amp;test=videoPoster\" width=\"1\" height=\"1\">"
        XCTAssertTrue(testposter.hasRemoteImage())
        let testxlink = "<svg viewBox=\"0 0 160 40\" xmlns=\"http://www.w3.org/2000/svg\"><a xlink:href=\"https://developer.mozilla.org/\"><text x=\"10\" y=\"25\">MDN Web Docs</text></a> </svg>"
        XCTAssertTrue(testxlink.hasRemoteImage())
        let testBackground1 = "<body background=\"URL\">"
        XCTAssertTrue(testBackground1.hasRemoteImage())
        let testEmbeddedBase64Image = "<img src=\"data:image:base64"
        XCTAssertFalse(testEmbeddedBase64Image.hasRemoteImage())
        let testCachedEmbeddedImage = "<img src=\"pm-cache:ielwfjlsfise"
        XCTAssertFalse(testCachedEmbeddedImage.hasRemoteImage())
    }

    func testRandomString() {
        XCTAssertEqual(String.randomString(3).count, 3)
        XCTAssertTrue(String.randomString(0).isEmpty)
    }

    func testEncodeBase64() {
        XCTAssertEqual("This is a sample string".encodeBase64(),
                       "VGhpcyBpcyBhIHNhbXBsZSBzdHJpbmc=")
        XCTAssertEqual("Welcome to protonmail".encodeBase64(),
                       "V2VsY29tZSB0byBwcm90b25tYWls")
    }

    func testParseObject() {
        XCTAssertEqual("".parseObject(), [:])
        let dict = "{\"dev\":\"Dev\",\"name\":\"Tester\"}".parseObject()
        XCTAssertEqual(dict["dev"], "Dev")
        XCTAssertEqual(dict["name"], "Tester")

        let dict2 = "{\"age\":100,\"name\":\"Tester\"}".parseObject()
        XCTAssertEqual(dict2, [:])
    }

    func testToDictionary() {
        XCTAssertNil("".toDictionary())
        guard let dict = "{\"age\":100,\"name\":\"Tester\"}".toDictionary() else {
            XCTFail("Shouldn't be nil")
            return
        }
        XCTAssertEqual(dict["name"] as? String, "Tester")
        XCTAssertEqual(dict["age"] as? Int, 100)
    }

    func testParseJSON() {
        var str = "{\"Name\": \"tester\", \"device\": \"iPhone\"}"
        guard let result1: [String: String] = str.parseJSON() else {
            XCTFail("Should parse success")
            return
        }
        XCTAssertEqual(result1["Name"], "tester")
        XCTAssertEqual(result1["device"], "iPhone")

        str = "[{\"Name\": \"name1\"}, {\"age\": 3}]"
        guard let result2: [[String: Any]] = str.parseJSON() else {
            XCTFail("Should parse success")
            return
        }
        XCTAssertEqual(result2.count, 2)
        XCTAssertEqual(result2[0]["Name"] as? String, "name1")
        XCTAssertEqual(result2[1]["age"] as? Int, 3)

        str = ""
        let result3: [String: Any]? = str.parseJSON()
        XCTAssertNil(result3)

        str = "[{\"Name\": \"name1\"}, {\"age\": 3}]"
        let result4: [String: String]? = str.parseJSON()
        XCTAssertNil(result4)
    }

    func testCommaSeparatedListShouldJoinWithComma() {
        XCTAssertEqual(["foo", "bar"].asCommaSeparatedList(trailingSpace: false), "foo,bar")
    }

    func testCommaSeparatedListShouldJoinWithCommaWithTrailingSpaceIfParameterTrue() {
        XCTAssertEqual(["foo", "bar"].asCommaSeparatedList(trailingSpace: true), "foo, bar")
    }

    func testCommaSeparatedListShouldIgnoreEmptyStringElementsWhenSingleValue() {
        XCTAssertEqual(["", "foo"].asCommaSeparatedList(trailingSpace: true), "foo")
    }

    func testCommaSeparatedListShouldIgnoreEmptyStringElements() {
        XCTAssertEqual(["", "foo", "", "bar"].asCommaSeparatedList(trailingSpace: true), "foo, bar")
    }

    func testRemoveMailToIfNeeded() {
        var str = "mailto:abc@test.com"
        var result = str.removeMailToIfNeeded()
        XCTAssertEqual(result, "abc@test.com")

        str = "     mailto:abc@test.com"
        result = str.removeMailToIfNeeded()
        XCTAssertEqual(result, "abc@test.com")

        str = "prefix.mailto:abc@test.com"
        result = str.removeMailToIfNeeded()
        XCTAssertEqual(result, str)

        str = "abc@test.com"
        result = str.removeMailToIfNeeded()
        XCTAssertEqual(result, str)

        str = "mapto:abc@test.com"
        result = str.removeMailToIfNeeded()
        XCTAssertEqual(result, str)

        str = "Tester name "
        result = str.removeMailToIfNeeded()
        XCTAssertEqual(result, str)
    }

    func testSubscriptRange() {
        let str = "abcdefghijk"
        let range1 = NSRange(location: 0, length: 3)
        XCTAssertEqual(str[range1], "abc")
        let range2 = NSRange(location: 5, length: 2)
        XCTAssertEqual(str[range2], "fg")
    }
}

extension String_ExtensionTests {
    func testGetDisplayAddress() {
        let data = """
        [
          {"Name": "Tester"},
          {"Address": "zzz@test.com"},
          {"Name": "Hi", "Address": "abc@test.com"}
        ]
        """
        let ans1 = [
            "Tester &lt;<a href=\"mailto:\" class=\"\"></a>&gt;",
            " &lt;<a href=\"mailto:zzz@test.com\" class=\"\">zzz@test.com</a>&gt;",
            "Hi &lt;<a href=\"mailto:abc@test.com\" class=\"\">abc@test.com</a>&gt;"
        ]
        let result1 = data.formatJsonContact(true)
        for ans in ans1 {
            XCTAssertTrue(result1.preg_match(ans))
        }

        let ans2 = [
            "Tester&lt;&gt;",
            "&lt;zzz@test.com&gt;",
            "Hi&lt;abc@test.com&gt;"
        ]
        let result2 = data.formatJsonContact(false)
        for ans in ans2 {
            XCTAssertTrue(result2.preg_match(ans))
        }
    }
}
