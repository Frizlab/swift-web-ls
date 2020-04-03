// swift-tools-version:5.2
import PackageDescription


let package = Package(
	name: "swift-web-ls",
	platforms: [
		.macOS(.v10_15),
	],
	products: [
		.library(name: "SwiftWebLsKit", targets: ["SwiftWebLsKit"]),
		.executable(name: "swift-web-ls", targets: ["swift-web-ls"])
	],
	dependencies: [
		// 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-rc"),
		.package(url: "https://github.com/vapor/leaf.git", from: "4.0.0-rc")
	],
	targets: [
		.target(name: "SwiftWebLsKit", dependencies: [
			.product(name: "Leaf", package: "leaf"),
			.product(name: "Vapor", package: "vapor")
		]),
		.target(name: "swift-web-ls", dependencies: [
			.target(name: "SwiftWebLsKit")
		]),
		.testTarget(name: "SwiftWebLsKitTests", dependencies: [
			.target(name: "SwiftWebLsKit"),
			.product(name: "XCTVapor", package: "vapor")
		])
	]
)
