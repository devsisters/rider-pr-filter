package com.devsisters.prfilter

import com.intellij.openapi.vcs.changes.ui.ChangesTree

object PRFileTreeFilter {
    /**
     * Apply filter to the changes tree based on the pattern.
     *
     * Note: This method wraps the tree model with a FilteringTreeModel
     * to provide proper filtering functionality.
     *
     * @param tree The changes tree to filter
     * @param pattern The filter pattern (glob style, semicolon-separated)
     */
    fun applyFilter(tree: ChangesTree, pattern: String) {
        val originalModel = tree.model

        if (pattern.isBlank()) {
            // If we previously applied a FilteringTreeModel, restore the original
            if (originalModel is FilteringTreeModel) {
                // Extract the source model and restore it
                // For now, just expand all nodes since we can't easily unwrap
                expandAll(tree)
            } else {
                expandAll(tree)
            }
            return
        }

        // Apply FilteringTreeModel
        val filteringModel = FilteringTreeModel(originalModel, pattern)
        tree.model = filteringModel

        // Expand filtered nodes
        expandAll(tree)
    }

    /**
     * Safely expand all visible rows in the tree.
     * Prevents infinite loops by tracking the previous row count.
     */
    private fun expandAll(tree: ChangesTree) {
        var previousRowCount = 0
        var currentRowCount = tree.rowCount
        var iterations = 0
        val maxIterations = 100 // Safety limit

        // Keep expanding until no new rows appear or we hit the safety limit
        while (currentRowCount > previousRowCount && iterations < maxIterations) {
            for (i in 0 until currentRowCount) {
                tree.expandRow(i)
            }
            previousRowCount = currentRowCount
            currentRowCount = tree.rowCount
            iterations++
        }
    }

    /**
     * Check if a file path should be visible based on current filter.
     */
    fun shouldShowFile(filePath: String): Boolean {
        val settings = PRFilterSettings.getInstance()
        if (!settings.state.isEnabled) return true

        val pattern = settings.state.filterPattern
        if (pattern.isBlank()) return true

        return FilePatternMatcher.matches(filePath, pattern)
    }
}
