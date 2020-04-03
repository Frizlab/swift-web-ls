import Foundation

import Vapor
import Leaf



/* Called before your application initializes. */
public func configure(_ app: Application) throws {
	/* Use the Leaf renderer */
	app.views.use(.leaf)
	
	try routes(app)
}
