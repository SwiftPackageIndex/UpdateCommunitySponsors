// Copyright Dave Verwer, Sven A. Schmidt, and other contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import ArgumentParser

@main
struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Update community sponsors.")

    @Option(name: [.customLong("token")], help: "The GitHub API token to use.")
    var gitHubToken: String

    @Option(name: [.customLong("output")], help: "The path to the SwiftPackageIndex-Server source code.")
    var outputDirectory: String

    mutating func run() async throws {
        var cursor = ""
        var sponsors: [SponsorQueryResults.SponsorEntity] = []
        while(true) {
            let chunkData = try await fetchFromGitHub(query: chunkQuery(count: 100, cursor: cursor))
            cursor = chunkData.data.organization.sponsorshipsAsMaintainer.pageInfo.endCursor
            sponsors.append(contentsOf: chunkData.data.organization.sponsorshipsAsMaintainer.nodes.map { $0.sponsorEntity })
            guard chunkData.data.organization.sponsorshipsAsMaintainer.pageInfo.hasNextPage else { break }
        }

        var output = SourceTemplate.header
        for sponsor in sponsors {
            if let login = sponsor.login, let url = sponsor.avatarUrl {
                output += "        CommunitySponsor(\n"
                output += "            login: \"\(login)\",\n"
                output += "            name: \(sponsor.nameOrNil),\n"
                output += "            avatarUrl: \"\(url)\"\n"
                output += "        ),\n"
            }
        }
        output += SourceTemplate.footer

        try output.write(toFile: pathToOutputFile(), atomically: true, encoding: .utf8)
    }

    func fetchFromGitHub(query queryData: Data) async throws -> SponsorQueryResults {
        let url = URL(string: "https://api.github.com/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("bearer \(gitHubToken)", forHTTPHeaderField: "Authorization")

        request.httpBody = queryData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<299).contains(httpResponse.statusCode)
        else { throw RuntimeError("Expected a 2xx response") }
        return try JSONDecoder().decode(SponsorQueryResults.self, from: data)
    }

    func chunkQuery(count: Int, cursor: String) throws -> Data {
        return try JSONEncoder().encode(["query": """
        {
          organization(login: "swiftpackageindex") {
            sponsorshipsAsMaintainer(first: \(count), after: \"\(cursor)\", includePrivate: false) {
              pageInfo {
                hasNextPage
                endCursor
              }
              nodes {
                sponsorEntity {
                  ... on Organization {
                    login
                    name
                    avatarUrl
                  }
                  ... on User {
                    login
                    name
                    avatarUrl
                  }
                }
              }
            }
          }
        }
        """])
    }

    func pathToOutputFile() -> String {
        outputDirectory.expandingTilde(path: "Sources/App/Core/CommunitySponsors.swift")
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String

    init(_ description: String) {
        self.description = description
    }
}

extension String {
    public func expandingTilde(path: String) -> String {
        let fullPath = NSString(string: self).appendingPathComponent(path)
        return NSString(string: fullPath).expandingTildeInPath
    }
}
