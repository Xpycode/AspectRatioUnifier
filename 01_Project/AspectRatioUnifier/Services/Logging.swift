import Foundation
import os

enum AspectRatioUnifierLogger {
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.xpycode.AspectRatioUnifier", category: "UI")
    static let export = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.xpycode.AspectRatioUnifier", category: "Export")
    static let storage = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.xpycode.AspectRatioUnifier", category: "Storage")
}
