// swift-tools-version:5.9
import PackageDescription
let version = "1.4.0"
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
			checksum: "a4c3261546118ae0176110d1fef5bc0c23d0ce6ef3cc6ae035eb211206fccf5a"
		)
	]
)
