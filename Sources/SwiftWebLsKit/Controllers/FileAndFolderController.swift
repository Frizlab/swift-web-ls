import Foundation

import Vapor



public final class FileAndFolderController {
	
	public let publicDirectory: URL
	
	public init(publicDirectory d: String) {
		publicDirectory = URL(fileURLWithPath: d, isDirectory: true)
	}
	
	public func serveFileOrDirectory(_ request: Request) -> EventLoopFuture<Response> {
		var path = request.url.path
		
		/* path must be relative */
		while path.hasPrefix("/") {
			path = String(path.dropFirst())
		}
		
		/* Protect against relative paths */
		guard !path.contains("../") else {
			return request.eventLoop.makeFailedFuture(Abort(.forbidden))
		}
		
		/* Create absolute file path */
		let filePath = publicDirectory.appendingPathComponent(path.removingPercentEncoding ?? path).path
		
		/* Check if file exists and is not a directory */
		var isDir: ObjCBool = false
		guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
			return request.view.render("folder").flatMap{ $0.encodeResponse(for: request) }
		}
		
		/* Stream the file */
		let res = request.fileio.streamFile(at: filePath)
		return request.eventLoop.makeSucceededFuture(res)
	}
	
}
