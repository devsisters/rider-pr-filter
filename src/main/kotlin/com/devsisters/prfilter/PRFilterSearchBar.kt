package com.devsisters.prfilter

import com.intellij.openapi.project.Project
import com.intellij.ui.JBColor
import com.intellij.ui.SearchTextField
import com.intellij.util.ui.JBUI
import java.awt.BorderLayout
import java.awt.Dimension
import java.awt.FlowLayout
import javax.swing.*

class PRFilterSearchBar(private val project: Project) : JPanel(BorderLayout()) {
    private val searchField = SearchTextField(false).apply {
        textEditor.emptyText.text = "Filter files (e.g., Shop*.*;*.cs;*.json)"
        textEditor.toolTipText = "Use wildcards like *.cs, Shop*.*, or Shop*.cs. Separate multiple patterns with semicolons."
    }
    private val applyButton = JButton("Apply")
    private val clearButton = JButton("×")
    private var filterCallback: ((String) -> Unit)? = null

    init {
        setupUI()
        setupListeners()
        loadSavedPattern()
    }

    private fun setupUI() {
        border = JBUI.Borders.empty(4, 8)
        background = JBColor.background()

        // Search field panel with responsive sizing
        val searchPanel = JPanel(BorderLayout()).apply {
            background = JBColor.background()

            // Set minimum and preferred sizes for responsive behavior
            searchField.apply {
                minimumSize = Dimension(200, preferredSize.height)
                preferredSize = Dimension(400, preferredSize.height)
            }

            add(searchField, BorderLayout.CENTER)
        }

        // Button panel (Apply + Clear)
        val buttonPanel = JPanel(FlowLayout(FlowLayout.RIGHT, 2, 0)).apply {
            background = JBColor.background()

            // Apply button
            add(applyButton.apply {
                toolTipText = "Apply filter"
                cursor = java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR)
            })

            // Clear button
            add(clearButton.apply {
                toolTipText = "Clear filter"
                isBorderPainted = false
                isContentAreaFilled = false
                cursor = java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR)
                preferredSize = java.awt.Dimension(24, 24)
            })
        }

        add(searchPanel, BorderLayout.CENTER)
        add(buttonPanel, BorderLayout.EAST)
    }

    private fun setupListeners() {
        // Apply filter on Enter key press (ActionListener handles Enter key by default)
        searchField.textEditor.addActionListener {
            onPatternChanged()
        }

        // Apply button
        applyButton.addActionListener {
            onPatternChanged()
        }

        // Clear button
        clearButton.addActionListener {
            searchField.text = ""
            savePattern("")
            filterCallback?.invoke("")
        }
    }

    private fun onPatternChanged() {
        val pattern = searchField.text.trim()
        savePattern(pattern)
        filterCallback?.invoke(pattern)
    }

    private fun savePattern(pattern: String) {
        val settings = PRFilterSettings.getInstance()
        settings.state.filterPattern = pattern
        settings.state.isEnabled = pattern.isNotEmpty()
    }

    private fun loadSavedPattern() {
        val settings = PRFilterSettings.getInstance()
        if (settings.state.isEnabled && settings.state.filterPattern.isNotEmpty()) {
            searchField.text = settings.state.filterPattern
        }
    }

    fun setFilterCallback(callback: (String) -> Unit) {
        this.filterCallback = callback
    }

    fun getPattern(): String = searchField.text.trim()
}