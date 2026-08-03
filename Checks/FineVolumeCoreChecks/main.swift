import FineVolumeCore
import Foundation

private func expectEqual(
    _ actual: Float,
    _ expected: Float,
    accuracy: Float = 0.000_001,
    _ message: String
) {
    guard abs(actual - expected) <= accuracy else {
        fputs("FAIL: \(message). Expected \(expected), got \(actual).\n", stderr)
        exit(1)
    }
}

expectEqual(
    VolumeMath.adjusted(0.50, direction: .up),
    0.51,
    "volume should increase by one percentage point"
)
expectEqual(
    VolumeMath.adjusted(0.50, direction: .down),
    0.49,
    "volume should decrease by one percentage point"
)
expectEqual(
    VolumeMath.adjusted(0.995, direction: .up),
    1,
    "volume should clamp at 100%"
)
expectEqual(
    VolumeMath.adjusted(0.005, direction: .down),
    0,
    "volume should clamp at 0%"
)
expectEqual(
    VolumeMath.adjusted(2, direction: .down),
    0.99,
    "out-of-range high input should be sanitized"
)
expectEqual(
    VolumeMath.adjusted(-1, direction: .up),
    0.01,
    "out-of-range low input should be sanitized"
)

print("FineVolumeCore checks passed.")
