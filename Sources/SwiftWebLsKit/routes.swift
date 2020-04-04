import Foundation

import Vapor



func routes(_ app: Application) throws {
	let c = FileAndFolderController(publicDirectory: app.directory.publicDirectory)
	app.get(use: c.serveFileOrDirectory) /* Probably needed because of a bug: https://github.com/vapor/vapor/issues/2288 */
	app.get(.catchall, use: c.serveFileOrDirectory)
	app.post(use: c.receiveFile)
	app.post(.catchall, use: c.receiveFile)
}
