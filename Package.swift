// swift-tools-version:5.9
import PackageDescription
let version = "1.4.1"
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
			checksum: "160c91cd402f81fb74f33f1f3fd9d94929c88e3a289728525130a9f6f8df50df"
		)
	]
)
