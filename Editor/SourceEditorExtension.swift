//
//  SourceEditorExtension.swift
//  Editor
//
//  Created by Thriller on 2019/5/30.
//  Copyright © 2019 Thriller. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    func extensionDidFinishLaunching() {
        // If your extension needs to do any work at launch, implement this optional method.
        print("ThrillerEditor did finish launching")
    }
    
    /*
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return []
    }
    */
    
}
