//
//  EditorController.swift
//  Editor
//
//  Created by Thriller on 2019/6/1.
//  Copyright © 2019 Thriller. All rights reserved.
//

import XcodeKit
import AppKit

class EditorController {
    
    enum EditorCommandIdentifier: String {
        case deleteLines = "Thriller.Editor.DeleteLines";
        case duplicateLines = "Thriller.Editor.DuplicateLines";
        case copyLines = "Thriller.Editor.CopyLines";
    }
    
    /// handle all editor command
    static func handle(with invocation: XCSourceEditorCommandInvocation) {
        
        // Fail fast if there is no text selected at all or there is no text in the file
        guard let textRange = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            invocation.buffer.lines.count > 0,
            let commandIdentifier = EditorCommandIdentifier(rawValue: invocation.commandIdentifier) else { return }
        
        let range = Range(uncheckedBounds: (textRange.start.line, min(textRange.end.line + 1, invocation.buffer.lines.count)))
        
        switch commandIdentifier {
        case .deleteLines:
            _deleteLines(with: invocation, at: range)
        case .duplicateLines:
            _duplicateLines(with: invocation, at: range)
        case .copyLines:
            _copyLines(with: invocation, at: range)
        }
    }
}

extension EditorController {
    
    /// delete selected lines
    private static func _deleteLines(with invocation: XCSourceEditorCommandInvocation,
                                     at range: Range<Int>) {
        // copy
        _copyLines(with: invocation, at: range)
        
        // delete
        let indexSet = IndexSet(integersIn: range)
        invocation.buffer.lines.removeObjects(at: indexSet)
        
        // reset selection
        _resetSelections(with: invocation, at: range.lowerBound)
    }
    
    /// duplicate selected lines
    private static func _duplicateLines(with invocation: XCSourceEditorCommandInvocation,
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
        _selectLines(with: invocation, range: range)
    }
    
    /// copy selected lines
    private static func _copyLines(with invocation: XCSourceEditorCommandInvocation,
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
        _selectLines(with: invocation, range: range)
    }
    
    /// reset the selection at the begining of the selections
    private static func _resetSelections(with invocation: XCSourceEditorCommandInvocation,
                                         at line: Int) {
        
        // get range
        let position = XCSourceTextPosition(line: line, column: 0)
        let range = XCSourceTextRange(start: position, end: position)
        
        // select lines
        _selectLines(with: invocation, range: range)
    }
    
    /// select at range
    private static func _selectLines(with invocation: XCSourceEditorCommandInvocation,
                                     range: XCSourceTextRange) {
        
        // remove selection
        invocation.buffer.selections.removeAllObjects()
        
        // select at range
        invocation.buffer.selections.add(range)
    }
}
