// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ZenzaiConverter",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ZenzaiConverter", targets: ["ZenzaiConverter"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/azooKey/AzooKeyKanaKanjiConverter",
            branch: "main",
            traits: ["Zenzai"]
        )
    ],
    targets: [
        .target(
            name: "ZenzaiConverter",
            dependencies: [
                .product(
                    name: "KanaKanjiConverterModuleWithDefaultDictionary",
                    package: "AzooKeyKanaKanjiConverter"
                )
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: .cxx17
)
