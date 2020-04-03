import Foundation

import Leaf
import Vapor



struct IsEmptyLeafTag : LeafTag {
	
	static let name = "isEmpty"
	
	func render(_ ctx: LeafContext) throws -> LeafData {
		guard let array = ctx.parameters.first?.array, ctx.parameters.count == 1 else {
			throw Abort(.internalServerError)
		}
		return .bool(array.isEmpty)
	}
	
}
