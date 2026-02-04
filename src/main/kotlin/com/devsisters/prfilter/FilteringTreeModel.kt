package com.devsisters.prfilter

import com.intellij.openapi.vcs.changes.Change
import com.intellij.openapi.vcs.changes.ui.ChangesBrowserNode
import javax.swing.event.TreeModelEvent
import javax.swing.event.TreeModelListener
import javax.swing.tree.TreeModel
import javax.swing.tree.TreePath

/**
 * A tree model that wraps another tree model and filters nodes based on a pattern.
 * Nodes that don't match the pattern (and don't have matching children) are completely hidden.
 */
class FilteringTreeModel(
    private val sourceModel: TreeModel,
    private val pattern: String
) : TreeModel {
    private val listeners = mutableListOf<TreeModelListener>()

    // Cache to avoid recalculating matches
    private val matchCache = mutableMapOf<Any, Boolean>()
    private val childrenCache = mutableMapOf<Any, List<Any>>()

    init {
        // Listen to source model changes
        sourceModel.addTreeModelListener(object : TreeModelListener {
            override fun treeNodesChanged(e: TreeModelEvent?) {
                clearCache()
                listeners.forEach { it.treeNodesChanged(e) }
            }

            override fun treeNodesInserted(e: TreeModelEvent?) {
                clearCache()
                listeners.forEach { it.treeNodesInserted(e) }
            }

            override fun treeNodesRemoved(e: TreeModelEvent?) {
                clearCache()
                listeners.forEach { it.treeNodesRemoved(e) }
            }

            override fun treeStructureChanged(e: TreeModelEvent?) {
                clearCache()
                listeners.forEach { it.treeStructureChanged(e) }
            }
        })
    }

    private fun clearCache() {
        matchCache.clear()
        childrenCache.clear()
    }

    override fun getRoot(): Any = sourceModel.root

    override fun getChild(parent: Any, index: Int): Any {
        val filteredChildren = getFilteredChildren(parent)
        return filteredChildren[index]
    }

    override fun getChildCount(parent: Any): Int {
        return getFilteredChildren(parent).size
    }

    override fun isLeaf(node: Any): Boolean {
        // A node is a leaf if it has no filtered children
        return getFilteredChildren(node).isEmpty()
    }

    override fun valueForPathChanged(path: TreePath?, newValue: Any?) {
        sourceModel.valueForPathChanged(path, newValue)
    }

    override fun getIndexOfChild(parent: Any?, child: Any?): Int {
        if (parent == null || child == null) return -1
        val filteredChildren = getFilteredChildren(parent)
        return filteredChildren.indexOf(child)
    }

    override fun addTreeModelListener(l: TreeModelListener?) {
        l?.let { listeners.add(it) }
    }

    override fun removeTreeModelListener(l: TreeModelListener?) {
        listeners.remove(l)
    }

    /**
     * Get filtered children of a node.
     * A child is included if:
     * 1. It matches the pattern, OR
     * 2. It has descendants that match the pattern
     */
    private fun getFilteredChildren(parent: Any): List<Any> {
        // Return cached result if available
        childrenCache[parent]?.let { return it }

        val childCount = sourceModel.getChildCount(parent)
        val filteredChildren = mutableListOf<Any>()

        for (i in 0 until childCount) {
            val child = sourceModel.getChild(parent, i)
            if (shouldShowNode(child)) {
                filteredChildren.add(child)
            }
        }

        // Cache the result
        childrenCache[parent] = filteredChildren
        return filteredChildren
    }

    /**
     * Check if a node should be shown.
     * A node is shown if:
     * 1. The pattern is empty (show all), OR
     * 2. The node itself matches the pattern, OR
     * 3. Any of its descendants match the pattern
     */
    private fun shouldShowNode(node: Any): Boolean {
        // Return cached result if available
        matchCache[node]?.let { return it }

        // Empty pattern means show all
        if (pattern.isBlank()) {
            matchCache[node] = true
            return true
        }

        // Extract file path from node
        val filePaths = extractFilePaths(node)

        // Check if this node matches
        val nodeMatches = filePaths.any { filePath ->
            FilePatternMatcher.matches(filePath, pattern)
        }

        if (nodeMatches) {
            matchCache[node] = true
            return true
        }

        // Check if any child matches (recursively)
        val childCount = sourceModel.getChildCount(node)
        for (i in 0 until childCount) {
            val child = sourceModel.getChild(node, i)
            if (shouldShowNode(child)) {
                matchCache[node] = true
                return true
            }
        }

        // No match found
        matchCache[node] = false
        return false
    }

    /**
     * Extract file paths from a tree node.
     * Handles different node types in the IntelliJ Platform.
     */
    private fun extractFilePaths(node: Any): List<String> {
        val paths = mutableListOf<String>()

        when (node) {
            is ChangesBrowserNode<*> -> {
                // Extract from ChangesBrowserNode
                val userObject = node.userObject

                when (userObject) {
                    is Change -> {
                        // Get file paths from Change
                        userObject.beforeRevision?.file?.path?.let { paths.add(it) }
                        userObject.afterRevision?.file?.path?.let { paths.add(it) }
                    }
                    is String -> {
                        // Node might represent a directory or label
                        paths.add(userObject)
                    }
                    else -> {
                        // Fallback to toString
                        paths.add(userObject?.toString() ?: node.toString())
                    }
                }

                // Also add the text representation
                node.textPresentation?.let { paths.add(it) }
            }
            else -> {
                // Fallback to toString for unknown node types
                paths.add(node.toString())
            }
        }

        return paths.filter { it.isNotBlank() }
    }

    /**
     * Force a refresh of the model by clearing caches and notifying listeners.
     */
    fun refresh() {
        clearCache()
        val root = sourceModel.root
        val event = TreeModelEvent(this, arrayOf(root))
        listeners.forEach { it.treeStructureChanged(event) }
    }
}
