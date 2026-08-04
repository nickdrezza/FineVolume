import Foundation
import IOKit.hid
import IOKit.hidsystem

enum HIDVolumeKeyRemapperError: LocalizedError {
    case noKeyboardServices
    case propertyUpdateFailed

    var errorDescription: String? {
        switch self {
        case .noKeyboardServices:
            return "Fine Volume could not find a keyboard service to configure."
        case .propertyUpdateFailed:
            return "macOS rejected the temporary volume-key mapping."
        }
    }
}

final class HIDVolumeKeyRemapper {
    private typealias Mapping = [[String: NSNumber]]

    private static let propertyKey = "UserKeyMapping" as CFString
    private static let sourceKey = "HIDKeyboardModifierMappingSrc"
    private static let destinationKey = "HIDKeyboardModifierMappingDst"

    private static let volumeUpUsage = encodedUsage(
        page: UInt64(kHIDPage_Consumer),
        usage: UInt64(kHIDUsage_Csmr_VolumeIncrement)
    )
    private static let volumeDownUsage = encodedUsage(
        page: UInt64(kHIDPage_Consumer),
        usage: UInt64(kHIDUsage_Csmr_VolumeDecrement)
    )
    private static let f18Usage = encodedUsage(page: 0x07, usage: 0x6D)
    private static let f19Usage = encodedUsage(page: 0x07, usage: 0x6E)

    private let system: IOHIDEventSystemClient
    private var services: [UInt64: IOHIDServiceClient] = [:]
    private var baselineMappings: [UInt64: Mapping] = [:]
    private var isEnabled = false

    init() throws {
        system = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
        try discoverKeyboardServices()
        try apply(enabled: false)
    }

    deinit {
        try? apply(enabled: false)
    }

    func setEnabled(_ enabled: Bool) throws {
        guard enabled != isEnabled else { return }
        try discoverKeyboardServices()
        try apply(enabled: enabled)
        isEnabled = enabled
    }

    private func discoverKeyboardServices() throws {
        guard let allServices = IOHIDEventSystemClientCopyServices(system) as? [IOHIDServiceClient] else {
            throw HIDVolumeKeyRemapperError.noKeyboardServices
        }

        for service in allServices {
            guard IOHIDServiceClientConformsTo(
                service,
                UInt32(kHIDPage_GenericDesktop),
                UInt32(kHIDUsage_GD_Keyboard)
            ) != 0,
            let registryID = IOHIDServiceClientGetRegistryID(service) as? NSNumber
            else {
                continue
            }

            let id = registryID.uint64Value
            services[id] = service

            guard baselineMappings[id] == nil else { continue }
            let current = IOHIDServiceClientCopyProperty(service, Self.propertyKey) as? Mapping ?? []
            baselineMappings[id] = current.filter { !Self.isFineVolumeMapping($0) }
        }

        guard !services.isEmpty else {
            throw HIDVolumeKeyRemapperError.noKeyboardServices
        }
    }

    private func apply(enabled: Bool) throws {
        var updatedAtLeastOneService = false

        for (id, service) in services {
            var mapping = baselineMappings[id] ?? []
            if enabled {
                mapping.append(contentsOf: Self.fineVolumeMapping)
            }

            if IOHIDServiceClientSetProperty(
                service,
                Self.propertyKey,
                mapping as CFArray
            ) {
                updatedAtLeastOneService = true
            }
        }

        guard updatedAtLeastOneService else {
            throw HIDVolumeKeyRemapperError.propertyUpdateFailed
        }
    }

    private static var fineVolumeMapping: Mapping {
        [
            [
                sourceKey: NSNumber(value: volumeUpUsage),
                destinationKey: NSNumber(value: f18Usage),
            ],
            [
                sourceKey: NSNumber(value: volumeDownUsage),
                destinationKey: NSNumber(value: f19Usage),
            ],
        ]
    }

    private static func isFineVolumeMapping(_ mapping: [String: NSNumber]) -> Bool {
        guard let source = mapping[sourceKey]?.uint64Value,
              let destination = mapping[destinationKey]?.uint64Value
        else {
            return false
        }

        return (source == volumeUpUsage && destination == f18Usage)
            || (source == volumeDownUsage && destination == f19Usage)
    }

    private static func encodedUsage(page: UInt64, usage: UInt64) -> UInt64 {
        (page << 32) | usage
    }
}
