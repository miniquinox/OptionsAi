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
        return percentage > 40 ? "arrow.up.right" : "arrow.down.right"
    }
    var color: Color {
        // use red with rgb: 251, 55, 5, and green with rgb: 25, 194, 6
        return percentage > 40 ? Color(red: 25/255, green: 194/255, blue: 6/255) : Color(red: 251/255, green: 55/255, blue: 5/255)
    }
}

// MARK: - Data Provider Function
func loadSampleDataSync() -> [OptionsData] {
    let repo = "miniquinox/OptionsAi"
    let filePath = "options_data_2.json"
    let apiUrl = "https://api.github.com/repos/\(repo)/commits?path=\(filePath)&page=1&per_page=1"
    let headers = ["Accept": "application/vnd.github.v3+json"]

    var request = URLRequest(url: URL(string: apiUrl)!)
    request.allHTTPHeaderFields = headers
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

    let semaphore = DispatchSemaphore(value: 0)
    var result: [OptionsData] = []

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let data = data {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let latestCommitHash = json[0]["sha"] as? String {
                    let rawUrl = "https://raw.githubusercontent.com/\(repo)/\(latestCommitHash)/\(filePath)"
                    let fileRequest = URLRequest(url: URL(string: rawUrl)!)

                    let fileTask = URLSession.shared.dataTask(with: fileRequest) { (fileData, fileResponse, fileError) in
                        if let fileData = fileData {
                            do {
                                let decoder = JSONDecoder()
                                result = try decoder.decode([OptionsData].self, from: fileData)
                                semaphore.signal()
                            } catch {
                                print("Failed to decode JSON: \(error)")
                                semaphore.signal()
                            }
                        } else if let fileError = fileError {
                            print("Failed to load data: \(fileError)")
                            semaphore.signal()
                        }
                    }
                    fileTask.resume()
                }
            } catch {
                print("Failed to decode JSON: \(error)")
                semaphore.signal()
            }
        } else if let error = error {
            print("Failed to load data: \(error)")
            semaphore.signal()
        }
    }
    task.resume()

    semaphore.wait()
    return result
}


func loadSampleData(completion: @escaping (Result<[OptionsData], Error>) -> Void) {
    let repo = "miniquinox/OptionsAi"
    let filePath = "options_data_2.json"
    let apiUrl = "https://api.github.com/repos/\(repo)/commits?path=\(filePath)&page=1&per_page=1"
    let headers = ["Accept": "application/vnd.github.v3+json"]

    var request = URLRequest(url: URL(string: apiUrl)!)
    request.allHTTPHeaderFields = headers
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            completion(.failure(error))
        } else if let data = data {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let latestCommitHash = json[0]["sha"] as? String {
                    let rawUrl = "https://raw.githubusercontent.com/\(repo)/\(latestCommitHash)/\(filePath)"
                    let fileRequest = URLRequest(url: URL(string: rawUrl)!)

                    let fileTask = URLSession.shared.dataTask(with: fileRequest) { (fileData, fileResponse, fileError) in
                        if let fileError = fileError {
                            completion(.failure(fileError))
                        } else if let fileData = fileData {
                            do {
                                let decoder = JSONDecoder()
                                let optionsData = try decoder.decode([OptionsData].self, from: fileData)
                                completion(.success(optionsData))
                            } catch {
                                completion(.failure(error))
                            }
                        }
                    }
                    fileTask.resume()
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    task.resume()
}

// MARK: - View Extension for Background Compatibility
extension View {
    @ViewBuilder
    func widgetBackground<T: View>(_ backgroundView: T) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { backgroundView }
        } else {
            background(backgroundView)
        }
    }
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
            if let lastOption = entry.optionsData.last {
                HStack {
                    Text("QuinOptionsAi")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text("- \(lastOption.date)")
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 2)
                .padding(.top) // Add padding to the top of the HStack

                if lastOption.options.isEmpty {
                    HStack {
                        Text("No Option Picks Today")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Spacer() // This pushes the above views to the left
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 4)
                    Spacer() // This pushes the above views to the top

                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(lastOption.options.indices, id: \.self) { optionIndex in
                            HStack {
                                Text(lastOption.options[optionIndex].id)
                                    .font(.system(size: 16))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(lastOption.options[optionIndex].percentage, specifier: "%.2f")%")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                    .background(lastOption.options[optionIndex].percentage > 40 ? Color(red: 25/255, green: 194/255, blue: 6/255) : Color(red: 251/255, green: 55/255, blue: 5/255))
                                    .cornerRadius(5)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 4)

                            if optionIndex < lastOption.options.count - 1 {
                                Divider()
                                    .background(colorScheme == .dark ? .white : .gray)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                    Spacer() // This pushes the above views to the top
                }
            }
        }
        .widgetBackground(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(10)
        .edgesIgnoringSafeArea(.all)
        .padding(.horizontal) // Add horizontal padding
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
            case .failure(_):
                let entry = SimpleEntry(date: Date(), optionsData: [])
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        loadSampleData { result in
            let currentDate = Date()
            let refreshDate = Calendar.current.date(byAdding: .second, value: 10, to: currentDate)!
            let entries: [SimpleEntry]
            
            switch result {
            case .success(let optionsData):
                entries = [SimpleEntry(date: currentDate, optionsData: optionsData)]
            case .failure(_):
                entries = [SimpleEntry(date: currentDate, optionsData: [])]
            }
            
            let timeline = Timeline(entries: entries, policy: .after(refreshDate))
            completion(timeline)
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
        .contentMarginsDisabled() // Disable content margins for iOS 17
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
