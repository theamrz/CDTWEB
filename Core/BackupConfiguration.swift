import Foundation

/// تنظیمات جامع برای عملیات Backup
struct BackupConfiguration: Codable, Equatable {
    // MARK: - Extensions
    
    /// پسوندهای فایل‌های کد (پیش‌فرض: .swift)
    var codeExtensions: Set<String> = [".swift"]
    
    /// پسوندهای اضافه که کاربر تعریف می‌کند (روی codeExtensions اعمال می‌شود)
    var customCodeExtensions: Set<String> = []
    
    /// تمام پسوندهای مورد نظر برای Full Bundle
    var allExtensions: Set<String> = [
        ".swift", ".h", ".m", ".mm",
        ".json", ".plist", ".yaml", ".yml",
        ".md", ".txt", ".sh",
        ".html", ".css", ".js", ".ts", ".tsx"
    ]
    
    /// پسوندهای Full اضافه (کاربر)
    var customAllExtensions: Set<String> = []
    
    /// پسوندهای Config
    var configPatterns: [String] = [
        "Package.swift",
        "*.xcconfig",
        "*.plist",
        "*.entitlements",
        "project.pbxproj",
        "Podfile",
        "Cartfile",
        ".gitignore",
        ".swiftlint.yml",
        ".swiftformat",
        "Makefile",
        "Dockerfile",
        "docker-compose*.yml"
    ]
    
    // MARK: - Skip Patterns
    
    /// پوشه‌هایی که باید نادیده گرفته شوند
    var skipDirectories: Set<String> = [
        "node_modules", ".git", ".build", "Build",
        "DerivedData", "Pods", "Carthage",
        ".swiftpm", "xcuserdata",
        "__pycache__", "venv", ".venv",
        ".idea", ".vscode", ".cache",
        "dist", "build", ".next", ".turbo",
        ".output", "coverage", "tmp"
    ]
    
    /// پوشه‌های اضافه برای نادیده گرفتن (کاربر)
    var customSkipDirectories: Set<String> = []
    
    /// فایل‌هایی که باید نادیده گرفته شوند
    var skipFiles: Set<String> = [
        ".DS_Store", "Thumbs.db",
        "Package.resolved",
        "Podfile.lock", "Cartfile.resolved",
        "*.xcuserstate"
    ]
    
    /// فایل‌های اضافه برای نادیده گرفتن (کاربر)
    var customSkipFiles: Set<String> = []
    
    /// الگوهای test/spec که باید skip شوند
    var skipTestPatterns: [String] = [
        "*Tests.swift", "*Test.swift",
        "*Spec.swift", "*.spec.*",
        "*_test.swift", "*_tests.swift"
    ]
    
    // MARK: - Output Options
    
    /// تولید فایل Markdown
    var generateMarkdown: Bool = true
    
    /// تولید فایل TXT
    var generateTxt: Bool = true
    
    /// تولید فایل Tree
    var generateTree: Bool = true
    
    /// تولید فایل مسیرها
    var generatePaths: Bool = true
    
    /// تولید فایل Configs
    var generateConfigs: Bool = true
    
    /// ایجاد فایل ZIP
    var createZip: Bool = true
    
    /// حداکثر سایز فایل برای include کردن محتوا (KB)
    var maxFileSizeKB: Int = 1024
    
    /// include کردن hidden files
    var includeHidden: Bool = false
    
    // MARK: - Naming
    
    /// استفاده از تاریخ شمسی برای نام‌گذاری
    var useJalaliDate: Bool = true
    
    /// پیشوند نام پوشه backup
    var backupPrefix: String = "Backup"
    
    /// یادداشت/کامنت برای این backup
    var backupNote: String = ""
}

// MARK: - Default Presets

extension BackupConfiguration {
    /// پیکربندی پیش‌فرض برای پروژه‌های Swift/iOS
    static var swiftDefault: BackupConfiguration {
        BackupConfiguration()
    }
    
    /// پیکربندی برای پروژه‌های TypeScript/Node
    static var typescriptDefault: BackupConfiguration {
        var config = BackupConfiguration()
        config.codeExtensions = [".ts", ".tsx", ".js", ".jsx"]
        config.allExtensions = [
            ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs",
            ".json", ".yaml", ".yml", ".md", ".html", ".css", ".scss"
        ]
        config.configPatterns = [
            "package.json", "tsconfig*.json", "*.config.*",
            "next.config.*", "vite.config.*", "webpack.config.*",
            ".eslintrc.*", ".prettierrc*", "jest.config.*",
            "nx.json", "turbo.json", "pnpm-workspace.yaml"
        ]
        return config
    }
    
    /// پیکربندی ساده (فقط کد Swift)
    static var minimal: BackupConfiguration {
        var config = BackupConfiguration()
        config.generateTxt = false
        config.generatePaths = false
        config.generateConfigs = false
        config.createZip = false
        return config
    }
}

// MARK: - Persistence

extension BackupConfiguration {
    private static let userDefaultsKey = "backup.configuration"
    
    /// ذخیره تنظیمات در UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
    
    /// بارگذاری تنظیمات از UserDefaults
    static func load() -> BackupConfiguration {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let config = try? JSONDecoder().decode(BackupConfiguration.self, from: data) else {
            return .swiftDefault
        }
        return config
    }
}
