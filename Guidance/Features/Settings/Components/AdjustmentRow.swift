import SwiftUI

struct AdjustmentRow: View {
  let label: LocalizedStringKey
  @Binding var value: Int

  var body: some View {
    HStack {
      Text(label)
      Spacer()
      TextField(label, value: $value, format: .number)
        .labelsHidden()
        .textFieldStyle(.roundedBorder)
        .frame(width: 72)
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
    }
  }
}
