import Foundation

import Leaf
import Vapor



struct URLEncodeLeafTag : LeafTag {
	
	static let name = "urlencode"
	
	func render(_ ctx: LeafContext) throws -> LeafData {
		print(ctx)
		guard let string = ctx.parameters.first?.string, ctx.parameters.count == 1 else {
			throw Abort(.internalServerError)
		}
		guard let urlEncoded = string.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
			throw Abort(.internalServerError)
		}
		return .string(urlEncoded)
	}
	
}
