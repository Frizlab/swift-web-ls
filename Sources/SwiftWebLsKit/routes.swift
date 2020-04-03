import Foundation

import Vapor



func routes(_ app: Application) throws {
	let c = FileAndFolderController(publicDirectory: app.directory.publicDirectory)
	app.get(use: c.serveFileOrDirectory)
	app.get(.catchall, use: c.serveFileOrDirectory)
}
