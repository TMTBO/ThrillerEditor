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
        
        func _convertFromSelection(with invocation: XCSourceEditorCommandInvocation,
                                   at textRange: XCSourceTextRange) -> Bool {
            
            // from selection
            // get selected string
            let lineRange = Range(uncheckedBounds: (textRange.start.line, min(textRange.end.line + 1, invocation.buffer.lines.count)))
            let indexSet = IndexSet(integersIn: lineRange)
            guard var selectedLines = invocation
                .buffer
                .lines
                .objects(at: indexSet) as? [String] else { return false }
            
            // get first and last to correct column
            let firstString = selectedLines.first ?? ""
            let lastString = selectedLines.last ?? ""
            let firstLine = String(firstString.dropFirst(max(textRange.start.column, 0)))
            let lastLine = String(lastString.dropLast(max(lastString.count - textRange.end.column, 0)))
            
            // get json string
            selectedLines[0] = firstLine
            selectedLines[selectedLines.count - 1] = lastLine
            let selectedString = selectedLines.joined().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // convert to collection object
            guard let selectedData = selectedString.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: selectedData, options: [.mutableContainers, .mutableLeaves]) else { return false }
            
            // convert to model
            if let dict = obj as? Dictionary<NSString, AnyObject> {
                let insertLine = invocation.buffer.lines.count
                
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
                
                // select lines
                let start = XCSourceTextPosition(line: insertLine, column: 0)
                let end = XCSourceTextPosition(line: invocation.buffer.lines.count, column: 0)
                let range = XCSourceTextRange(start: start, end: end)
                LinesController.selectLines(with: invocation, range: range)
                return true
            } else if let array = obj as? Array<Any> {
                // warning must be a dictionary
                return true
            }
            
            return false
        }
        
        // from selection
        // get selected string
        if _convertFromSelection(with: invocation, at: textRange) { return }
        
        
        // from pasteboard
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
