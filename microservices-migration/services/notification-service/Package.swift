// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "NotificationService",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        .executable(name: "NotificationService", targets: ["NotificationService"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.2"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.6.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.15.0"),
    ],
    targets: [
        .executableTarget(
            name: "NotificationService",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Redis", package: "redis"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        )
    ]
)
