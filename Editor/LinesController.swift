//
//  LinesController.swift
//  Editor
//
//  Created by Thriller on 2019/6/2.
//  Copyright © 2019 Thriller. All rights reserved.
//

import XcodeKit
import AppKit

/// Handle Lines
struct LinesController {
    
    /// delete selected lines
    internal static func deleteLines(with invocation: XCSourceEditorCommandInvocation,
                                     at range: Range<Int>) {
        // copy
        copyLines(with: invocation, at: range)
        
        // delete
        let indexSet = IndexSet(integersIn: range)
        invocation.buffer.lines.removeObjects(at: indexSet)
        
        // reset selection
        resetSelections(with: invocation, at: range.lowerBound)
    }
    
    /// duplicate selected lines
    internal static func duplicateLines(with invocation: XCSourceEditorCommandInvocation,
                                        at range: Range<Int>) {
        
        // get selected lines
        let indexSet = IndexSet(integersIn: range)
        guard let selectedLines = invocation
            .buffer
            .lines
            .objects(at: indexSet) as? [String] else { return }
        
        // insert lines
        invocation.buffer.lines.insert(selectedLines, at: indexSet)
        
        // select lines
        let start = XCSourceTextPosition(line: range.lowerBound + range.count, column: 0)
        let end = XCSourceTextPosition(line: range.upperBound + range.count - 1,
                                       column: (selectedLines.last?.count ?? 1) - 1)
        let range = XCSourceTextRange(start: start, end: end)
        selectLines(with: invocation, range: range)
    }
    
    /// copy selected lines
    internal static func copyLines(with invocation: XCSourceEditorCommandInvocation,
                                   at range: Range<Int>) {
        
        // get selected string
        let indexSet = IndexSet(integersIn: range)
        guard let selectedLines = invocation
            .buffer
            .lines
            .objects(at: indexSet) as? [String] else { return }
        let selectedString = selectedLines.joined().dropLast()
        
        // copy
        let pastboard = NSPasteboard.general
        pastboard.declareTypes([.string], owner: nil)
        pastboard.setString(String(selectedString), forType: .string)
        
        // select lines
        let startPosition = XCSourceTextPosition(line: range.lowerBound, column: 0)
        let endPosition = XCSourceTextPosition(line: range.upperBound - 1,
                                               column: (selectedLines.last?.count ?? 1) - 1)
        let range = XCSourceTextRange(start: startPosition, end: endPosition)
        selectLines(with: invocation, range: range)
    }
    
    /// reset the selection at the begining of the selections
    internal static func resetSelections(with invocation: XCSourceEditorCommandInvocation,
                                         at line: Int) {
        
        // get range
        let position = XCSourceTextPosition(line: line - 1, column: 0)
        let range = XCSourceTextRange(start: position, end: position)
        
        // select lines
        selectLines(with: invocation, range: range)
    }
    
    /// select at range
    internal static func selectLines(with invocation: XCSourceEditorCommandInvocation,
                                     range: XCSourceTextRange) {
        
        // remove selection
        invocation.buffer.selections.removeAllObjects()
        
        // select at range
        invocation.buffer.selections.add(range)
    }
}
