//
// UIColor+ProtonMail.swift
// Proton Mail
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

import Foundation
import UIKit

extension UIColor {
    /// Does not include the number sign (#) at the beginning.
    var rrggbbaa: String {
        guard let components = cgColor.components else {
            return String(repeating: "0", count: 8)
        }

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        if cgColor.numberOfComponents < 3 {
            // UIExtendedGrayColorSpace
            red = components[0]
            green = components[0]
            blue = components[0]
            alpha = components[1]
        } else {
            red  = components[0]
            green = components[1]
            blue = components[2]
            alpha = components[3]
        }

        return String.init(
            format: String(repeating: "%02lX", count: 4),
            lroundf(Float(red * 255)),
            lroundf(Float(green * 255)),
            lroundf(Float(blue * 255)),
            lroundf(Float(alpha * 255))
        )
    }

    convenience init(RRGGBB: UInt) {
        self.init(
            red: CGFloat((RRGGBB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((RRGGBB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(RRGGBB & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    func toHex() -> String {
        guard let components = self.cgColor.components else {
            return "#000000"
        }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0

        if self.cgColor.numberOfComponents < 3 {
            // UIExtendedGrayColorSpace
            r = components[0]
            g = components[0]
            b = components[0]
        } else {
            r = components[0]
            g = components[1]
            b = components[2]
        }

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
}

extension UIColor {

    convenience init(hexColorCode: String) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        if hexColorCode.hasPrefix("#") {
            let index   = hexColorCode.index(hexColorCode.startIndex, offsetBy: 1)
            let hex     = String(hexColorCode[index...])
            let scanner = Scanner(string: hex)
            var hexValue: CUnsignedLongLong = 0

            if scanner.scanHexInt64(&hexValue) {
                if hex.count == 6 {
                    red   = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF) / 255.0
                } else if hex.count == 8 {
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF) / 255.0
                }
            }
        }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// Other Methods
extension UIColor {
    /**
     Create non-autoreleased color with in the given hex string and alpha
     
     :param:   hexString
     :param:   alpha
     :returns: color with the given hex string and alpha
     
     
     Example:
     
     // With hash
     let color: UIColor = UIColor(hexString: "#ff8942")
     
     // Without hash, with alpha
     let secondColor: UIColor = UIColor(hexString: "ff8942", alpha: 0.5)
     
     // Short handling
     let shortColorWithHex: UIColor = UIColor(hexString: "fff")
     */

    convenience init(hexString: String, alpha: Float) {
        var hex = hexString

        // Check for hash and remove the hash
        if hex.hasPrefix("#") {
            let hexL = hex.index(hex.startIndex, offsetBy: 1)
            hex = String(hex[hexL...])
        }

        if hex.count == 0 {
            hex = "000000"
        }

        let hexLength = hex.count
        // Check for string length
        assert(hexLength == 6 || hexLength == 3)

        // Deal with 3 character Hex strings
        if hexLength == 3 {
            let redR = hex.index(hex.startIndex, offsetBy: 1)
            let redHex = String(hex[..<redR])
            let greenL = hex.index(hex.startIndex, offsetBy: 1)
            let greenR = hex.index(hex.startIndex, offsetBy: 2)
            let greenHex = String(hex[greenL..<greenR])
            let blueL = hex.index(hex.startIndex, offsetBy: 2)
            let blueHex = String(hex[blueL...])
            hex = redHex + redHex + greenHex + greenHex + blueHex + blueHex
        }
        let redR = hex.index(hex.startIndex, offsetBy: 2)
        let redHex = String(hex[..<redR])
        let greenL = hex.index(hex.startIndex, offsetBy: 2)
        let greenR = hex.index(hex.startIndex, offsetBy: 4)
        let greenHex = String(hex[greenL..<greenR])

        let blueL = hex.index(hex.startIndex, offsetBy: 4)
        let blueR = hex.index(hex.startIndex, offsetBy: 6)
        let blueHex = String(hex[blueL..<blueR])

        var redInt: CUnsignedLongLong = 0
        var greenInt: CUnsignedLongLong = 0
        var blueInt: CUnsignedLongLong = 0

        Scanner(string: redHex).scanHexInt64(&redInt)
        Scanner(string: greenHex).scanHexInt64(&greenInt)
        Scanner(string: blueHex).scanHexInt64(&blueInt)

        self.init(red: CGFloat(redInt) / 255.0, green: CGFloat(greenInt) / 255.0, blue: CGFloat(blueInt) / 255.0, alpha: CGFloat(alpha))
    }

    convenience init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat) {
        assert(
            0...1 ~= hue &&
            0...1 ~= saturation &&
            0...1 ~= lightness &&
            0...1 ~= alpha,
            "Invalid hue:\(hue), saturation:\(saturation), lightness:\(lightness) or alpha:\(alpha)"
        )

        //From HSL TO HSB ---------
        var newSaturation: CGFloat = 0.0

        let brightness = lightness + saturation * min(lightness, 1-lightness)

        if brightness == 0 { newSaturation = 0.0 }
        else {
            newSaturation = 2 * (1 - lightness / brightness)
        }
        //---------

        self.init(hue: hue, saturation: newSaturation, brightness: brightness, alpha: alpha)
    }
}
