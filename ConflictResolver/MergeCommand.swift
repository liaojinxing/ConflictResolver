//
//  MergeCommand.swift
//  MergePlugin
//
//  Created by Jinxing Liao on 08/03/2018.
//  Copyright © 2018 Plugin. All rights reserved.
//

import Foundation

enum MergeCommand: Int {
    case acceptTheirs = 1
    case acceptYours
    case keepBoth
    case jumpToNextConflict

    var title: String {
        switch self {
        case .acceptTheirs:
            return "Accept Theirs"
        case .acceptYours:
            return "Accept Yours"
        case .keepBoth:
            return "Keep Both"
        case .jumpToNextConflict:
            return "Jump to Next Conflict"
        }
    }

    static var allCases: [MergeCommand] {
        var values: [MergeCommand] = []
        var index = 1
        while let element = self.init(rawValue: index) {
            values.append(element)
            index += 1
        }
        return values
    }

    var identifier: String {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        return "\(bundleID).\(title)".replacingOccurrences(of: " ", with: "-")
    }

    static func from(identifier: String) -> MergeCommand? {
        let acceptTheirsIdentifier = MergeCommand.acceptTheirs.identifier
        let acceptYoursIdentifier = MergeCommand.acceptYours.identifier
        let keepBothIdentifier = MergeCommand.keepBoth.identifier
        let jumpToNextIdentifier = MergeCommand.jumpToNextConflict.identifier

        switch identifier {
        case acceptTheirsIdentifier:
            return .acceptTheirs
        case acceptYoursIdentifier:
            return .acceptYours
        case keepBothIdentifier:
            return .keepBoth
        case jumpToNextIdentifier:
            return .jumpToNextConflict
        default:
            return nil
        }
    }
}

