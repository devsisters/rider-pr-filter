package com.devsisters.prfilter

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage

@State(
    name = "PRFilterSettings",
    storages = [Storage("PRFilterSettings.xml")]
)
class PRFilterSettings : PersistentStateComponent<PRFilterSettings.State> {
    data class State(
        var filterPattern: String = "",
        var isEnabled: Boolean = false
    )

    private var myState = State()

    override fun getState(): State = myState

    override fun loadState(state: State) {
        myState = state
    }

    companion object {
        fun getInstance(): PRFilterSettings {
            return ApplicationManager.getApplication().getService(PRFilterSettings::class.java)
        }
    }
}
