package com.devsisters.prfilter

import java.nio.file.Paths
import java.util.regex.Pattern

object FilePatternMatcher {
    /**
     * Check if a file path matches the given pattern(s).
     *
     * @param filePath The file path to check
     * @param pattern Pattern string (e.g., "*.cs" or "*.cs;*.json" or "*shop*.*;shop*builder.cs")
     * @return true if the file matches any of the patterns
     */
    fun matches(filePath: String, pattern: String): Boolean {
        if (pattern.isBlank()) return true

        val patterns = pattern.split(';')
            .map { it.trim() }
            .filter { it.isNotEmpty() }

        if (patterns.isEmpty()) return true

        val path = Paths.get(filePath)
        val fileName = path.fileName?.toString() ?: filePath
        val normalizedPath = filePath.replace('\\', '/')

        return patterns.any { patternStr ->
            // Try matching against both filename and full path
            matchesPattern(fileName, patternStr) || matchesPattern(normalizedPath, patternStr)
        }
    }

    /**
     * Check if a filename matches a single pattern using wildcard matching.
     * Supports patterns like:
     * - *.cs (files ending with .cs)
     * - *shop*.* (files containing "shop" with any extension)
     * - shop*builder.cs (files starting with "shop" and ending with "builder.cs")
     */
    private fun matchesPattern(fileName: String, pattern: String): Boolean {
        return try {
            // Convert wildcard pattern to regex
            val regex = wildcardToRegex(pattern)
            regex.matches(fileName)
        } catch (e: Exception) {
            // Fallback to simple contains check
            fileName.contains(pattern.replace("*", ""), ignoreCase = true)
        }
    }

    /**
     * Convert a wildcard pattern to a regular expression.
     * * matches any characters (including none)
     * ? matches exactly one character
     * All other characters are escaped for literal matching
     */
    private fun wildcardToRegex(pattern: String): Regex {
        val sb = StringBuilder()
        sb.append("^")

        var i = 0
        while (i < pattern.length) {
            when (val c = pattern[i]) {
                '*' -> sb.append(".*")
                '?' -> sb.append(".")
                '.', '(', ')', '[', ']', '{', '}', '+', '^', '$', '|', '\\' -> {
                    sb.append('\\')
                    sb.append(c)
                }
                else -> sb.append(c)
            }
            i++
        }

        sb.append("$")
        return Regex(sb.toString(), RegexOption.IGNORE_CASE)
    }

    /**
     * Get a human-readable description of the pattern.
     */
    fun getPatternDescription(pattern: String): String {
        if (pattern.isBlank()) return "All files"

        val patterns = pattern.split(';')
            .map { it.trim() }
            .filter { it.isNotEmpty() }

        return when {
            patterns.isEmpty() -> "All files"
            patterns.size == 1 -> "Files matching: ${patterns[0]}"
            else -> "Files matching: ${patterns.joinToString(", ")}"
        }
    }
}