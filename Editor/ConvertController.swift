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
            if let dict = obj as? Dictionary<String, AnyObject> {
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
            guard let copiedString = NSPasteboard.general.string(forType: .string) else { return false }
            
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
        
        /// handle json string
        func _handle(with invocation: XCSourceEditorCommandInvocation,
                     lines: [String]) -> Bool {
            let insertLine = invocation.buffer.lines.count
            
            // get class name
            guard var filteredClassName = lines.filter({ $0.hasPrefix("@interface") }).first,
                filteredClassName.count > 0 else { return false }
            
            filteredClassName = filteredClassName.replacingOccurrences(of: " ", with: "")
            guard let interfaceRange = filteredClassName.range(of: "@interface"),
                let colonRange = filteredClassName.range(of: ":") else { return false }
            
            var className = String(filteredClassName[interfaceRange.upperBound..<colonRange.lowerBound])
            guard let firstChar = className.first else { return false }
            let upperChar = firstChar.uppercased()
            className = className.replacingOccurrences(of: String(firstChar), with: upperChar)
            
            // class interface
            var interfaceString = "\n@interface \(className) : NSObject\n\n"
            
            // properties
            let properties = lines
                .filter({ !$0.hasSuffix("_:1;\n")
                    && !$0.hasPrefix("@")
                    && !$0.hasPrefix("{")
                    && !$0.hasPrefix("}")
                })
                .compactMap { (line) -> String? in
                    let items =  line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
                    guard items.count == 2,
                        let type = items.first,
                        let name = items.last else { return nil }
                    let property = _generateProperty(type: type, name: name.replacingOccurrences(of: ";", with: ""))
                    return property
                }.joined()
            interfaceString.append(properties)
            
            // methods
            
            // class end
            interfaceString.append("\n@end")
            
            // insert
            invocation.buffer.lines.insert(interfaceString, at: insertLine)
            return true
        }
        
        /// convert from selection
        func _convertFromSelection(with invocation: XCSourceEditorCommandInvocation,
                                   at textRange: XCSourceTextRange) -> Bool {
            
            // get selected lines
            let lineRange = Range(uncheckedBounds: (textRange.start.line, min(textRange.end.line + 1, invocation.buffer.lines.count)))
            let indexSet = IndexSet(integersIn: lineRange)
            guard let selectedLines = invocation
                .buffer
                .lines
                .objects(at: indexSet) as? [String],
                selectedLines.count > 0 else { return false }
            
            // handle lines
            return _handle(with: invocation, lines: selectedLines)
        }
 
        /// convert form pasteboard
        func _convertFromPasteboard(with invocation: XCSourceEditorCommandInvocation,
                                    at textRange: XCSourceTextRange) -> Bool {
            // get copied string
            guard let copiedString = NSPasteboard.general.string(forType: .string) else { return false }
            
            return true
        }
        
        // from selection
        if _convertFromSelection(with: invocation, at: textRange) { return }
        
        // from pasteboard
        if _convertFromPasteboard(with: invocation, at: textRange) { return }
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
        case int = "int";
    }
    
    enum MemonryControl: String {
        case copy, assign, strong;
    }
    
    /// generate property
    internal static func _generateProperty(key: String, value: AnyObject) -> String {
        
        let type = _typeString(object: value)
        let memonryControl = _memonryControl(with: type)
        let property = String(format: "@property (nonatomic, %@) %@%@;\n", memonryControl, type, key)
        return property
    }
    
    internal static func _generateProperty(type: String, name: String) -> String {
        
        let type = _typeString(type: type)
        let memonryControl = _memonryControl(with: type)
        let property = String(format: "@property (nonatomic, %@) %@%@;\n", memonryControl, type, name)
        return property
    }
    
    /// memonry control for type
    internal static func _memonryControl(with type: String) -> String {
        
        if type.hasPrefix(PropertyType.int.rawValue) { return MemonryControl.assign.rawValue }
        
        guard let propertyType = PropertyType(rawValue: type) else { return MemonryControl.strong.rawValue }
        
        switch propertyType {
        case .NSString, .NSArray, .NSDictioary:
            return MemonryControl.copy.rawValue
        case .NSInteger, .CGFloat, .BOOL, .int:
            return MemonryControl.assign.rawValue
        }
    }
    
    /// type for type
    internal static func _typeString(type: String) -> String {
        
        if type.hasPrefix("int") { return type.appending(" ") }
        return _correctTypeString(type: type)
    }
    
    /// type for object
    internal static func _typeString(object: AnyObject) -> String {
        let type = object.className ?? Const.className.rawValue
        if type.lowercased().contains("number") {
            let number = (object as? NSNumber)?.doubleValue ?? 0
            if number == round(number) {
                // equal to int value is integer
                return PropertyType.NSInteger.rawValue
            } else {
                // otherwise is double
                return PropertyType.CGFloat.rawValue
            }
        }
        return _correctTypeString(type: type)
    }
    
    /// correct type string
    internal static func _correctTypeString(type: String) -> String {
        
        if type.lowercased().contains("bool") {
            return PropertyType.BOOL.rawValue
        } else if type.lowercased().contains("string") {
            return PropertyType.NSString.rawValue
        } else if type.lowercased().contains("array") {
            return PropertyType.NSArray.rawValue
        } else if type.lowercased().contains("dictionary") {
            return PropertyType.NSDictioary.rawValue
        } else {
            return type.appending(" *")
        }
    }
}
