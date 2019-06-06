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
            .objects(at: indexSet) as? [String],
            selectedLines.count > 0  else { return }
        
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
            .objects(at: indexSet) as? [String],
            selectedLines.count > 0 else { return }
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
    
    /// block comment
    internal static func blockComment(with invocation: XCSourceEditorCommandInvocation,
                                      at range: Range<Int>) {
        
        NSLog("wujie debu \(range.lowerBound) \(range.upperBound)")
        var hasStart = false
        var start = range.lowerBound
        repeat {
            guard let line = invocation.buffer.lines[start] as? String,
                line.contains("/*") else {
                start -= 1
                continue
            }
            hasStart = true
            break
        } while start >= 0
        
        var hasEnd = false
        var end = range.upperBound
        repeat {
            guard let line = invocation.buffer.lines[end - 1] as? String,
                line.contains("*/") else {
                    end += 1
                    continue
            }
            hasEnd = true
            break
        } while end < invocation.buffer.lines.count
        
        NSLog("wujie debug \(hasStart) \(start) \(hasEnd) \(end)")
        
        if hasStart && hasEnd {
            // uncomment lines
            let startLine = (invocation.buffer.lines[start] as! String).replacingOccurrences(of: "/*", with: "")
            if startLine.count == 0 {
                invocation.buffer.lines.removeObject(at: start)
            } else {
                invocation.buffer.lines[start] = startLine
            }
            
            let endLine = (invocation.buffer.lines[end] as! String).replacingOccurrences(of: "*/", with: "")
            if endLine.count == 0 {
                invocation.buffer.lines.removeObject(at: end)
            } else {
                invocation.buffer.lines[end] = endLine
            }
            NSLog("wujie debug delete \(start) \(end) \(invocation.buffer.lines)")
        } else {
            // comment lines
            start = range.lowerBound
            end = range.upperBound
            invocation.buffer.lines.insert("/*", at: start)
            invocation.buffer.lines.insert("*/", at: end + 1)
            
            let startPosition = XCSourceTextPosition(line: end + 1, column: 0)
            let endPosition = XCSourceTextPosition(line: end + 1, column: 2)
            invocation.buffer.selections.add(XCSourceTextRange(start: startPosition, end: endPosition))
            NSLog("wujie debug \(start) \(end) \(invocation.buffer.lines)")
        }
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
