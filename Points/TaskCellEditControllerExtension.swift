//
//  TaskCellEditControllerExtension.swift
//  Points
//
//  Created by Josh Kornreich on 2/20/25.
//


extension TaskCellEditController {
    // Add delegate setter for main cell to update
    func setDelegate(_ delegate: TaskTableViewCellDelegate?) {
        self.delegate = delegate
    }
}