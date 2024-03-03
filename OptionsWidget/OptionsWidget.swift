import WidgetKit
import SwiftUI

// MARK: - Model
struct OptionsData: Identifiable, Codable {
    let id = UUID()
    let date: String
    let options: [Option]
}

struct Option: Identifiable, Codable {
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
func loadSampleDataSync() -> [OptionsData] {
    let url = URL(string: "https://raw.githubusercontent.com/miniquinox/OptionsAi/main/options_data_2.json")!
    var request = URLRequest(url: url)
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

    let semaphore = DispatchSemaphore(value: 0)
    var result: [OptionsData] = []

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let data = data {
            do {
                let decoder = JSONDecoder()
                result = try decoder.decode([OptionsData].self, from: data)
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        } else if let error = error {
            print("Failed to load data: \(error)")
        }
        semaphore.signal()
    }
    task.resume()

    semaphore.wait()
    return result
}

func loadSampleData(completion: @escaping (Result<[OptionsData], Error>) -> Void) {
    let url = URL(string: "https://raw.githubusercontent.com/miniquinox/OptionsAi/main/options_data_2.json")!

    // Create a URL request that disables caching
    var request = URLRequest(url: url)
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            completion(.failure(error))
        } else if let data = data {
            do {
                let decoder = JSONDecoder()
                let optionsData = try decoder.decode([OptionsData].self, from: data)
                completion(.success(optionsData))
            } catch {
                completion(.failure(error))
            }
        }
    }
    task.resume()
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
            // Get the last element in the optionsData array
            if let lastOption = entry.optionsData.last {
                HStack {
                    Text("OptionsAi")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Text("-  \(lastOption.date)")
                        .font(.system(size: 16)) // Adjust the font size here
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(lastOption.options.indices, id: \.self) { optionIndex in
                        HStack {
                            Text(lastOption.options[optionIndex].id)
                                .font(.system(size: 14))
                                .lineLimit(1)
                            Spacer()
                            Text("\(lastOption.options[optionIndex].percentage, specifier: "%.2f")%")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                .background(lastOption.options[optionIndex].percentage > 50 ? Color.green : Color.red)
                                .cornerRadius(5) // Less rounded corners
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 4) // Add vertical padding to create space for the Divider

                        // Grey spacer bar, conditionally added if not the last item
                        if optionIndex < lastOption.options.count - 1 {
                            Divider()
                                .background(colorScheme == .dark ? .white : .gray)
                                .padding(.leading, 5) // Left padding to align with the text
                                .padding(.trailing, 5) // Right padding to align with the percentage boxes
                                .padding(.vertical, 4) // Vertical padding to ensure the Divider is centered between options
                        }
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white) // Background color for the VStack
        .cornerRadius(10) // Apply corner radius to VStack
        .edgesIgnoringSafeArea(.all) // Extend to the edges of the widget
        .padding(0) // Remove default padding
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), optionsData: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        loadSampleData { result in
            switch result {
            case .success(let optionsData):
                let entry = SimpleEntry(date: Date(), optionsData: optionsData)
                completion(entry)
            case .failure(let error):
                print(error)
                let entry = SimpleEntry(date: Date(), optionsData: [])
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        loadSampleData { result in
            switch result {
            case .success(let optionsData):
                let currentDate = Date()
                let refreshDate = Calendar.current.date(byAdding: .second, value: 10, to: currentDate)!
                let entries = [SimpleEntry(date: currentDate, optionsData: optionsData)]
                let timeline = Timeline(entries: entries, policy: .after(refreshDate))
                completion(timeline)
            case .failure(let error):
                print(error)
                let currentDate = Date()
                let refreshDate = Calendar.current.date(byAdding: .second, value: 10, to: currentDate)!
                let entries = [SimpleEntry(date: currentDate, optionsData: [])]
                let timeline = Timeline(entries: entries, policy: .after(refreshDate))
                completion(timeline)
            }
        }
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
        .supportedFamilies([.systemMedium, .systemLarge])
    }
    
    func clearCache() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}


// MARK: - Widget Previews
struct OptionsWidget_Previews: PreviewProvider {
    static var previews: some View {
        OptionsWidgetEntryView(entry: SimpleEntry(date: Date(), optionsData: loadSampleDataSync()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark) // Preview in dark mode
    }
}
