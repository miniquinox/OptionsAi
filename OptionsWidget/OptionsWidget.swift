import WidgetKit
import SwiftUI

// MARK: - Model
struct OptionsData: Identifiable, Codable {
    let id: String
    let percentage: Double
    var symbol: String {
        return percentage > 50 ? "arrow.up.right" : "arrow.down.right"
    }
    var color: Color {
        return percentage > 50 ? .green : .red
    }
}

// MARK: - Data Provider Function
func loadSampleData() -> [OptionsData] {
    guard let url = Bundle.main.url(forResource: "options_data", withExtension: "json") else {
        fatalError("Failed to locate options_data.json in bundle.")
    }

    guard let data = try? Data(contentsOf: url) else {
        fatalError("Failed to load options_data.json from bundle.")
    }

    let decoder = JSONDecoder()
    guard let loaded = try? decoder.decode([OptionsData].self, from: data) else {
        fatalError("Failed to decode options_data.json from bundle.")
    }

    return loaded
}

// MARK: - Widget Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let optionsData: [OptionsData]
}

// MARK: - Widget Entry View
struct OptionsWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("OptionsAi")
                .font(.system(size: 20))
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.vertical, 2)

            ForEach(entry.optionsData.indices, id: \.self) { index in
                HStack {
                    Text(entry.optionsData[index].id)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Spacer()
                    Text("\(entry.optionsData[index].percentage, specifier: "%.2f")%")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .background(entry.optionsData[index].percentage > 50 ? Color.green : Color.red)
                        .cornerRadius(5) // Less rounded corners
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 4) // Add vertical padding to create space for the Divider

                // Grey spacer bar, conditionally added if not the last item
                if index < entry.optionsData.count - 1 {
                    Divider()
                        .background(colorScheme == .dark ? .white : .gray)
                        .padding(.leading, 5) // Left padding to align with the text
                        .padding(.trailing, 5) // Right padding to align with the percentage boxes
                        .padding(.vertical, 4) // Vertical padding to ensure the Divider is centered between options
                }
            }
            Spacer() // This will push all the content to the top
        }
        .background(colorScheme == .dark ? Color.black : Color.white) // Background color for the VStack
        .cornerRadius(10) // Apply corner radius to VStack
        .edgesIgnoringSafeArea(.all) // Extend to the edges of the widget
    }
}


// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), optionsData: loadSampleData())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), optionsData: loadSampleData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entries = [SimpleEntry(date: Date(), optionsData: loadSampleData())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}


// MARK: - Widget
struct OptionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.optimiz3d.OptionsApp.OptionsWidget", provider: Provider()) { entry in
            OptionsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Options Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemMedium, .systemLarge])    }
}


// MARK: - Widget Previews
struct OptionsWidget_Previews: PreviewProvider {
    static var previews: some View {
        OptionsWidgetEntryView(entry: SimpleEntry(date: Date(), optionsData: loadSampleData()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark) // Preview in dark mode
    }
}
