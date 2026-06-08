import SwiftUI

struct AlarmSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hour: Int
    @State private var minute: Int
    @State private var selectedDays: Set<Int>

    private let weekdayDisplayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private let alarm: Alarm
    private let onSave: (Alarm) -> Void
    private let onClose: (() -> Void)?

    init(
        alarm: Alarm,
        onSave: @escaping (Alarm) -> Void = { _ in },
        onClose: (() -> Void)? = nil
    ) {
        self.alarm = alarm
        self.onSave = onSave
        self.onClose = onClose
        _hour = State(initialValue: alarm.hour)
        _minute = State(initialValue: alarm.minute)
        _selectedDays = State(initialValue: Set(alarm.repeatDays))
    }

    var body: some View {
        ZStack {
            alarmSettingBackdrop

            VStack(spacing: 0) {
                Spacer()

                timeBlock

                daySelector
                    .padding(.top, DesignTokens.Spacing.hero)

                saveButton
                    .padding(.top, DesignTokens.Spacing.alarmEditorWeekdayToAction)
                    .padding(.bottom, DesignTokens.Spacing.xLarge)
            }
            .padding(.horizontal, DesignTokens.Spacing.pageHorizontal)
            .padding(.top, DesignTokens.Spacing.pageHorizontal)
        }
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, DesignTokens.Spacing.modalCloseTopInset)
                .padding(.trailing, DesignTokens.Spacing.pageHorizontal)
        }
    }

    private var alarmSettingBackdrop: some View {
        DesignTokens.Colors.overlayScrim
            .ignoresSafeArea()
    }

    private var closeButton: some View {
        VibriseCloseButton(action: closeEditor)
    }

    private var timeBlock: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.small) {
            wheelColumn(value: $hour, range: 0...23)

            Text(":")
                .vibriseMavenText(size: DesignTokens.Size.pickerSeparatorSize)
                .fontWeight(.medium)
                .frame(height: DesignTokens.Size.pickerSelectionHeight, alignment: .center)
                .offset(y: -6)

            wheelColumn(value: $minute, range: 0...59)
        }
    }

    private var daySelector: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            weekdayRow([1, 2, 3, 4])
            weekdayRow([5, 6, 0])
        }
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }

    private func weekdayRow(_ days: [Int]) -> some View {
        HStack(spacing: 28) {
            ForEach(days, id: \.self) { index in
                weekdayButton(for: index)
            }
        }
    }

    private func weekdayButton(for index: Int) -> some View {
        let isSelected = selectedDays.contains(index)
        let label = weekdayDisplayLabels[index]

        return Button {
            toggleDay(index)
        } label: {
            ZStack {
                Color.clear
                    .frame(
                        width: DesignTokens.Size.weekdaySelector,
                        height: DesignTokens.Size.weekdaySelector
                    )
                    .homeMaterialChrome(
                        Circle(),
                        highlightStrokeOpacity: DesignTokens.Chrome.homeHighlightStrokeOpacity,
                        highlightBlurRadius: DesignTokens.Chrome.homeHighlightBlurRadius,
                        highlightStrokeWidth: DesignTokens.Chrome.homeHighlightStrokeWidth,
                        baseStrokeOpacity: DesignTokens.Chrome.homeBaseStrokeOpacity
                    )
                    .opacity(isSelected ? 1 : 0)

                Text(label)
                    .vibriseSatoshiText(
                        size: 16,
                        weight: isSelected ? .medium : .regular,
                        color: isSelected ? DesignTokens.Colors.primaryText : Color.white.opacity(0.2)
                    )
                    .blendMode(isSelected ? .normal : .plusLighter)
            }
            .frame(
                width: DesignTokens.Size.weekdaySelector,
                height: DesignTokens.Size.weekdaySelector
            )
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button {
            onSave(
                Alarm(
                    id: alarm.id,
                    isEnabled: alarm.isEnabled,
                    hour: hour,
                    minute: minute,
                    repeatDays: selectedDays.sorted()
                )
            )
            closeEditor()
        } label: {
            Text("Save")
                .font(DesignTokens.Typography.satoshiFont(size: 16))
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(
                    width: DesignTokens.Size.alarmEditorActionWidth,
                    height: DesignTokens.Size.primaryActionHeight
                )
                .homeMaterialChrome(
                    Capsule(),
                    highlightStrokeOpacity: DesignTokens.Chrome.homeHighlightStrokeOpacity,
                    highlightBlurRadius: DesignTokens.Chrome.homeHighlightBlurRadius,
                    highlightStrokeWidth: DesignTokens.Chrome.homeHighlightStrokeWidth,
                    baseStrokeOpacity: DesignTokens.Chrome.homeBaseStrokeOpacity
                )
        }
        .buttonStyle(.plain)
    }

    private func wheelColumn(value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        ZStack {
            pickerSelectionFrame
                .allowsHitTesting(false)

            AlarmWheelColumn(selection: value, range: range)
        }
    }

    private var pickerSelectionFrame: some View {
        Color.clear
            .frame(
                width: DesignTokens.Size.pickerSelectionWidth,
                height: DesignTokens.Size.pickerSelectionHeight
            )
            .homeMaterialChrome(
                RoundedRectangle(
                    cornerRadius: DesignTokens.CornerRadius.card,
                    style: .continuous
                ),
                highlightStrokeOpacity: DesignTokens.Chrome.homeHighlightStrokeOpacity,
                highlightBlurRadius: DesignTokens.Chrome.homeHighlightBlurRadius,
                highlightStrokeWidth: DesignTokens.Chrome.homeHighlightStrokeWidth,
                baseStrokeOpacity: DesignTokens.Chrome.homeBaseStrokeOpacity
            )
    }

    private func toggleDay(_ index: Int) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            if selectedDays.contains(index) {
                selectedDays.remove(index)
            } else {
                selectedDays.insert(index)
            }
        }
    }

    private func closeEditor() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

private struct AlarmWheelColumn: View {
    @Binding var selection: Int
    let range: ClosedRange<Int>

    @GestureState private var dragTranslation: CGFloat = 0

    private var visibleOffsets: [Int] {
        Array(-2...2)
    }

    var body: some View {
        ZStack {
            ForEach(visibleOffsets, id: \.self) { offset in
                if let value = resolvedValue(for: offset) {
                    wheelLabel(for: value, offset: offset)
                }
            }
        }
        .frame(
            width: DesignTokens.Size.pickerWidth,
            height: DesignTokens.Size.pickerHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    private func wheelLabel(for value: Int, offset: Int) -> some View {
        let effectivePosition = abs(CGFloat(offset) + dragTranslation / DesignTokens.Size.pickerRowStep)
        let isSelected = effectivePosition < 0.5
        let isAdjacent = effectivePosition >= 0.5 && effectivePosition < 1.5
        let isOuter = effectivePosition >= 1.5
        let fontSize = resolvedFontSize(isSelected: isSelected, isAdjacent: isAdjacent, isOuter: isOuter)
        let opacity = resolvedOpacity(isSelected: isSelected, isAdjacent: isAdjacent, isOuter: isOuter)
        let scale = resolvedScale(isSelected: isSelected, isAdjacent: isAdjacent, isOuter: isOuter)

        return Text(String(format: "%02d", value))
            .font(DesignTokens.Typography.mavenProFont(size: fontSize))
            .fontWeight(isSelected ? .medium : .regular)
            .tracking(DesignTokens.Typography.tracking(for: fontSize))
            .foregroundStyle(DesignTokens.Colors.primaryText.opacity(opacity))
            .blendMode((isAdjacent || isOuter) ? .plusLighter : .normal)
            .scaleEffect(scale)
            .offset(y: baseOffsetY(for: offset) + dragTranslation)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let projectedSteps = -value.predictedEndTranslation.height / DesignTokens.Size.pickerRowStep
                let stepDelta = Int(projectedSteps.rounded())
                let nextValue = min(max(selection + stepDelta, range.lowerBound), range.upperBound)

                withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.88)) {
                    selection = nextValue
                }
            }
    }

    private func resolvedValue(for offset: Int) -> Int? {
        let value = selection + offset
        guard range.contains(value) else {
            return nil
        }
        return value
    }

    private func resolvedFontSize(isSelected: Bool, isAdjacent: Bool, isOuter: Bool) -> CGFloat {
        if isSelected {
            return DesignTokens.Size.pickerSelectedValueSize
        }
        if isAdjacent {
            return DesignTokens.Size.pickerAdjacentValueSize
        }
        if isOuter {
            return DesignTokens.Size.pickerValueSize
        }
        return DesignTokens.Size.pickerValueSize
    }

    private func resolvedOpacity(isSelected: Bool, isAdjacent: Bool, isOuter: Bool) -> CGFloat {
        if isSelected {
            return 1
        }
        if isAdjacent {
            return 0.2
        }
        if isOuter {
            return 0.1
        }
        return 0.1
    }

    private func resolvedScale(isSelected: Bool, isAdjacent: Bool, isOuter: Bool) -> CGFloat {
        if isSelected {
            return 1
        }
        if isAdjacent {
            return 1
        }
        if isOuter {
            return 1
        }
        return 1
    }

    private func baseOffsetY(for offset: Int) -> CGFloat {
        switch offset {
        case -2:
            return -102
        case -1:
            return -62
        case 0:
            return 0
        case 1:
            return 62
        case 2:
            return 102
        default:
            return CGFloat(offset) * DesignTokens.Size.pickerRowStep
        }
    }
}

#Preview {
    AlarmSettingView(
        alarm: Alarm(
            id: 1,
            isEnabled: true,
            hour: 7,
            minute: 0,
            repeatDays: [1, 2, 3, 4, 5]
        )
    )
}
