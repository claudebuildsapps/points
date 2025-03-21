// MARK: - TaskCellSwipeController Extension
extension TaskCellSwipeController {
    // Add delegate setter for main cell to update
    func setDelegate(_ delegate: TaskTableViewCellDelegate?) {
        self.delegate = delegate
    }
}
