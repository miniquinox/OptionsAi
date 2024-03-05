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
        return percentage > 50 ? "arrow.up.right" : "arrow.down.right"
    }
    var color: Color {
        return percentage > 50 ? .green : .red
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
                    .padding() // Add padding
                    .background(Color(.systemBackground)) // Add a background color
                    .cornerRadius(10) // Add rounded corners
                    .shadow(radius: 5) // Add a shadow
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("OptionsAi")
            .navigationBarItems(trailing: Button(action: {
                loadSampleData { result in
                    switch result {
                    case .success(let data):
                        // Handle the loaded data
                        print("Data loaded successfully: \(data)")
                    case .failure(let error):
                        // Handle the error
                        print("Error loading data: \(error)")
                    }
                }
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
                    var optionsData = try decoder.decode([OptionsData].self, from: data)
                    optionsData.reverse() // Reverse the order of the data
                    completion(.success(optionsData))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }

    private func color(for percentage: Double) -> Color {
        // use red with rgb: 251, 55, 5, and green with rgb: 25, 194, 6
        return percentage > 50 ? Color(red: 25/255, green: 194/255, blue: 6/255) : Color(red: 251/255, green: 55/255, blue: 5/255)
    }

    private func background(for percentage: Double) -> Color {
        // use red with rgb: 251, 55, 5, and green with rgb: 25, 194, 6
        percentage > 50 ? Color(red: 25/255, green: 194/255, blue: 6/255) : Color(red: 251/255, green: 55/255, blue: 5/255)
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
