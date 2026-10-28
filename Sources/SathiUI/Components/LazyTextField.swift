import SwiftUI

struct LazyTextField: View {
    let placeholder: String
    @Binding var text: String
    let onSubmit: () -> Void
    let onEndEditing: () -> Void
    @State private var isEditing: Bool
    @FocusState private var focused: Bool

    init(
        placeholder: String,
        text: Binding<String>,
        startsEditing: Bool = false,
        onSubmit: @escaping () -> Void = {},
        onEndEditing: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        _text = text
        _isEditing = State(initialValue: startsEditing)
        self.onSubmit = onSubmit
        self.onEndEditing = onEndEditing
    }

    var body: some View {
        if isEditing {
            field
        } else {
            resting
        }
    }

    private var resting: some View {
        Button { isEditing = true } label: {
            Text(verbatim: text.isEmpty ? placeholder : text)
                .font(Typography.chip)
                .foregroundStyle(text.isEmpty ? Night.muted : Night.text)
                .lineLimit(1)
                .padding(UIMetrics.timeButtonPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(shape.fill(Night.bg))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(placeholder)
        .accessibilityValue(text)
    }

    private var field: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(Typography.chip)
            .foregroundStyle(Night.text)
            .padding(UIMetrics.timeButtonPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(Night.bg))
            .focused($focused)
            .onAppear { focused = true }
            .onSubmit {
                onSubmit()
                isEditing = false
            }
            .onChange(of: focused) { nowFocused in
                guard !nowFocused else { return }
                onEndEditing()
                isEditing = false
            }
    }

    private var shape: some Shape {
        RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
    }
}
