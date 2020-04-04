import Foundation

import Leaf
import Vapor



struct URLEncodeLeafTag : LeafTag {
	
	static let name = "urlencode"
	
	func render(_ ctx: LeafContext) throws -> LeafData {
		guard let string = ctx.parameters.first?.string, ctx.parameters.count == 1 else {
			throw "parameter given to urlencode leaf tag is not a string"
		}
		guard let urlEncoded = string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
			throw "cannot add percent encoding to given string in urlencode Leaf tag"
		}
		return .string(urlEncoded)
	}
	
}


struct URLDecodeLeafTag : LeafTag {
	
	static let name = "urldecode"
	
	func render(_ ctx: LeafContext) throws -> LeafData {
		guard let string = ctx.parameters.first?.string, ctx.parameters.count == 1 else {
			throw "parameter given to urldecode leaf tag is not a string"
		}
		guard let urlDecoded = string.removingPercentEncoding else {
			throw "cannot remove percent encoding to given string in urldecode Leaf tag"
		}
		return .string(urlDecoded)
	}
	
}
