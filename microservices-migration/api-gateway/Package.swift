// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "APIGateway",
    platforms: [
       .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.20.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "APIGateway",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "JWT", package: "jwt"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
