// swift-tools-version:5.9
import PackageDescription
let version = "1.5.2"
let package = Package(
	name: "OpusKit",
    products: [
		.library(
			name: "OpusKit",
			targets: ["OpusKit"]),
		],
	dependencies: [],
	targets: [
		.binaryTarget(
			name: "OpusKit",
			url: "https://github.com/Phonebooth/OpusKit/releases/download/" + version + "/OpusKit.xcframework.zip",
			checksum: "f829aa696f6a4cb76c8f5a0db4df7afc387e80ee2bd5951918ee91e474746f63"
		)
	]
)
