// Widget kind MUST be "NotebookWidget" (matches HomeWidget.updateWidget iOSName).

import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.dime.tomotomo"

struct NotebookEntry: TimelineEntry {
  let date: Date
  let lang: String
  let lines: [String]
}

struct NotebookProvider: TimelineProvider {
  func placeholder(in context: Context) -> NotebookEntry {
    NotebookEntry(date: Date(), lang: "ko", lines: ["…"])
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
    let key = lang == "ja" ? "notebook_widget_payload_ja" : "notebook_widget_payload_ko"
    let raw = d?.string(forKey: key) ?? "[]"
    return NotebookEntry(date: Date(), lang: lang, lines: parseLines(raw))
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
      Text("単語帳")
        .font(.headline)
      Text(entry.lang == "ja" ? "日本語" : "韓国語")
        .font(.caption)
        .foregroundColor(.secondary)
      if entry.lines.isEmpty {
        Text("保存した単語はありません")
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

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: NotebookProvider()) { entry in
      NotebookWidgetView(entry: entry)
    }
    .configurationDisplayName("単語帳")
    .description("保存した単語をホーム画面に表示します。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
