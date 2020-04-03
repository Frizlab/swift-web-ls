import Foundation

import Vapor



public final class FileAndFolderController {
	
	public let publicDirectory: URL
	
	public init(publicDirectory d: String) {
		publicDirectory = URL(fileURLWithPath: d, isDirectory: true)
	}
	
	public func serveFileOrDirectory(_ request: Request) throws -> EventLoopFuture<Response> {
		var path = request.url.path
		
		/* path must be relative */
		while path.hasPrefix("/") {
			path = String(path.dropFirst())
		}
		
		/* We also remove the trailing slashes (for cosmetic purpose) */
		while path.hasSuffix("/") {
			path = String(path.dropLast())
		}
		
		/* Protect against relative paths */
		guard !path.contains("../") else {
			throw Abort(.forbidden)
		}
		
		/* Create absolute file path URL */
		let fileURL = publicDirectory.appendingPathComponent(path.removingPercentEncoding ?? path)
		
		/* Check if file exists and is not a directory */
		var isDir: ObjCBool = false
		guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) else {
			throw Abort(.notFound)
		}
		
		if isDir.boolValue {
			struct FolderContext : Encodable {
				var folderName: String?
				var folderPath: String
				var subFolderNames: [String]
				var fileNames: [String]
			}
			
			var context = FolderContext(
				folderName: path.split(separator: "/").last.flatMap(String.init),
				folderPath: "/" + path,
				subFolderNames: [],
				fileNames: []
			)
			
			/* List files and folders in the folder */
			let elts = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: [.isDirectoryKey])
			for u in elts {
				/* Filter out hidden files */
				guard !u.lastPathComponent.hasPrefix(".") else {continue}
				
				guard let isDir = try u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
					throw Abort(.internalServerError)
				}
				if isDir {
					context.subFolderNames.append(u.lastPathComponent)
				} else {
					context.fileNames.append(u.lastPathComponent)
				}
			}
			
			return request.view.render("folder", context).flatMap{ $0.encodeResponse(for: request) }
		} else {
			/* Stream the file */
			let res = request.fileio.streamFile(at: fileURL.path)
			res.headers.contentType = .binary
			res.headers.contentDisposition = .init(.attachment, name: fileURL.deletingPathExtension().lastPathComponent, filename: fileURL.lastPathComponent)
			return request.eventLoop.makeSucceededFuture(res)
		}
	}
	
}
