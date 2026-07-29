// Widget kind MUST be "NotebookWidget" (matches HomeWidget.updateWidget iOSName).

import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.dime.tomotomo"

/// Endonym for `lang`, looked up by its index in the pushed cycle list — the same
/// mechanism Android uses, so there is only one way this is derived.
private func languageLabel(_ d: UserDefaults?, _ lang: String) -> String {
  func csv(_ key: String) -> [String] {
    (d?.string(forKey: key) ?? "")
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }
  let cycle = csv("notebook_widget_langs")
  let labels = csv("notebook_widget_labels")
  guard let i = cycle.firstIndex(of: lang), labels.indices.contains(i) else {
    return lang
  }
  return labels[i]
}

struct NotebookEntry: TimelineEntry {
  let date: Date
  /// Language name in its own script (한국어 / 日本語 / English / 中文).
  let langLabel: String
  /// Chrome text, localized by the app — this extension cannot reach AppStrings,
  /// so it used to render hardcoded Japanese for every user.
  let title: String
  let emptyText: String
  let lines: [String]
}

struct NotebookProvider: TimelineProvider {
  func placeholder(in context: Context) -> NotebookEntry {
    NotebookEntry(
      date: Date(), langLabel: "한국어", title: "단어장",
      emptyText: "저장한 단어가 없습니다", lines: ["…"])
  }

  func getSnapshot(in context: Context, completion: @escaping (NotebookEntry) -> Void) {
    completion(readEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<NotebookEntry>) -> Void) {
    let entry = readEntry()
    let next = Date().addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func readEntry() -> NotebookEntry {
    let d = UserDefaults(suiteName: widgetGroupId)
    let lang = d?.string(forKey: "notebook_widget_lang") ?? "ko"
    // One slot per language: hardcoding ko/ja meant an English or Chinese
    // learner's words were never shown, only the Korean slot.
    let raw = d?.string(forKey: "notebook_widget_payload_\(lang)") ?? "[]"
    return NotebookEntry(
      date: Date(),
      langLabel: languageLabel(d, lang),
      title: d?.string(forKey: "notebook_widget_title") ?? "단어장",
      emptyText: d?.string(forKey: "notebook_widget_empty") ?? "저장한 단어가 없습니다",
      lines: parseLines(raw))
  }

  private func parseLines(_ json: String) -> [String] {
    guard let data = json.data(using: .utf8),
          let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return arr.prefix(5).compactMap { o in
      let c = (o["c"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let t = (o["t"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if c.isEmpty && t.isEmpty { return nil }
      if t.isEmpty { return c }
      if c.isEmpty { return t }
      return "\(c)  ·  \(t)"
    }
  }
}

struct NotebookWidgetView: View {
  var entry: NotebookProvider.Entry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(entry.title)
        .font(.headline)
      Text(entry.langLabel)
        .font(.caption)
        .foregroundColor(.secondary)
      if entry.lines.isEmpty {
        Text(entry.emptyText)
          .font(.caption)
      } else {
        ForEach(Array(entry.lines.enumerated()), id: \.offset) { _, line in
          Text(line)
            .font(.subheadline)
            .lineLimit(2)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(12)
  }
}

@main
struct NotebookWidgetBundle: WidgetBundle {
  var body: some Widget {
    NotebookWidget()
  }
}

struct NotebookWidget: Widget {
  let kind: String = "NotebookWidget"

  /// Gallery strings come from the App Group, like the rest of the widget's
  /// text, so they follow the language chosen in the app. Localizing them
  /// natively would need a strings catalog added to this target.
  private var galleryStrings: (name: String, description: String) {
    let d = UserDefaults(suiteName: widgetGroupId)
    return (
      d?.string(forKey: "notebook_widget_title") ?? "단어장",
      d?.string(forKey: "notebook_widget_gallery_desc")
        ?? "저장한 단어를 홈 화면에 보여줍니다."
    )
  }

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NotebookProvider()) { entry in
      NotebookWidgetView(entry: entry)
    }
    .configurationDisplayName(galleryStrings.name)
    .description(galleryStrings.description)
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
