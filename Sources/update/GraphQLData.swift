// Copyright 2020-2021 Dave Verwer, Sven A. Schmidt, and other contributors.
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

struct SponsorQueryResults: Codable {
    let data: Data

    struct Data: Codable {
        let organization: Organization
    }

    struct Organization: Codable {
        let sponsorshipsAsMaintainer: SponsorshipsAsMaintainer
    }

    struct SponsorshipsAsMaintainer: Codable {
        let pageInfo: PageInfo
        let nodes: [Node]
    }

    struct PageInfo: Codable {
        let hasNextPage: Bool
        let endCursor: String
    }

    struct Node: Codable {
        let sponsorEntity: SponsorEntity
    }

    struct SponsorEntity: Codable {
        let login: String?
        let name: String?
        let username: String?
        let avatarUrl: String?

        var nameOrNil: String {
            if let name = name {
                return "\"\(name)\""
            } else {
                return "nil"
            }
        }
    }
}
