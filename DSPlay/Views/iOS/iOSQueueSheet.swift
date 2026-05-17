#if os(iOS)
import SwiftUI

/// Queue presented as a bottom sheet on iOS. Reuses `QueueDrawerView`.
struct iOSQueueSheet: View {
    @Environment(UIState.self) private var ui

    var body: some View {
        NavigationStack {
            QueueDrawerView()
                .navigationTitle("Up Next")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { ui.queueOpen = false }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
#endif
