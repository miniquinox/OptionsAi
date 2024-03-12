import SwiftUI

// Ensure that your OptionsData and Option structs are defined either above this view or in a separate file.

struct OptionsData: Identifiable, Codable {
    let id = UUID()
    let date: String
    let options: [Option]
}

struct Option: Identifiable, Codable {
    let id: String
    let percentage: Double
    var symbol: String {
        return percentage > 30 ? "arrow.up.right" : "arrow.down.right"
    }
    var color: Color {
        return percentage > 30 ? .green : .red
    }
}

struct ContentView: View {
    @State private var optionsData: [OptionsData] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                ForEach(optionsData, id: \.id) { dailyOptions in
                    VStack(alignment: .leading) {
                        Text("Options for \(dailyOptions.date)")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.bottom, 5)
                        
                        if dailyOptions.options.isEmpty {
                            Text("No Option Picks Today")
                                .foregroundColor(colorScheme == .dark ? .white : .black)

                        } else {
                            ForEach(dailyOptions.options) { option in
                                HStack {
                                    Text(option.id)
                                        .lineLimit(1)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    Spacer()
                                    Text("\(option.percentage, specifier: "%.2f")%")
                                        .foregroundColor(.white)
                                        .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                        .background(background(for: option.percentage))
                                        .cornerRadius(5)
                                }
                            }
                        }
                    }
                    .padding() // Add padding
                    .background(Color(.systemBackground)) // Add a background color
                    .cornerRadius(10) // Add rounded corners
                    .shadow(radius: 5) // Add a shadow
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("QuinOptionsAi")
            .navigationBarItems(trailing: Button(action: {
                loadData() // This calls your loadData function to refresh the data
            }, label: {
                Image(systemName: "arrow.clockwise")
            }))
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        loadSampleData { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self.optionsData = data
                }
            case .failure(let error):
                print("Failed to load data: \(error)")
            }
        }
    }

    func loadSampleData(completion: @escaping (Result<[OptionsData], Error>) -> Void) {
        let repo = "miniquinox/OptionsAi"
        let filePath = "options_data_2.json"
        let apiUrl = "https://api.github.com/repos/\(repo)/commits?path=\(filePath)&page=1&per_page=1"
        let headers = ["Accept": "application/vnd.github.v3+json"]

        var request = URLRequest(url: URL(string: apiUrl)!)
        request.allHTTPHeaderFields = headers

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } else if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                       let latestCommitHash = json[0]["sha"] as? String {
                        let rawUrl = "https://raw.githubusercontent.com/\(repo)/\(latestCommitHash)/\(filePath)"
                        let fileRequest = URLRequest(url: URL(string: rawUrl)!)

                        let fileTask = URLSession.shared.dataTask(with: fileRequest) { (fileData, fileResponse, fileError) in
                            if let fileError = fileError {
                                DispatchQueue.main.async {
                                    completion(.failure(fileError))
                                }
                            } else if let fileData = fileData {
                                do {
                                    let decoder = JSONDecoder()
                                    var optionsData = try decoder.decode([OptionsData].self, from: fileData)
                                    optionsData.reverse() // Reverse the order of the data
                                    print(optionsData)

                                    DispatchQueue.main.async {
                                        completion(.success(optionsData))
                                    }
                                } catch {
                                    DispatchQueue.main.async {
                                        completion(.failure(error))
                                    }
                                }
                            }
                        }
                        fileTask.resume()
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        task.resume()
    }

    private func color(for percentage: Double) -> Color {
        // use red with rgb: 251, 55, 5, and green with rgb: 25, 194, 6
        return percentage > 30 ? Color(red: 25/255, green: 194/255, blue: 6/255) : Color(red: 251/255, green: 55/255, blue: 5/255)
    }

    private func background(for percentage: Double) -> Color {
        // use red with rgb: 251, 55, 5, and green with rgb: 25, 194, 6
        percentage > 30 ? Color(red: 25/255, green: 194/255, blue: 6/255) : Color(red: 251/255, green: 55/255, blue: 5/255)
    }
}

// Below is your preview provider
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
