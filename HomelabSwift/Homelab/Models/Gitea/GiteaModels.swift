import Foundation

struct GiteaUser: Codable, Identifiable {
    let id: Int
    let login: String
    let full_name: String
    let email: String
    let avatar_url: String
    let created: String
}

struct GiteaRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let full_name: String
    let description: String
    let owner: GiteaRepoOwner
    let `private`: Bool
    let fork: Bool
    let stars_count: Int
    let forks_count: Int
    let open_issues_count: Int
    let open_pr_counter: Int
    let language: String
    let size: Int
    let updated_at: String
    let created_at: String
    let html_url: String
    let default_branch: String

    var isPrivate: Bool { `private` }
}

struct GiteaRepoOwner: Codable {
    let login: String
    let avatar_url: String
}

struct GiteaOrg: Codable, Identifiable {
    let id: Int
    let username: String
    let full_name: String
    let avatar_url: String
    let description: String
}

struct GiteaNotification: Codable, Identifiable {
    let id: Int
    let subject: GiteaNotificationSubject
    let repository: GiteaNotificationRepo
    let unread: Bool
    let updated_at: String
}

struct GiteaNotificationSubject: Codable {
    let title: String
    let type: String
    let url: String
}

struct GiteaNotificationRepo: Codable {
    let full_name: String
}

struct GiteaFileContent: Codable, Identifiable {
    let name: String
    let path: String
    let sha: String
    let type: GiteaFileType
    let size: Int
    let content: String?
    let encoding: String?
    let url: String
    let html_url: String
    let download_url: String?

    var id: String { sha + path }

    var isDirectory: Bool { type == .dir }
    var isFile: Bool { type == .file }

    var decodedContent: String? {
        guard let content, encoding == "base64" else { return content }
        // Clean base64 string (remove newlines)
        let cleaned = content.replacingOccurrences(of: "\n", with: "")
        guard let data = Data(base64Encoded: cleaned) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension.lowercased()
    }

    var isImage: Bool {
        ["png", "jpg", "jpeg", "gif", "webp", "svg", "ico", "bmp"].contains(fileExtension)
    }

    var isMarkdown: Bool {
        ["md", "markdown"].contains(fileExtension)
    }
}

enum GiteaFileType: String, Codable {
    case file
    case dir
    case symlink
    case submodule
}

struct GiteaCommit: Codable, Identifiable {
    let sha: String
    let url: String
    let html_url: String
    let commit: GiteaCommitData
    let author: GiteaCommitAuthorUser?

    var id: String { sha }
}

struct GiteaCommitData: Codable {
    let message: String
    let author: GiteaCommitPersonInfo
    let committer: GiteaCommitPersonInfo
}

struct GiteaCommitPersonInfo: Codable {
    let name: String
    let email: String
    let date: String
}

struct GiteaCommitAuthorUser: Codable {
    let login: String
    let avatar_url: String
}

struct GiteaIssue: Codable, Identifiable {
    let id: Int
    let number: Int
    let title: String
    let body: String
    let state: String
    let user: GiteaIssueUser
    let labels: [GiteaLabel]
    let comments: Int
    let created_at: String
    let updated_at: String
    let closed_at: String?
    let pull_request: GiteaPullRequest?

    var isOpen: Bool { state == "open" }
    var isPR: Bool { pull_request != nil }
}

struct GiteaIssueUser: Codable {
    let login: String
    let avatar_url: String
}

struct GiteaLabel: Codable, Identifiable {
    let id: Int
    let name: String
    let color: String
}

struct GiteaPullRequest: Codable {
    let merged: Bool?
    let merged_at: String?
}

struct GiteaBranch: Codable, Identifiable {
    let name: String
    let commit: GiteaBranchCommit
    let protected: Bool

    var id: String { name }
}

struct GiteaBranchCommit: Codable {
    let id: String
    let message: String
}

struct GiteaHeatmapItem: Codable, Identifiable {
    let timestamp: Int
    let contributions: Int

    var id: Int { timestamp }

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}

// MARK: - Token creation

struct GiteaTokenRequest: Codable {
    let name: String
    let scopes: [String]
}

struct GiteaTokenResponse: Codable {
    let id: Int
    let name: String
    let sha1: String
}

struct GiteaServerVersion: Codable {
    let version: String
}
