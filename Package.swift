// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-graphql-pagination",
    products: [
        .library(name: "GraphQLPagination", targets: ["GraphQLPagination"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-custom-dump.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "GraphQLPagination"
        ),
        .testTarget(
            name: "GraphQLPaginationTests",
            dependencies: [
                "GraphQLPagination",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
    ]
)
