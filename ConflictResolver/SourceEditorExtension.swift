//
//  SourceEditorExtension.swift
//  MergePlugin
//
//  Created by Jinxing Liao on 08/03/2018.
//  Copyright © 2018 Plugin. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {

    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return MergeCommand.allCases.map({ mergeCommand in
            return [
                XCSourceEditorCommandDefinitionKey.nameKey: mergeCommand.title,
                XCSourceEditorCommandDefinitionKey.classNameKey: SourceEditorCommand.className(),
                XCSourceEditorCommandDefinitionKey.identifierKey: mergeCommand.identifier
            ]
        })
    }
}

