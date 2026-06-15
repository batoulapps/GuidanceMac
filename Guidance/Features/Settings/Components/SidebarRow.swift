import SwiftUI

struct SidebarRow: View {
  let tab: SettingsTab
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: tab.icon)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.white)
          .frame(width: 24, height: 24)
          .background(tab.iconColor, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        Text(tab.title)
          .font(.system(size: 13))
          .foregroundStyle(isSelected ? .white : .primary)
        Spacer()
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(isSelected ? Color.accentColor : .clear)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .focusEffectDisabled()
  }
}
