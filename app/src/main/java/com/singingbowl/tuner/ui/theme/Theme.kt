package com.singingbowl.tuner.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFF8BC34A),
    secondary = Color(0xFF607D8B),
    background = Color(0xFF101010)
)

private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF8BC34A),
    secondary = Color(0xFF607D8B),
    background = Color(0xFFF7F7F7)
)

@Composable
fun SingingBowlTunerTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
