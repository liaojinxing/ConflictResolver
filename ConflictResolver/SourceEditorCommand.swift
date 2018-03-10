//
//  SourceEditorCommand.swift
//  MergePlugin
//
//  Created by Jinxing Liao on 08/03/2018.
//  Copyright © 2018 Plugin. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

    private enum ConflictStringConstant {
        static let head = "<<<<<<<"
        static let commonAncestors = "|||||||"
        static let commonSeparator = "======="
        static let voyagerEnd = ">>>>>>>"
    }

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        let identifer = invocation.commandIdentifier
        guard let mergeCommand = MergeCommand.from(identifier: identifer) else {
            completionHandler(nil)
            return
        }

        let lines = invocation.buffer.lines as! [String]
        let optionalselectedFirstLineIndex = (invocation.buffer.selections.firstObject as? XCSourceTextRange)?.start.line
        if mergeCommand == .jumpToNextConflict {
            let (nextHeadIndex, nextEndIndex) = nextConflictHeadIndex(from: optionalselectedFirstLineIndex ?? 0, lines: lines)
            if nextHeadIndex != NSNotFound, nextEndIndex != NSNotFound {
                let start = XCSourceTextPosition(line: nextHeadIndex, column: 0)
                let end = XCSourceTextPosition(line: nextEndIndex + 1, column: 0)
                let textRange = XCSourceTextRange(start: start, end: end)
                invocation.buffer.selections.removeAllObjects()
                invocation.buffer.selections.add(textRange)
            }
            completionHandler(nil)
            return
        }

        guard let selectedFirstLineIndex = optionalselectedFirstLineIndex else {
            completionHandler(nil)
            return
        }

        guard conflictExisted(selectedLineIndex: selectedFirstLineIndex, lines: lines) else {
            completionHandler(nil)
            return
        }

        let (headIndex, commonAncestorIndex, commonSeparatorIndex, voyagerEndIndex) = getSeparatorIndices(from: selectedFirstLineIndex, lines: lines)

        guard headIndex != NSNotFound, commonSeparatorIndex != NSNotFound, voyagerEndIndex != NSNotFound else {
            completionHandler(nil)
            return
        }

        if commonAncestorIndex != NSNotFound {
            // diff3 conflict style
            switch mergeCommand {
            case .acceptYours:
                let indexSet = IndexSet(integersIn: commonAncestorIndex...voyagerEndIndex)
                invocation.buffer.lines.removeObjects(at: indexSet)
                invocation.buffer.lines.removeObject(at: headIndex)
            case .acceptTheirs:
                invocation.buffer.lines.removeObject(at: voyagerEndIndex)
                let indexSet = IndexSet(integersIn: headIndex...commonSeparatorIndex)
                invocation.buffer.lines.removeObjects(at: indexSet)
            case .keepBoth:
                invocation.buffer.lines.removeObject(at: voyagerEndIndex)
                let indexSet = IndexSet(integersIn: commonAncestorIndex...commonSeparatorIndex)
                invocation.buffer.lines.removeObjects(at: indexSet)
                invocation.buffer.lines.removeObject(at: headIndex)
            default:
                break
            }
        } else {
            switch mergeCommand {
            case .acceptYours:
                let indexSet = IndexSet(integersIn: commonSeparatorIndex...voyagerEndIndex)
                invocation.buffer.lines.removeObjects(at: indexSet)
                invocation.buffer.lines.removeObject(at: headIndex)
            case .acceptTheirs:
                invocation.buffer.lines.removeObject(at: voyagerEndIndex)
                let indexSet = IndexSet(integersIn: headIndex...commonSeparatorIndex)
                invocation.buffer.lines.removeObjects(at: indexSet)
            case .keepBoth:
                invocation.buffer.lines.removeObject(at: voyagerEndIndex)
                invocation.buffer.lines.removeObject(at: commonSeparatorIndex)
                invocation.buffer.lines.removeObject(at: headIndex)
            default:
                break
            }
        }
        completionHandler(nil)
    }

    private func conflictExisted(selectedLineIndex: Int, lines: [String]) -> Bool {
        for i in selectedLineIndex ..< lines.count {
            let line = lines[i]
            if line.starts(with: ConflictStringConstant.voyagerEnd) {
                return true
            }
        }
        return false
    }

    private func getSeparatorIndices(from selectedLineIndex: Int, lines: [String]) -> (Int, Int, Int, Int) {
        var headIndex = NSNotFound
        var commonAncestorIndex: Int = NSNotFound
        var commonSeparatorIndex: Int = NSNotFound
        var voyagerEndIndex: Int = NSNotFound

        for i in (0 ... selectedLineIndex).reversed() {
            let line = lines[i]
            if line.starts(with: ConflictStringConstant.head) {
                headIndex = i
                break
            }
        }
        if headIndex == NSNotFound {
            return (NSNotFound, NSNotFound, NSNotFound, NSNotFound)
        }

        for i in headIndex ..< lines.count {
            let line = lines[i]
            if line.starts(with: ConflictStringConstant.commonAncestors) {
                commonAncestorIndex = i
            }
            if line.starts(with: ConflictStringConstant.commonSeparator) {
                commonSeparatorIndex = i
            }
            if line.starts(with: ConflictStringConstant.voyagerEnd) {
                voyagerEndIndex = i
                break
            }
        }
        return (headIndex, commonAncestorIndex, commonSeparatorIndex, voyagerEndIndex)
    }

    private func nextConflictHeadIndex(from selectedLine: Int, lines: [String]) -> (Int, Int) {
        guard selectedLine > 0, selectedLine < lines.count - 1 else {
            return (NSNotFound, NSNotFound)
        }

        var headIndex = NSNotFound
        var endIndex = NSNotFound

        for i in selectedLine + 1 ..< lines.count {
            if lines[i].starts(with: ConflictStringConstant.head) {
                headIndex = i
            }
            if lines[i].starts(with: ConflictStringConstant.voyagerEnd) {
                endIndex = i
                return (headIndex, endIndex)
            }
        }
        for i in 0 ..< selectedLine {
            if lines[i].starts(with: ConflictStringConstant.head) {
                headIndex = i
            }
            if lines[i].starts(with: ConflictStringConstant.voyagerEnd) {
                endIndex = i
                return (headIndex, endIndex)
            }
        }
        return (NSNotFound, NSNotFound)
    }
}

