import Foundation

import NIO
import Vapor



public final class FileAndFolderController {
	
	static public let uploadsFolderName = ".uploads"
	
	public let publicDirectory: URL
	
	public init(publicDirectory d: String) {
		publicDirectory = URL(fileURLWithPath: d, isDirectory: true)
	}
	
	public func serveFileOrDirectory(_ request: Request) throws -> EventLoopFuture<Response> {
		let (path, fileURL) = try sanitizePathAndCreateFileURL(request.url.path)
		
		/* Check if file exists and is not a directory */
		var isDir: ObjCBool = false
		guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) else {
			throw Abort(.notFound)
		}
		
		if isDir.boolValue {
			guard path.hasSuffix("/") || path.isEmpty else {
				return request.eventLoop.makeSucceededFuture(request.redirect(to: path + "/"))
			}
			
			struct FolderContext : Encodable {
				var folderName: String?
				var folderPath: String
				var subFolderNames: [String]
				var fileNames: [String]
				var allowUpload: Bool
				var showParent: Bool
			}
			
			var context = FolderContext(
				folderName: path.split(separator: "/").last.flatMap(String.init),
				folderPath: "/" + path,
				subFolderNames: [],
				fileNames: [],
				allowUpload: false,
				showParent: !path.isEmpty
			)
			
			/* List files and folders in the folder */
			let elts = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: [.isDirectoryKey])
			for u in elts {
				if try u.lastPathComponent == ".uploads" && u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true {
					context.allowUpload = true
				}
				if u.lastPathComponent == ".hide_parent" {
					context.showParent = false
				}
				
				/* Filter out hidden files */
				guard !u.lastPathComponent.hasPrefix(".") else {continue}
				
				guard let isDir = try u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory else {
					throw "Cannot retrieve URL directory value"
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
	
	public func receiveFile(_ request: Request) throws -> EventLoopFuture<Response> {
		struct FileAndUser : Decodable {
			var name: String
			var file: File
		}
		
		let (_, baseFileURL) = try sanitizePathAndCreateFileURL(request.url.path)
		
		/* Apparently this puts the whole file in memory. I hoped it would not,
		 * but alas, it seems it does! */
		let fileAndUser = try request.content.decode(FileAndUser.self)
		
		guard !fileAndUser.name.isEmpty && !fileAndUser.file.filename.isEmpty else {
			throw "the username and the file are required"
		}
		
		let saferUserName = pathSafeStr(from: fileAndUser.name)
		let saferFileName = pathSafeStr(from: fileAndUser.file.filename)
		let saferFileNameBase = (saferFileName as NSString).deletingPathExtension
		let saferFileNameExtension = (saferFileName as NSString).pathExtension
		let folderURL = baseFileURL.appendingPathComponent(FileAndFolderController.uploadsFolderName).appendingPathComponent(saferUserName)
		var i = 0
		var fileURL: URL
		repeat {
			i += 1
			fileURL = folderURL.appendingPathComponent(saferFileNameBase + (i > 1 ? "-\(i)" : "")).appendingPathExtension(saferFileNameExtension)
		} while FileManager.default.fileExists(atPath: fileURL.path)
		
		try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
		guard FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) else {
			request.logger.error("Cannot create file at path \(fileURL.path)")
			throw "Cannot create file"
		}
		
		let fh = try NIOFileHandle(path: fileURL.path, mode: .write)
		/* Do not defer the close (otherwise the file will be closed before the content has been written to it!) */
		
		let fio = NonBlockingFileIO(threadPool: request.application.threadPool)
		return fio.write(fileHandle: fh, buffer: fileAndUser.file.data, eventLoop: request.eventLoop)
		.flatMapThrowing{ _ in
			try fh.close()
			return request.view.render("upload-success").flatMap{ $0.encodeResponse(for: request) }
		}
		.flatMap{ $0 }
	}
	
	private func sanitizePathAndCreateFileURL(_ path: String) throws -> (String, URL) {
		var path = path
		
		/* path must be relative */
		while path.hasPrefix("/") {
			path = String(path.dropFirst())
		}
		
		/* We also remove the double trailing slashes */
		while path.hasSuffix("//") {
			path = String(path.dropLast())
		}
		
		/* Protect against relative paths */
		guard !path.contains("/../") && !path.hasPrefix("../") && !path.hasSuffix("/..") && path != ".." else {
			throw Abort(.forbidden)
		}
		
		/* Create absolute file path URL */
		let fileURL = publicDirectory.appendingPathComponent(path.removingPercentEncoding ?? path)
		
		return (path, fileURL)
	}
	
	private func pathSafeStr(from str: String) -> String {
		let str1 = str.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: nil)
		let charSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_,")).inverted
		return str1.components(separatedBy: charSet).joined(separator: " ")
	}
	
}
