import Foundation

/// Data container representing a pitch detection result.
struct PitchInfo {
    let frequency: Double
    let cents: Double
    let confidence: Double
    let overtones: [Double]
}

/// Simplified pitch detector implementing the McLeod Pitch Method (MPM).  It
/// computes the normalized squared difference function over a window and
/// searches for the first significant peak to estimate frequency.
class PitchDetector {
    private let sampleRate: Double
    private let a4: Double
    private let minFreq: Double = 60.0
    private let maxFreq: Double = 1500.0
    private var minLag: Int { Int(sampleRate / maxFreq) }
    private var maxLag: Int { Int(sampleRate / minFreq) }

    init(sampleRate: Double, a4: Double) {
        self.sampleRate = sampleRate
        self.a4 = a4
    }

    func detectPitch(_ buffer: [Float]) -> PitchInfo? {
        // Convert to Double and remove DC offset
        var data = buffer.map { Double($0) }
        let mean = data.reduce(0.0, +) / Double(data.count)
        for i in data.indices { data[i] -= mean }
        let maxLag = Swift.min(self.maxLag, data.count - 1)
        var nsdf = Array(repeating: 0.0, count: maxLag + 1)
        var maxVal = 0.0
        let minLag = self.minLag
        for tau in minLag...maxLag {
            var acf = 0.0
            var m = 0.0
            let end = data.count - tau
            for i in 0..<end {
                let x = data[i]
                let y = data[i + tau]
                acf += x * y
                m += x * x + y * y
            }
            if m > 0 {
                nsdf[tau] = 2.0 * acf / m
            } else {
                nsdf[tau] = 0.0
            }
            if nsdf[tau] > maxVal { maxVal = nsdf[tau] }
        }
        var bestTau = -1
        var bestVal = 0.0
        if maxVal <= 0.0 { return nil }
        for tau in (minLag + 1)..<maxLag - 1 {
            let prev = nsdf[tau - 1]
            let current = nsdf[tau]
            let next = nsdf[tau + 1]
            if current > prev && current > next && current > 0.6 * maxVal {
                let denom = (prev - 2 * current + next)
                let delta = denom == 0 ? 0.0 : (prev - next) / (2 * denom)
                let peak = Double(tau) + delta
                let freq = sampleRate / peak
                if freq > minFreq && freq < maxFreq {
                    bestTau = tau
                    bestVal = current
                    break
                }
            }
        }
        if bestTau < 0 { return nil }
        let freq = sampleRate / Double(bestTau)
        let semitone = 12.0 * log2(freq / a4)
        let nearest = round(semitone)
        let cents = min(max((semitone - nearest) * 100.0, -50.0), 50.0)
        let confidence = min(max(bestVal, 0.0), 1.0)
        var overtones: [Double] = []
        for k in 2...8 {
            let overtoneFreq = freq * Double(k)
            if overtoneFreq > sampleRate / 2 { break }
            overtones.append(overtoneFreq)
        }
        return PitchInfo(frequency: freq, cents: cents, confidence: confidence, overtones: overtones)
    }
}