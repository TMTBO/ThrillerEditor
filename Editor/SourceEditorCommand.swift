//
//  SourceEditorCommand.swift
//  Editor
//
//  Created by Thriller on 2019/5/30.
//  Copyright © 2019 Thriller. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        EditorController.handle(with: invocation)
        completionHandler(nil)
    }
    
}
