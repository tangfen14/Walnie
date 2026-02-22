import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

@main
struct WalnieLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.1, *) {
      WalnieFeedReminderWidget()
    }
  }
}

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {}

  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    return "\(id)_\(key)"
  }
}

private let walnieSharedDefaults = UserDefaults(suiteName: "group.com.wang.walnie.shared")!
private let walnieFallbackQuickActionUrl = "walnie://quick-add/voice-feed"

@available(iOSApplicationExtension 16.1, *)
struct WalnieFeedReminderWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      WalnieReminderLockscreenView(context: context)
        .padding(14)
        .background(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(red: 0.15, green: 0.19, blue: 0.27).opacity(0.96))
        )
        .activityBackgroundTint(Color.clear)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          WalnieAvatarView(context: context)
            .frame(width: 44, height: 44)
        }

        DynamicIslandExpandedRegion(.trailing) {
          WalnieQuickAddButton(context: context, compact: true)
        }

        DynamicIslandExpandedRegion(.center) {
          let feedAt = lastFeedAt(context: context)
          VStack(alignment: .leading, spacing: 2) {
            WalnieRelativeTimeView(lastFeedAt: feedAt)
              .font(.caption)
              .foregroundStyle(.white.opacity(0.82))
            Text(lastMealLine(lastFeedAt: feedAt))
              .font(.headline)
              .foregroundStyle(.white)
              .lineLimit(1)
          }
        }
      } compactLeading: {
        WalnieAvatarView(context: context)
          .frame(width: 24, height: 24)
      } compactTrailing: {
        Image(systemName: "plus")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.orange)
      } minimal: {
        Image(systemName: "drop.fill")
          .foregroundStyle(.orange)
      }
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct WalnieReminderLockscreenView: View {
  let context: ActivityViewContext<LiveActivitiesAppAttributes>

  var body: some View {
    let feedAt = lastFeedAt(context: context)
    HStack(alignment: .center, spacing: 12) {
      VStack(spacing: 4) {
        WalnieAvatarView(context: context)
          .frame(width: 52, height: 52)

        Text("walnie")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.92))
      }

      VStack(alignment: .leading, spacing: 4) {
        WalnieRelativeTimeView(lastFeedAt: feedAt)
          .font(.caption)
          .foregroundStyle(.white.opacity(0.82))

        Text(lastMealLine(lastFeedAt: feedAt))
          .font(.title3)
          .fontWeight(.semibold)
          .lineLimit(1)
          .foregroundStyle(.white)

        HStack(spacing: 6) {
          Image(systemName: "drop.fill")
            .font(.caption)
            .foregroundStyle(.orange)
          Text(feedMethodWithAmountLine(context: context))
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(1)
        }
      }

      Spacer()

      WalnieQuickAddButton(context: context, compact: false)
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct WalnieAvatarView: View {
  let context: ActivityViewContext<LiveActivitiesAppAttributes>

  var body: some View {
    if let path = walnieSharedDefaults.string(forKey: context.attributes.prefixedKey("avatar")),
      let image = UIImage(contentsOfFile: path)
    {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1))
    } else if let bundledImage = UIImage(named: "WinnieAvatar") {
      Image(uiImage: bundledImage)
        .resizable()
        .scaledToFill()
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1))
    } else {
      Image(systemName: "person.circle.fill")
        .resizable()
        .scaledToFit()
        .foregroundStyle(.white.opacity(0.9))
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct WalnieRelativeTimeView: View {
  let lastFeedAt: Date

  var body: some View {
    TimelineView(.periodic(from: .now, by: 60)) { context in
      Text(elapsedMealLine(lastFeedAt: lastFeedAt, now: context.date))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .allowsTightening(true)
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct WalnieQuickAddButton: View {
  let context: ActivityViewContext<LiveActivitiesAppAttributes>
  let compact: Bool

  var body: some View {
    Link(destination: quickActionURL(context: context)) {
      Circle()
        .fill(Color.orange)
        .frame(width: compact ? 36 : 52, height: compact ? 36 : 52)
        .overlay(
          Image(systemName: "plus")
            .font(.system(size: compact ? 18 : 24, weight: .semibold))
            .foregroundStyle(.black)
        )
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private func quickActionURL(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> URL {
  let urlRaw = walnieSharedDefaults.string(forKey: context.attributes.prefixedKey("quickActionUrl"))
    ?? walnieFallbackQuickActionUrl
  return URL(string: urlRaw) ?? URL(string: walnieFallbackQuickActionUrl)!
}

@available(iOSApplicationExtension 16.1, *)
private func lastFeedAt(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Date {
  let raw = walnieSharedDefaults.double(forKey: context.attributes.prefixedKey("lastFeedAtMs"))
  if raw <= 0 {
    return Date()
  }
  return Date(timeIntervalSince1970: raw / 1000)
}

@available(iOSApplicationExtension 16.1, *)
private func feedMethodLabel(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
  let useChinese = isChineseLanguage()

  if useChinese {
    if let zh = walnieSharedDefaults.string(forKey: context.attributes.prefixedKey("feedMethodZh")), !zh.isEmpty {
      return zh
    }
    return "瓶装母乳"
  }

  if let en = walnieSharedDefaults.string(forKey: context.attributes.prefixedKey("feedMethodEn")), !en.isEmpty {
    return en
  }
  return "Bottled breast milk"
}

private func isChineseLanguage() -> Bool {
  guard let language = Locale.preferredLanguages.first else {
    return false
  }
  return language.hasPrefix("zh")
}

private func formattedTime(lastFeedAt: Date) -> String {
  let formatter = DateFormatter()
  formatter.locale = Locale.current
  formatter.dateFormat = "HH:mm"
  return formatter.string(from: lastFeedAt)
}

@available(iOSApplicationExtension 16.1, *)
private func feedMethodWithAmountLine(
  context: ActivityViewContext<LiveActivitiesAppAttributes>
) -> String {
  let method = feedMethodLabel(context: context)
  guard let amount = feedAmountMl(context: context) else {
    return method
  }

  if isChineseLanguage() {
    return "\(method)  \(amount)ml"
  }
  return "\(method)  \(amount) ml"
}

@available(iOSApplicationExtension 16.1, *)
private func feedAmountMl(
  context: ActivityViewContext<LiveActivitiesAppAttributes>
) -> Int? {
  let key = context.attributes.prefixedKey("feedAmountMl")
  if let number = walnieSharedDefaults.object(forKey: key) as? NSNumber {
    let value = number.intValue
    return value > 0 ? value : nil
  }
  if let raw = walnieSharedDefaults.string(forKey: key), let value = Int(raw), value > 0 {
    return value
  }
  return nil
}

private func lastMealLine(lastFeedAt: Date) -> String {
  if isChineseLanguage() {
    return "上次干饭是 \(formattedTime(lastFeedAt: lastFeedAt))"
  }
  return "Last meal at \(formattedTime(lastFeedAt: lastFeedAt))"
}

private func elapsedMealLine(lastFeedAt: Date, now: Date) -> String {
  let elapsed = elapsedDurationText(lastFeedAt: lastFeedAt, now: now)
  if isChineseLanguage() {
    return "急急国王已经 \(elapsed) 没有干饭了"
  }
  return "No meal for \(elapsed)"
}

private func elapsedDurationText(lastFeedAt: Date, now: Date) -> String {
  let seconds = max(0, Int(now.timeIntervalSince(lastFeedAt)))
  let totalMinutes = max(1, (seconds + 59) / 60)

  if isChineseLanguage() {
    if totalMinutes < 60 {
      return "\(totalMinutes)分钟"
    }
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return "\(hours)小时\(minutes)分钟"
  }

  if totalMinutes < 60 {
    return "\(totalMinutes) min"
  }
  let hours = totalMinutes / 60
  let minutes = totalMinutes % 60
  return "\(hours)h \(minutes)m"
}
