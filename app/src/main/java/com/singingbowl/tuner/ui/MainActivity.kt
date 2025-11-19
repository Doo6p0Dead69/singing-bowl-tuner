package com.singingbowl.tuner.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.singingbowl.tuner.audio.AudioCapture
import com.singingbowl.tuner.data.BowlRepository
import com.singingbowl.tuner.data.SettingsRepository
import com.singingbowl.tuner.data.bowlsStore
import com.singingbowl.tuner.data.settingsStore
import com.singingbowl.tuner.ui.theme.SingingBowlTunerTheme
import kotlinx.coroutines.Dispatchers

class MainActivity : ComponentActivity() {
    private val viewModel by viewModels<TunerViewModel> {
        TunerViewModelFactory(
            audioCapture = AudioCapture(
                sampleRate = TunerViewModel.SAMPLE_RATE,
                frameSize = 2048,
                dispatcher = Dispatchers.IO
            ),
            bowlRepository = BowlRepository(applicationContext.bowlsStore),
            settingsRepository = SettingsRepository(applicationContext.settingsStore)
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            SingingBowlTunerTheme {
                val state by viewModel.state.collectAsState()
                val bowls by viewModel.bowls.collectAsState()
                MainScreen(
                    state = state,
                    bowls = bowls,
                    onToggle = { viewModel.toggleListening() },
                    onSaveBowl = { viewModel.saveBowl(it) },
                    onA4Change = { viewModel.setA4Reference(it) }
                )
            }
        }
    }
}

@Composable
fun MainScreen(
    state: TunerState,
    bowls: List<com.singingbowl.tuner.data.BowlProfile>,
    onToggle: () -> Unit,
    onSaveBowl: (String) -> Unit,
    onA4Change: (Float) -> Unit,
) {
    val scrollState = rememberScrollState()
    val (bowlName, setBowlName) = remember { mutableStateOf("") }
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(scrollState)
            .padding(16.dp)
    ) {
        TopAppBar(title = { Text(text = "Тюнер поющих чаш") })
        Spacer(modifier = Modifier.height(16.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = if (state.isListening) "Микрофон включен" else "Микрофон выключен")
            Button(onClick = onToggle) {
                Text(text = "Вкл/выкл")
            }
        }

        Spacer(modifier = Modifier.height(12.dp))
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    "Частота: ${state.frequencyHz?.let { String.format("%.1f Hz", it) } ?: "-"}",
                    style = MaterialTheme.typography.headlineMedium
                )
                Text("Нота: ${state.note ?: "-"}", style = MaterialTheme.typography.headlineSmall)
                Text("Центы: ${state.cents?.let { String.format("%+.1f", it) } ?: "-"}")
                Text("Уверенность: ${(state.clarity * 100).toInt()}%")
                state.warning?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = "Калибровка A4")
                Slider(
                    value = state.a4Reference,
                    onValueChange = { onA4Change(it) },
                    valueRange = 430f..450f
                )
                Text(text = String.format("A4 = %.1f Hz", state.a4Reference), fontWeight = FontWeight.Bold)
            }
        }

        Spacer(modifier = Modifier.height(12.dp))
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = "Сохранить профиль чаши", style = MaterialTheme.typography.titleMedium)
                OutlinedTextField(
                    value = bowlName,
                    onValueChange = setBowlName,
                    label = { Text("Название чаши") },
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = {
                        if (bowlName.isNotBlank()) onSaveBowl(bowlName)
                        setBowlName("")
                    },
                    enabled = state.frequencyHz != null && bowlName.isNotBlank()
                ) {
                    Text("Сохранить")
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = "Сохранённые чаши", style = MaterialTheme.typography.titleMedium)
                if (bowls.isEmpty()) {
                    Text("Нет сохранённых профилей")
                } else {
                    bowls.forEach { bowl ->
                        Text("${bowl.name} — ${String.format("%.1f Hz", bowl.frequencyHz)} (${bowl.note} ${String.format("%+.1f центов", bowl.cents)})")
                    }
                }
            }
        }
    }
}
