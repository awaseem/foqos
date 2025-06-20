//
//  FoqosWidget.swift
//  FoqosWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), emoji: "😀")
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(date: Date(), emoji: "😀")
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    var entries: [SimpleEntry] = []

    let currentDate = Date()
    for hourOffset in 0..<5 {
      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
      let entry = SimpleEntry(date: entryDate, emoji: "😀")
      entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let emoji: String
}

struct FoqosWidgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack {
      Text("Time:")
      Text(entry.date, style: .time)

      Text("Emoji:")
      Text(entry.emoji)
    }
  }
}

struct FoqosWidget: Widget {
  let kind: String = "FoqosWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      if #available(iOS 17.0, *) {
        FoqosWidgetEntryView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        FoqosWidgetEntryView(entry: entry)
          .padding()
          .background()
      }
    }
    .configurationDisplayName("My Widget")
    .description("This is an example widget.")
  }
}

#Preview(as: .systemSmall) {
  FoqosWidget()
} timeline: {
  SimpleEntry(date: .now, emoji: "😀")
  SimpleEntry(date: .now, emoji: "🤩")
}
