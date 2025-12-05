package com.singingbowl.tuner.data

import kotlinx.serialization.Serializable

@Serializable
data class BowlProfile(
    val name: String,
    val frequencyHz: Float,
    val note: String,
    val cents: Float
)
