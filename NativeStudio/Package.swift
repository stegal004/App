// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Studio",
    platforms: [.macOS(.v27), .iOS(.v27)],
    products: [.executable(name: "Studio", targets: ["StudioApp"])],
    targets: [.executableTarget(name: "StudioApp")]
)
