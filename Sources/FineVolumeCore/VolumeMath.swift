import Foundation

public enum VolumeDirection: Sendable {
    case up
    case down
}

public enum VolumeMath {
    public static func adjusted(
        _ current: Float,
        direction: VolumeDirection,
        step: Float = 0.01
    ) -> Float {
        let safeCurrent = min(max(current, 0), 1)
        let safeStep = max(step, 0)

        switch direction {
        case .up:
            return min(safeCurrent + safeStep, 1)
        case .down:
            return max(safeCurrent - safeStep, 0)
        }
    }
}
