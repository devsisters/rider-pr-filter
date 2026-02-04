package com.devsisters.prfilter

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.diagnostic.Logger
import com.intellij.openapi.fileEditor.FileEditorManager
import com.intellij.openapi.fileEditor.FileEditorManagerListener
import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.StartupActivity
import com.intellij.openapi.vcs.changes.ui.ChangesViewContentManager
import com.intellij.openapi.wm.ToolWindowManager
import com.intellij.ui.content.ContentManagerEvent
import com.intellij.ui.content.ContentManagerListener
import java.awt.BorderLayout
import java.awt.Component
import javax.swing.JComponent
import javax.swing.JLabel
import javax.swing.JPanel

class PRViewDecorator : StartupActivity.DumbAware {
    companion object {
        private val LOG = Logger.getInstance(PRViewDecorator::class.java)
    }

    override fun runActivity(project: Project) {
        // LOG.info("=== PRViewDecorator: Starting PR filter plugin for project: ${project.name} ===")
        ApplicationManager.getApplication().invokeLater {
            setupPRFilterBar(project)
            setupEditorListener(project)
        }
    }

    private fun setupEditorListener(project: Project) {
        // LOG.info("PRViewDecorator: Setting up editor listener")

        // Listen for file editor events to detect when PR views are opened
        project.messageBus.connect().subscribe(
            FileEditorManagerListener.FILE_EDITOR_MANAGER,
            object : FileEditorManagerListener {
                override fun fileOpened(source: FileEditorManager, file: com.intellij.openapi.vfs.VirtualFile) {
                    // LOG.info("PRViewDecorator: File opened: ${file.name}, fileType: ${file.fileType}, class: ${file.javaClass.simpleName}")
                    // Give the editor time to fully initialize using a timer instead of blocking the EDT
                    javax.swing.Timer(500) {
                        tryAddSearchBarToEditor(project, source)
                    }.apply {
                        isRepeats = false
                        start()
                    }
                }
            }
        )

        // Check already opened editors
        ApplicationManager.getApplication().invokeLater {
            // LOG.info("PRViewDecorator: Checking already opened editors")
            tryAddSearchBarToEditor(project, FileEditorManager.getInstance(project))
        }
    }

    private fun tryAddSearchBarToEditor(project: Project, editorManager: FileEditorManager) {
        editorManager.selectedEditor?.component?.let { component ->
            findAndDecorateChangesPanel(component, project)
        }
    }

    private fun findAndDecorateChangesPanel(component: Component, project: Project) {
        // Recursively search for changes panel
        if (component is JPanel) {
            // Look for "Changes from" label which indicates the changes panel
            val hasChangesLabel = findComponentRecursive(component) { comp ->
                comp is JLabel && comp.text?.contains("Changes from", ignoreCase = true) == true
            }

            if (hasChangesLabel != null) {
                // LOG.info("PRViewDecorator: Found 'Changes from' label, adding search bar to panel")
                // Found the changes panel, try to add search bar above it
                addSearchBarToPanel(component, project)
                return
            }
        }

        // Continue searching in children
        if (component is JComponent) {
            component.components?.forEach { child ->
                findAndDecorateChangesPanel(child, project)
            }
        }
    }

    private fun findComponentRecursive(component: Component, predicate: (Component) -> Boolean): Component? {
        if (predicate(component)) return component

        if (component is JComponent) {
            component.components?.forEach { child ->
                findComponentRecursive(child, predicate)?.let { return it }
            }
        }

        return null
    }

    private fun addSearchBarToPanel(panel: JPanel, project: Project) {
        // Check if search bar is already added
        if (hasSearchBar(panel)) {
            // LOG.info("PRViewDecorator: Search bar already exists in panel, skipping")
            return
        }

        // LOG.info("PRViewDecorator: Creating search bar for panel")

        // Create search bar
        val searchBar = PRFilterSearchBar(project)

        // Set up filtering callback
        searchBar.setFilterCallback { pattern ->
            applyFilter(project, pattern)
        }

        // Create wrapper panel with search bar at the top
        val wrapperPanel = JPanel(BorderLayout()).apply {
            putClientProperty("PR_FILTER_WRAPPER", true)
            add(searchBar, BorderLayout.NORTH)
        }

        // Get the parent of the panel
        val parent = panel.parent
        if (parent is JPanel) {
            val layout = parent.layout
            val constraints = if (layout is BorderLayout) {
                // Find the constraint where this panel is located
                BorderLayout.CENTER
            } else {
                null
            }

            parent.remove(panel)
            wrapperPanel.add(panel, BorderLayout.CENTER)

            if (constraints != null && layout is BorderLayout) {
                parent.add(wrapperPanel, constraints)
            } else {
                parent.add(wrapperPanel)
            }

            parent.revalidate()
            parent.repaint()
        }
    }

    private fun setupPRFilterBar(project: Project) {
        val toolWindowManager = ToolWindowManager.getInstance(project)

        // Try multiple tool window names including GitHub
        val toolWindowNames = listOf("Commit", "Version Control", "Git", "Pull Requests", "GitHub")

        // LOG.info("PRViewDecorator: Attempting to find tool windows: $toolWindowNames")
        // LOG.info("PRViewDecorator: Available tool windows: ${toolWindowManager.toolWindowIds.joinToString()}")

        for (toolWindowName in toolWindowNames) {
            val toolWindow = toolWindowManager.getToolWindow(toolWindowName)
            if (toolWindow == null) {
                // LOG.debug("PRViewDecorator: Tool window '$toolWindowName' not found")
                continue
            }

            // LOG.info("PRViewDecorator: Found tool window '$toolWindowName'")

            toolWindow.contentManager.addContentManagerListener(object : ContentManagerListener {
                override fun contentAdded(event: ContentManagerEvent) {
                    // LOG.info("PRViewDecorator: Content added to '$toolWindowName': displayName='${event.content.displayName}', tabName='${event.content.tabName}'")
                    checkAndAddSearchBar(event, project)
                }

                override fun selectionChanged(event: ContentManagerEvent) {
                    // LOG.debug("PRViewDecorator: Selection changed in '$toolWindowName': displayName='${event.content.displayName}', tabName='${event.content.tabName}'")
                    checkAndAddSearchBar(event, project)
                }
            })

            // Check current content
            toolWindow.contentManager.contents.forEach { content ->
                // LOG.info("PRViewDecorator: Checking existing content: displayName='${content.displayName}', tabName='${content.tabName}'")
                val event = ContentManagerEvent(toolWindow.contentManager, content, 0)
                checkAndAddSearchBar(event, project)
            }
        }
    }

    private fun checkAndAddSearchBar(event: ContentManagerEvent, project: Project) {
        val content = event.content
        val displayName = content.displayName ?: ""
        val tabName = content.tabName ?: ""

        // LOG.debug("PRViewDecorator: Checking content - displayName='$displayName', tabName='$tabName', component class='${content.component?.javaClass?.simpleName}'")

        // Check if this is a PR view - 더 넓은 조건으로 확인
        val isPRView = displayName.contains("Pull Request", ignoreCase = true) ||
                displayName.contains("PR #", ignoreCase = false) ||
                displayName.contains("#", ignoreCase = false) ||  // GitHub PR은 #번호로 표시됨
                content.tabName?.contains("Pull Request", ignoreCase = true) == true ||
                content.component?.javaClass?.name?.contains("GHPR", ignoreCase = true) == true

        // LOG.debug("PRViewDecorator: Is PR view? $isPRView")

        if (!isPRView) return

        val component = content.component as? JComponent
        if (component == null) {
            // LOG.debug("PRViewDecorator: Content component is not a JComponent")
            return
        }

        // Check if search bar is already added
        if (hasSearchBar(component)) {
            // LOG.info("PRViewDecorator: Search bar already exists, skipping")
            return
        }

        // LOG.info("PRViewDecorator: Adding search bar to PR view")

        // Create search bar
        val searchBar = PRFilterSearchBar(project)

        // Set up filtering callback
        searchBar.setFilterCallback { pattern ->
            applyFilter(project, pattern)
        }

        // Create wrapper panel with search bar
        val wrapperPanel = JPanel(BorderLayout()).apply {
            // Add a unique client property to identify this panel
            putClientProperty("PR_FILTER_WRAPPER", true)

            add(searchBar, BorderLayout.NORTH)
        }

        // Remove component from current parent if it has one
        component.parent?.remove(component)

        // Add the original component to the wrapper
        wrapperPanel.add(component, BorderLayout.CENTER)

        // Replace content and revalidate
        try {
            content.component = wrapperPanel
            wrapperPanel.revalidate()
            wrapperPanel.repaint()
            // LOG.info("PRViewDecorator: Successfully added search bar to PR view")
        } catch (e: Exception) {
            // If replacement fails, just continue
            LOG.error("PRViewDecorator: Failed to add search bar", e)
            e.printStackTrace()
        }
    }

    private fun hasSearchBar(component: JComponent): Boolean {
        // Check if this component or any parent already has the search bar
        if (component.getClientProperty("PR_FILTER_WRAPPER") == true) return true

        return component.components.any {
            it is PRFilterSearchBar ||
            (it is JComponent && it.getClientProperty("PR_FILTER_WRAPPER") == true)
        }
    }

    private fun applyFilter(project: Project, pattern: String) {
        // LOG.info("PRViewDecorator: Applying filter with pattern: '$pattern'")

        // Save the pattern
        val settings = PRFilterSettings.getInstance()
        settings.state.filterPattern = pattern
        settings.state.isEnabled = pattern.isNotEmpty()

        // Find and filter the changes tree in the current PR view
        ApplicationManager.getApplication().invokeLater {
            val toolWindowManager = ToolWindowManager.getInstance(project)
            val toolWindowNames = listOf("Commit", "Version Control", "Git", "Pull Requests", "GitHub")

            for (toolWindowName in toolWindowNames) {
                val toolWindow = toolWindowManager.getToolWindow(toolWindowName) ?: continue

                toolWindow.contentManager.contents.forEach { content ->
                    val displayName = content.displayName ?: ""

                    // Check if this is a PR view
                    val isPRView = displayName.contains("Pull Request", ignoreCase = true) ||
                            displayName.contains("PR #", ignoreCase = false) ||
                            displayName.contains("#", ignoreCase = false) ||
                            content.tabName?.contains("Pull Request", ignoreCase = true) == true ||
                            content.component?.javaClass?.name?.contains("GHPR", ignoreCase = true) == true

                    if (!isPRView) return@forEach

                    // LOG.info("PRViewDecorator: Found PR view to filter: '$displayName'")

                    // Find the wrapper panel that contains our search bar
                    val component = content.component as? JComponent
                    if (component != null) {
                        // Find ChangesTree within this component
                        val changesTree = findChangesTree(component)
                        if (changesTree != null) {
                            // LOG.info("PRViewDecorator: Found ChangesTree, applying filter")
                            applyTreeFilter(changesTree, pattern)
                        } else {
                            // LOG.warn("PRViewDecorator: ChangesTree not found in component tree")
                            // logComponentTree(component, 0)
                        }
                    }
                }
            }
        }
    }

    private fun findChangesTree(component: Component): com.intellij.openapi.vcs.changes.ui.ChangesTree? {
        if (component is com.intellij.openapi.vcs.changes.ui.ChangesTree) {
            return component
        }

        if (component is JComponent) {
            for (child in component.components) {
                val result = findChangesTree(child)
                if (result != null) return result
            }
        }

        return null
    }

    // Keep track of original models for each tree
    private val originalModels = mutableMapOf<com.intellij.openapi.vcs.changes.ui.ChangesTree, javax.swing.tree.TreeModel>()

    private fun applyTreeFilter(tree: com.intellij.openapi.vcs.changes.ui.ChangesTree, pattern: String) {
        try {
            // LOG.info("PRViewDecorator: Applying tree filter with pattern: '$pattern'")

            // Save the original model if not already saved
            if (!originalModels.containsKey(tree)) {
                originalModels[tree] = tree.model
                // LOG.info("PRViewDecorator: Saved original tree model: ${tree.model.javaClass.simpleName}")
            }

            val originalModel = originalModels[tree]!!

            if (pattern.isBlank()) {
                // Clear filter - restore original model and expand all
                // LOG.info("PRViewDecorator: Clearing filter, restoring original model")
                tree.model = originalModel

                // Expand all nodes recursively
                ApplicationManager.getApplication().invokeLater {
                    expandAllFiltered(tree)
                    tree.revalidate()
                    tree.repaint()
                }

                // LOG.info("PRViewDecorator: Filter cleared, restored original model")
                return
            }

            // Apply filtering tree model
            // LOG.info("PRViewDecorator: Applying FilteringTreeModel with pattern: '$pattern'")
            val filteringModel = FilteringTreeModel(originalModel, pattern)
            tree.model = filteringModel

            // Expand all filtered nodes after a short delay using Timer instead of blocking EDT
            javax.swing.Timer(100) {
                expandAllFiltered(tree)
                tree.revalidate()
                tree.repaint()
                // LOG.info("PRViewDecorator: FilteringTreeModel applied and tree expanded")
            }.apply {
                isRepeats = false
                start()
            }

        } catch (e: Exception) {
            LOG.error("PRViewDecorator: Error applying tree filter", e)
        }
    }

    /**
     * Expand all nodes in the filtered tree.
     */
    private fun expandAllFiltered(tree: com.intellij.openapi.vcs.changes.ui.ChangesTree) {
        var previousRowCount = 0
        var currentRowCount = tree.rowCount

        // Keep expanding until no new rows appear
        while (currentRowCount > previousRowCount) {
            for (i in 0 until currentRowCount) {
                tree.expandRow(i)
            }
            previousRowCount = currentRowCount
            currentRowCount = tree.rowCount
        }
    }

    private fun logComponentTree(component: Component, depth: Int) {
        val indent = "  ".repeat(depth)
        // LOG.warn("PRViewDecorator: ${indent}Component: ${component.javaClass.simpleName}")

        if (component is JComponent && depth < 5) {
            component.components?.forEach { child ->
                logComponentTree(child, depth + 1)
            }
        }
    }
}
