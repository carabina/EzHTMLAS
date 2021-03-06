
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)


import UIKit

extension UILabel {

	public var HTML: String {
		get {
			guard let a = attributedText else { return "" }
			let f = (a.attribute("baseFont", at: 0, effectiveRange: nil) as? UIFont) ?? font
			return a.HTMLString(f)
			// 1st chr has font setting, label.font is 1st char font
		}
		set {
			if newValue.has(string: "<") {
				attributedText = newValue.attributedString(font)
			} else {
				attributedText = NSAttributedString(string: newValue)
			}
		}
	}
}

extension UITextView {
	public var HTML: String {
		get {
			guard let a = attributedText else { return "" }
			let f = (a.attribute("baseFont", at: 0, effectiveRange: nil) as? UIFont) ?? font
			return a.HTMLString(f)
		}
		set {
			attributedText = newValue.attributedString(font)
		}
	}
}

extension UIButton {
	public var HTML: String {
		get {
			guard let a = attributedTitle(for: .normal) else { return "" }
			let f = (a.attribute("baseFont", at: 0, effectiveRange: nil) as? UIFont) ?? titleLabel?.font ?? UIFont.systemFont(ofSize: 17)
			return a.HTMLString(f)
		}
		set {
			let f = titleLabel?.font ?? UIFont.systemFont(ofSize: 17)
			setAttributedTitle(newValue.attributedString(f), for: .normal)
		}
	}
}

extension String {

	public func attributedString(_ font: UIFont? = nil) -> NSAttributedString {
		return HTMLAttributedString.toAS(self, font: font ?? UIFont.systemFont(ofSize: 17))
	}
}

public extension NSAttributedString
{
	func HTMLString(_ font: UIFont? = nil) -> String {
		return HTMLAttributedString.toHTML(self, font: font ?? UIFont.systemFont(ofSize: 17))
	}
}

public extension NSParagraphStyle {

	static func makeWithAlignment(_ alignment: NSTextAlignment) -> NSParagraphStyle {
		let p = NSMutableParagraphStyle()
		p.alignment = alignment
		return p as NSParagraphStyle
	}

	static var Right: NSParagraphStyle { return makeWithAlignment(.right) }
	static var Left: NSParagraphStyle { return makeWithAlignment(.left) }
	static var Center: NSParagraphStyle { return makeWithAlignment(.center) }
}

public struct HTMLAttributedString {

	public static func setStyle(_ key: String, _ font: UIFont, _ color: UIColor?, _ bgcolor: UIColor?) {
		var dic: [String: Any] = [:]
		dic[NSFontAttributeName] = font
		if let c = color { dic[NSForegroundColorAttributeName] = c }
		if let c = bgcolor { dic[NSBackgroundColorAttributeName] = c }
		styles[key] = dic
	}

	public static func setStyle(_ key: String, param: [String: Any]) {
		styles[key] = param
	}

	public static var styles: [String: [String: Any]] = [
		"head": [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)], // 17 semi-bold
		"sub": [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)], // 15
		"body": [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)], // 17
		"foot": [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)], // 13
		"caption1": [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)], // 12
		"caption2": [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption2)], // 11
		// you can add more
	]

	public static var fontSizes: [CGFloat] = [0.6, 0.75, 0.9, 1.0, 1.2, 1.5, 2.0, 3.0] // mul

	public static var iconFont = "FontAwesome"
//
//	// for extend
//	public static var as2htmlHandler: ((_ atb: [String: Any], _ str: String, _ elements: inout [String]) -> String?)?
//	public static var html2asHandler: ((_ element: String, _ params: [String: String], _ atb: inout [String: Any]) -> NSAttributedString?)?

	/* return tags
	 font size=1-7
	 font point-size=
	 font color=#hexcolor
	 a href=url
	 b
	 i
	 br
	 img (no src)

	 */

	static func toHTML(_ astring: NSAttributedString, font: UIFont) -> String {

		func nsatb2htmlElement(_ atb: [String: Any], font: UIFont) -> [String] {

			var result: [String] = []
			var fontr: [String] = []

			for (k, v) in atb {
				switch k {
				case NSFontAttributeName:
					guard let f = v as? UIFont else { break }
					let des = f.fontDescriptor
					if des.symbolicTraits.contains(.traitBold) { result.append("b") }
					if des.symbolicTraits.contains(.traitItalic) { result.append("i") }

					if f.pointSize == font.pointSize { break }

					var done = false
					for i in 0 ..< fontSizes.count {
						if font.pointSize * fontSizes[i] == f.pointSize {
							fontr.append("size=\"\((i))\"")
							done = true
							break
						}
					}
					if done { break }
					fontr.append("point-size=\"\((f.pointSize))\"")

				case NSForegroundColorAttributeName:
					guard let c = v as? UIColor else { break }
					var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
					c.getRed(&r, green: &g, blue: &b, alpha: &a)
					let s = String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
					fontr.append("color=\"#\(s)\"")

				case NSLinkAttributeName:
					guard let s = v as? String else { break }
					result.append("a href=\"\(s)\"")

				case NSUnderlineStyleAttributeName:
					result.append("u")

				default:
					break
				}

			}

			if !fontr.isEmpty { result.append("font " + fontr.joined(separator: " ")) }

			return result
		}


		var current: [String] = []
		var result: String = ""

		astring.enumerateAttributes(in: NSRange(location: 0, length: astring.length), options: []) { (attributes, range, pointer) in
			let elements = nsatb2htmlElement(attributes, font: font)
			let str = astring.attributedSubstring(from: range).string

//			if let h = as2htmlHandler {
//				if let r = h(attributes, str, &elements) {
//					result += r
//					return
//				}
//			}

			if str == "\u{fffc}" {
				result += "<img"
				if let v = astring.attribute("imgsrc", at: range.location, effectiveRange: nil) as? String {
					result += " src=\"\(v)\""
				}
				result += "/>"
				return
			}

			while let v = current.last {
				if elements.contains(v) { break }
				result += "</\( v.components(separatedBy:" ").first ?? "")>"
				current.removeLast()
			}

			for v in elements {
				if current.contains(v) { continue }
				result += "<\(v)>"
				current.append(v)
			}

			result += str.replace([
				("&", "&amp;"),
				("\u{a0}", "&nbsp;"),
				("\"", "&quot;"),
				("<", "&lt;"),
				(">", "&gt;"),
				("\n", "<br/>")])

		}

		while let v = current.last {
			result += "</\( v.components(separatedBy:" ").first ?? "")>"
			current.removeLast()
		}

		return result
	}

	/*capable

	 font size=1-7 (default:3 relative)
	 font point-size=point
	 font color=#hexcolor
	 font background=#hexcolor
	 br
	 p
	 p aligin=left,center,right
	 p direction=vertical
	 span style=user-defined-style
	 a href=url
	 img src=name
	 img src=name width= height= x=offset y=offset

	 */
	public static func toAS(_ str: String, font: UIFont) -> NSAttributedString {

		func xstr(_ ptr: UnsafePointer<xmlChar>?) -> String? {
			guard let ptr = ptr else { return nil }
			var r: String? = nil
			ptr.withMemoryRebound(to: CChar.self, capacity: 4) {
				r = String(cString: $0)
			}
			return r
		}

		func changeFontSize(_ atb: inout [String: Any], size: CGFloat) {
			if let f = atb[NSFontAttributeName] as? UIFont {
				atb[NSFontAttributeName] = UIFont(descriptor: f.fontDescriptor, size: size)
			} else { atb[NSFontAttributeName] = UIFont.systemFont(ofSize: size) }
		}

		func changeFontTrait(_ atb: inout [String: Any], traits: UIFontDescriptorSymbolicTraits) {
			if let f = atb[NSFontAttributeName] as? UIFont {
				atb[NSFontAttributeName] = UIFont(descriptor: f.fontDescriptor.withSymbolicTraits(traits)!, size: f.pointSize)
			} else { atb[NSFontAttributeName] = UIFont.boldSystemFont(ofSize: 17) }
		}

		func modifyAttribute(_ atb: inout [String: Any], font: UIFont, node: xmlNodePtr) -> NSAttributedString? {

			var result: NSAttributedString? = nil

			guard let ielement = xstr(node.pointee.name) else { return result }
			let element = ielement.lowercased()

			var params: [String: String] = [:]
			var props = xmlNodePtr(node.pointee.properties)

			while props != nil {
				if props?.pointee.children == nil { continue }
				guard let key = xstr(props?.pointee.name), var val = xstr(props?.pointee.children.pointee.content) else { continue }
				if val.hasSuffix("/") { val = val.ns.substring(to: val.length - 1) }
				params[key.lowercased()] = val
				props = props?.pointee.next
			}

			switch element {
			case "br":
				result = NSAttributedString(string: "\n", attributes: atb)

			case "font":
				if let v = params["size"] {
					var idx = v.intValue
					if v.hasPrefix("+") || v.hasPrefix("-") {
						var org: Int = 3
						if let f = atb[NSFontAttributeName] as? UIFont, let fi = fontSizes.index(of: f.pointSize / font.pointSize) { org = fi }
						idx += org
					}
					if idx < 0 || idx >= fontSizes.count { idx = 3 }
					changeFontSize(&atb, size: font.pointSize * fontSizes[idx])
				}

				if let v = params["point-size"] { changeFontSize(&atb, size: v.CGFloatValue) }
				if let v = params["point"] { changeFontSize(&atb, size: v.CGFloatValue) }
				if let v = params["color"] { atb[NSForegroundColorAttributeName] = UIColor.hexColor(v) }
				if let v = params["background"] { atb[NSBackgroundColorAttributeName] = UIColor.hexColor(v) }
				if let v = params["line-height"] {
					let ps = NSMutableParagraphStyle()
					ps.maximumLineHeight = v.CGFloatValue
					ps.minimumLineHeight = v.CGFloatValue
					atb[NSParagraphStyleAttributeName] = ps
				}
				
			case "b":
				changeFontTrait(&atb, traits: .traitBold)

			case "i":
				changeFontTrait(&atb, traits: .traitItalic)

			case "img":
				if let src = params["src"], let img = UIImage(named: src) {
					let attach = NSTextAttachment()
					attach.image = img
					var rc: CGRect = CGRect.zero
					rc.size = img.size
					if let v = params["width"] { rc.size.width = v.CGFloatValue }
					if let v = params["height"] { rc.size.height = v.CGFloatValue }
					rc.origin.y = round((font.capHeight - img.size.height) / 2)
					if let v = params["x"] { rc.origin.x = v.CGFloatValue } // may be no effect x
					if let v = params["y"] { rc.origin.y = v.CGFloatValue }
					attach.bounds = rc
					let ras = NSAttributedString(attachment: attach).mutableCopy() as? NSMutableAttributedString
					ras?.addAttribute("imgsrc", value: src, range: NSRange(location: 0, length: 1))
					result = ras?.copy() as? NSAttributedString
				}

			case "p", "span":
				if element == "p" { result = NSAttributedString(string: "\n", attributes: atb) }

				if let v = params["style"] {
					if let style = styles[v] {
						for (k, z) in style { atb[k] = z }
					}
				}

				if let v = params["align"] {
					switch v {
					case "left": atb[NSParagraphStyleAttributeName] = NSParagraphStyle.Left
					case "right": atb[NSParagraphStyleAttributeName] = NSParagraphStyle.Right
					case "center": atb[NSParagraphStyleAttributeName] = NSParagraphStyle.Center
					default: break
					}
				}

				if let v = params["direction"] {
					if v == "vertical" { atb[NSVerticalGlyphFormAttributeName] = 1 }
				}

			case "a":
				if let v = params["href"] { atb[NSLinkAttributeName] = v }

			case "icon":
				if let src = params["src"] {
					let fname = params["font"] ?? iconFont
					result = NSAttributedString(string: src, attributes: [NSFontAttributeName: fname])
				}

			default:
				break
//			if let h = html2asHandler {
//				if let r = h(element, params, &atb) { result = r }
//			}
			}

			return result
		}

		func asByNode(_ node: xmlNodePtr, attributes: [String: Any], font: UIFont) -> NSAttributedString {

			let result = NSMutableAttributedString()
			var atb = attributes

			if node.pointee.type == XML_ELEMENT_NODE {
				if let r = modifyAttribute(&atb, font: font, node: node) {
					result.append(r)
				}
			}

			if node.pointee.type != XML_ENTITY_REF_NODE && node.pointee.type != XML_ELEMENT_NODE && node.pointee.content != nil {
				if let s = xstr(node.pointee.content) {
					let t = s.removingPercentEncoding ?? ""
					result.append(NSAttributedString(string: t, attributes: atb))
				}
			}

			var current = node.pointee.children
			while current != nil {
				result.append(asByNode(current!, attributes: atb, font: font))
				current = current?.pointee.next
			}
			return result
		}

		let result = NSMutableAttributedString()
		guard let data = str.data(using: String.Encoding.utf8) else { return result }

		let document = htmlReadMemory((data as NSData).bytes.bindMemory(to: Int8.self, capacity: data.count), Int32(data.count), nil, "UTF-8", Int32(HTML_PARSE_NOWARNING.rawValue | HTML_PARSE_NOERROR.rawValue))
		if document == nil { return result }

		var current = document?.pointee.children
		while current != nil {
			result.append(asByNode(current!, attributes: [:], font: font))
			current = current?.pointee.next
		}
		xmlFreeDoc(document)

		let rs = result.string
		if rs.hasPrefix("\n") { result.deleteCharacters(in: NSRange(location: 0, length: 1)) }

		// add original base size
		result.addAttributes(["baseFont": font], range: NSRange(location: 0, length: result.length))

		return result
	}

}
