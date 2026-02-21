import SwiftUI

enum SyntaxHighlighter {

    // MARK: - Colors (adaptive dark/light)

    private static let keyword = Color(hex: "#FF7B72")      // red-ish
    private static let string = Color(hex: "#A5D6FF")        // light blue
    private static let comment = Color(hex: "#8B949E")       // gray
    private static let number = Color(hex: "#79C0FF")        // blue
    private static let type = Color(hex: "#FFA657")          // orange
    private static let function = Color(hex: "#D2A8FF")      // purple
    private static let plain = Color.primary

    // MARK: - Public API

    static func highlight(_ code: String, fileExtension ext: String) -> AttributedString {
        let lang = languageGroup(for: ext)
        var result = AttributedString(code)
        result.font = .system(.caption, design: .monospaced)
        result.foregroundColor = plain

        guard lang != .unknown else { return result }

        // Apply rules in order: comments first (lowest priority visually applied last would override,
        // but we apply from broadest to most specific — later rules override earlier)
        applyPatterns(to: &result, code: code, lang: lang)

        return result
    }

    // MARK: - Language Classification

    private enum Lang {
        case swift, python, javascript, go, rust, ruby, java, cLike, shell, yaml, dockerfile, sql, unknown
    }

    private static func languageGroup(for ext: String) -> Lang {
        switch ext {
        case "swift": return .swift
        case "py", "pyw": return .python
        case "js", "jsx", "ts", "tsx", "mjs", "cjs": return .javascript
        case "go": return .go
        case "rs": return .rust
        case "rb": return .ruby
        case "java", "kt", "kts", "scala": return .java
        case "c", "h", "cpp", "cc", "cxx", "hpp", "cs", "m", "mm": return .cLike
        case "sh", "bash", "zsh", "fish": return .shell
        case "yml", "yaml": return .yaml
        case "dockerfile": return .dockerfile
        case "sql": return .sql
        default: return .unknown
        }
    }

    // MARK: - Pattern Application

    private static func applyPatterns(to result: inout AttributedString, code: String, lang: Lang) {
        // 1) Strings (double-quoted and single-quoted)
        applyRegex(to: &result, code: code, pattern: #""[^"\\]*(?:\\.[^"\\]*)*""#, color: string)
        applyRegex(to: &result, code: code, pattern: #"'[^'\\]*(?:\\.[^'\\]*)*'"#, color: string)

        // 2) Numbers
        applyRegex(to: &result, code: code, pattern: #"\b\d+\.?\d*\b"#, color: number)

        // 3) Keywords (language-specific)
        let kws = keywords(for: lang)
        if !kws.isEmpty {
            let kwPattern = "\\b(" + kws.joined(separator: "|") + ")\\b"
            applyRegex(to: &result, code: code, pattern: kwPattern, color: keyword)
        }

        // 4) Types (capitalized words)
        applyRegex(to: &result, code: code, pattern: #"\b[A-Z][A-Za-z0-9_]+\b"#, color: type)

        // 5) Function calls
        applyRegex(to: &result, code: code, pattern: #"\b[a-zA-Z_]\w*(?=\s*\()"#, color: function)

        // 6) Comments (applied last to override everything)
        switch lang {
        case .python, .shell, .ruby, .yaml, .dockerfile:
            applyRegex(to: &result, code: code, pattern: #"#[^\n]*"#, color: comment)
        case .sql:
            applyRegex(to: &result, code: code, pattern: #"--[^\n]*"#, color: comment)
        default:
            applyRegex(to: &result, code: code, pattern: #"//[^\n]*"#, color: comment)
        }
        // Block comments for C-like languages
        if [.swift, .javascript, .go, .rust, .java, .cLike, .sql].contains(lang) {
            applyRegex(to: &result, code: code, pattern: #"/\*[\s\S]*?\*/"#, color: comment)
        }
    }

    private static func keywords(for lang: Lang) -> [String] {
        switch lang {
        case .swift:
            return ["import", "func", "var", "let", "class", "struct", "enum", "protocol", "extension",
                    "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
                    "return", "throw", "throws", "try", "catch", "async", "await", "self", "Self",
                    "true", "false", "nil", "private", "public", "internal", "static", "override",
                    "init", "deinit", "some", "any", "where", "in", "as", "is", "typealias"]
        case .python:
            return ["def", "class", "import", "from", "if", "elif", "else", "for", "while",
                    "return", "yield", "try", "except", "finally", "with", "as", "raise",
                    "pass", "break", "continue", "and", "or", "not", "in", "is", "lambda",
                    "True", "False", "None", "self", "async", "await", "print"]
        case .javascript:
            return ["function", "const", "let", "var", "class", "extends", "import", "export",
                    "from", "if", "else", "for", "while", "do", "switch", "case", "default",
                    "return", "throw", "try", "catch", "finally", "new", "this", "super",
                    "async", "await", "yield", "typeof", "instanceof", "true", "false", "null",
                    "undefined", "of", "in", "interface", "type", "enum", "implements"]
        case .go:
            return ["func", "package", "import", "var", "const", "type", "struct", "interface",
                    "if", "else", "for", "range", "switch", "case", "default", "return", "go",
                    "defer", "select", "chan", "map", "make", "new", "append", "len", "cap",
                    "true", "false", "nil", "break", "continue", "fallthrough"]
        case .rust:
            return ["fn", "let", "mut", "const", "struct", "enum", "impl", "trait", "use",
                    "mod", "pub", "crate", "self", "super", "if", "else", "match", "for",
                    "while", "loop", "return", "break", "continue", "where", "as", "in",
                    "true", "false", "Some", "None", "Ok", "Err", "async", "await", "move"]
        case .ruby:
            return ["def", "class", "module", "if", "elsif", "else", "unless", "case", "when",
                    "while", "until", "for", "do", "end", "return", "yield", "begin", "rescue",
                    "ensure", "raise", "require", "include", "attr_accessor", "attr_reader",
                    "true", "false", "nil", "self", "puts", "print"]
        case .java:
            return ["class", "interface", "enum", "extends", "implements", "import", "package",
                    "public", "private", "protected", "static", "final", "abstract", "void",
                    "int", "long", "double", "float", "boolean", "char", "byte", "short",
                    "if", "else", "for", "while", "do", "switch", "case", "default",
                    "return", "throw", "throws", "try", "catch", "finally", "new", "this",
                    "super", "true", "false", "null", "instanceof", "synchronized", "override"]
        case .cLike:
            return ["include", "define", "ifdef", "ifndef", "endif", "pragma",
                    "int", "long", "double", "float", "char", "void", "bool", "auto",
                    "struct", "enum", "union", "typedef", "const", "static", "extern",
                    "if", "else", "for", "while", "do", "switch", "case", "default",
                    "return", "break", "continue", "sizeof", "true", "false", "NULL",
                    "class", "public", "private", "protected", "virtual", "override",
                    "new", "delete", "this", "namespace", "using", "template", "typename"]
        case .shell:
            return ["if", "then", "else", "elif", "fi", "for", "while", "do", "done",
                    "case", "esac", "function", "return", "exit", "echo", "export",
                    "source", "local", "readonly", "set", "unset", "shift", "true", "false"]
        case .yaml:
            return ["true", "false", "null", "yes", "no", "on", "off"]
        case .dockerfile:
            return ["FROM", "RUN", "CMD", "ENTRYPOINT", "COPY", "ADD", "WORKDIR", "ENV",
                    "EXPOSE", "VOLUME", "USER", "ARG", "LABEL", "HEALTHCHECK", "SHELL",
                    "ONBUILD", "STOPSIGNAL", "MAINTAINER", "AS"]
        case .sql:
            return ["SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET",
                    "DELETE", "CREATE", "TABLE", "DROP", "ALTER", "INDEX", "JOIN", "LEFT",
                    "RIGHT", "INNER", "OUTER", "ON", "AND", "OR", "NOT", "NULL", "AS",
                    "ORDER", "BY", "GROUP", "HAVING", "LIMIT", "OFFSET", "DISTINCT",
                    "COUNT", "SUM", "AVG", "MIN", "MAX", "LIKE", "IN", "BETWEEN",
                    "EXISTS", "UNION", "ALL", "PRIMARY", "KEY", "FOREIGN", "REFERENCES",
                    "CASCADE", "CONSTRAINT", "DEFAULT", "CHECK", "UNIQUE", "GRANT"]
        case .unknown:
            return []
        }
    }

    // MARK: - Regex Helper

    private static func applyRegex(to result: inout AttributedString, code: String, pattern: String, color: Color) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let nsRange = NSRange(code.startIndex..., in: code)
        let matches = regex.matches(in: code, range: nsRange)

        for match in matches {
            guard let swiftRange = Range(match.range, in: code) else { continue }
            // Convert String range to AttributedString range
            let startOffset = code.distance(from: code.startIndex, to: swiftRange.lowerBound)
            let endOffset = code.distance(from: code.startIndex, to: swiftRange.upperBound)

            let attrStart = result.index(result.startIndex, offsetByCharacters: startOffset)
            let attrEnd = result.index(result.startIndex, offsetByCharacters: endOffset)

            result[attrStart..<attrEnd].foregroundColor = color
        }
    }
}
