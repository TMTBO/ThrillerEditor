//
//  EditorController.swift
//  Editor
//
//  Created by Thriller on 2019/6/1.
//  Copyright © 2019 Thriller. All rights reserved.
//

import XcodeKit
import AppKit

struct EditorController {
    
    enum EditorCommandIdentifier: String {
        case deleteLines = "Thriller.Editor.DeleteLines";
        case duplicateLines = "Thriller.Editor.DuplicateLines";
        case copyLines = "Thriller.Editor.CopyLines";
        case convertJson = "Thriller.Editor.ConvertJsonToModel";
        case convertProtobuf = "Thriller.Editor.ConvertProtobufToModel";
        
        // TODO: - sort import <>, "", oc, swift
        // TODO: - auto import anywhere
        // TODO: - generate sel interface oc, swift
        // TODO: - generate sel imp with select codes oc, swift
        // TODO: - generate statement with select expression oc, swift
        
        // TODO: - common wapper
        // TODO: - blcok common

        // TODO: - alignment
        // TODO: - format
        
        // TODO: - need comment or not
        // TODO: - convert protobuf to model
        // TODO: - prefix support
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
            LinesController.deleteLines(with: invocation, at: range)
        case .duplicateLines:
            LinesController.duplicateLines(with: invocation, at: range)
        case .copyLines:
            LinesController.copyLines(with: invocation, at: range)
        case .convertJson:
            ConvertController.convertJson(with: invocation, at: textRange)
        case .convertProtobuf:
            ConvertController.convertProtobuf(with: invocation, at: textRange)
        }
    }
}
