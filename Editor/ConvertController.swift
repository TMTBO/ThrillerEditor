//
//  ConvertController.swift
//  Editor
//
//  Created by Thriller on 2019/6/2.
//  Copyright © 2019 Thriller. All rights reserved.
//

import XcodeKit
import AppKit

/// Convert Code
struct ConvertController {
    
    enum Const: String {
        case className = "<#ClassName#>";
        case classDictMehtod = "+ (instancetype)<#className#>WithDict:(NSDictionary *)dict";
        case instanceDictMethod = "- (instancetype)initWithDict:(NSDictionary *)dict";
    }
    
    /// convert json to model
    internal static func convertJson(with invocation: XCSourceEditorCommandInvocation,
                                     at textRange: XCSourceTextRange) {
        
        /// handle json string
        func _handleJsonString(with invocation: XCSourceEditorCommandInvocation,
                               json: String) -> Bool {
            let jsonString = json.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // convert to collection object
            guard let jsonData = jsonString.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: jsonData, options: [.mutableContainers, .mutableLeaves]) else { return false }
            let insertLine = invocation.buffer.lines.count
            var handled = false
            
            // convert to model
            if let dict = obj as? Dictionary<NSString, AnyObject> {
                // class interface
                var interfaceString = "\n@interface \(Const.className.rawValue) : NSObject\n\n"
                // properties
                interfaceString = dict.reduce(interfaceString) { (result, item) -> String in
                    return result.appending(_generateProperty(key: item.key, value: item.value))
                }
                // methods
                interfaceString.append("\n\(Const.classDictMehtod.rawValue);\n\n\(Const.instanceDictMethod.rawValue);\n")
                // class end
                interfaceString.append("\n@end")
                // insert class
                invocation.buffer.lines.insert(interfaceString, at: insertLine)
                
                // handled
                handled = true
            } else if obj is Array<Any> {
                // warning
                let warning = "\n+-------------------------------------------------+\n|    WARNING: The selected must be `Dictionary`   +\n+-------------------------------------------------+\n"
                // insert
                invocation.buffer.lines.insert(warning, at: insertLine)
                
                // handled
                handled = true
            }
            
            // select lines
            let start = XCSourceTextPosition(line: insertLine, column: 0)
            let end = XCSourceTextPosition(line: invocation.buffer.lines.count, column: 0)
            let range = XCSourceTextRange(start: start, end: end)
            LinesController.selectLines(with: invocation, range: range)
            
            return handled
        }
        
        /// convert from selection
        func _convertFromSelection(with invocation: XCSourceEditorCommandInvocation,
                                   at textRange: XCSourceTextRange) -> Bool {
            
            // get selected string
            let lineRange = Range(uncheckedBounds: (textRange.start.line, min(textRange.end.line + 1, invocation.buffer.lines.count)))
            let indexSet = IndexSet(integersIn: lineRange)
            guard var selectedLines = invocation
                .buffer
                .lines
                .objects(at: indexSet) as? [String],
                selectedLines.count > 0 else { return false }
            
            // get first and last to correct column
            let firstString = selectedLines.first ?? ""
            let lastString = selectedLines.last ?? ""
            let firstLine = String(firstString.dropFirst(max(textRange.start.column, 0)))
            let lastLine = String(lastString.dropLast(max(lastString.count - textRange.end.column, 0)))
            
            // get json string
            selectedLines[0] = firstLine
            selectedLines[selectedLines.count - 1] = lastLine
            let selectedString = selectedLines.joined()
            
            // handle json
            return _handleJsonString(with: invocation, json: selectedString)
        }
        
        /// convert form pasteboard
        func _convertFromPasteboard(with invocation: XCSourceEditorCommandInvocation,
                                    at textRange: XCSourceTextRange) -> Bool {
            
            // get copied string
            guard let copiedString = NSPasteboard.general.string(forType: .string) else {
                    return false
            }
            
            // handle json
            return _handleJsonString(with: invocation, json: copiedString)
        }
        
        // from selection
        if _convertFromSelection(with: invocation, at: textRange) { return }
        
        // from pasteboard
        if _convertFromPasteboard(with: invocation, at: textRange) { return }
    }
    
    /// convert protobuf to model
    internal static func convertProtobuf(with invocation: XCSourceEditorCommandInvocation,
                                         at textRange: XCSourceTextRange) {
        
        // get selected lines
        let lineRange = Range(uncheckedBounds: (textRange.start.line, min(textRange.end.line + 1, invocation.buffer.lines.count)))
        let indexSet = IndexSet(integersIn: lineRange)
        guard let selectedLines = invocation
            .buffer
            .lines
            .objects(at: indexSet) as? [String],
            selectedLines.count > 0 else { return }
        
        let insertLine = invocation.buffer.lines.count
        
        // get class name
        guard let filteredClassName = selectedLines.filter({ $0.hasPrefix("@interface") }).first,
            filteredClassName.count > 0,
            let range = filteredClassName.range(of: "@interface +\\S+ +: +PBGeneratedMessage",
                                                options: .regularExpression,
                                                range: Range(uncheckedBounds: (filteredClassName.startIndex, filteredClassName.endIndex)),
                                                locale: nil) else { return }
        let className = filteredClassName[range]
        
        // class interface
        var interfaceString = "\n@interface \(className) : NSObject\n\n"
        
        // class end
        interfaceString.append("\n@end")
        
        invocation.buffer.lines.insert(interfaceString, at: insertLine)
        
    }
}

extension ConvertController {
    
    enum PropertyType: String {
        case NSString = "NSString *";
        case NSArray = "NSArray *";
        case NSDictioary = "NSDictionary *";
        case NSInteger = "NSInteger "
        case CGFloat = "CGFloat ";
        case BOOL = "BOOL ";
    }
    
    enum MemonryControl: String {
        case copy, assign, strong;
    }
    
    /// generate property
    internal static func _generateProperty(key: NSString, value: AnyObject) -> String {
        
        let type = _typeString(key: key, value: value)
        let memonryControl = _memonryControl(with: type)
        let property = String(format: "@property (nonatomic, %@) %@%@;\n", memonryControl, type, key)
        return property
    }
    
    /// memonry control for type
    internal static func _memonryControl(with type: String) -> String {
        
        guard let propertyType = PropertyType(rawValue: type) else { return MemonryControl.strong.rawValue }
        
        switch propertyType {
        case .NSString, .NSArray, .NSDictioary:
            return MemonryControl.copy.rawValue
        case .NSInteger, .CGFloat, .BOOL:
            return MemonryControl.assign.rawValue
        }
    }
    
    /// type for item
    internal static func _typeString(key: NSString, value: AnyObject) -> String {
        
        var className = value.className ?? Const.className.rawValue
        if className.lowercased().contains("number") {
            let number = (value as? NSNumber)?.doubleValue ?? 0
            if number == round(number) {
                // equal to int value is integer
                return PropertyType.NSInteger.rawValue
            } else {
                // otherwise is double
                return PropertyType.CGFloat.rawValue
            }
        } else if className.lowercased().contains("bool") {
            return PropertyType.BOOL.rawValue
        } else if className.lowercased().contains("string") {
            return PropertyType.NSString.rawValue
        } else if className.lowercased().contains("array") {
            return PropertyType.NSArray.rawValue
        } else if className.lowercased().contains("dictionary") {
            return PropertyType.NSDictioary.rawValue
        } else {
            className.append(" *")
        }
        return className
    }
}
