import Foundation

struct Dog: Codable, CustomStringConvertible {
    let id: Int
    var name: String
    var breed: String
    var description: String { "\(name) is a \(breed)" }
}

// This only differs from Dog in that it doesn't have an id property.
struct NewDog: Codable, CustomStringConvertible {
    var name: String
    var breed: String
    var description: String { "\(name) is a \(breed)" }
}

// This defines a custom error type.
enum HTTPError: Error {
    case badStatus(status: Int)
    case badUrl
    case jsonEncode
}

extension HTTPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badStatus(let status):
            return "bad status \(status)"
        case .badUrl:
            return "bad URL"
        case .jsonEncode:
            return "JSON encoding failed"
        }
    }
}

class ViewModel: ObservableObject {
    @Published var dogs: [Dog] = []

    private static let url = "http://localhost:8001/dog"

    func deleteDog(id: Int) async throws {
        return try await HttpUtil.delete(from: ViewModel.url, id: id)
    }

    func getDog(id: Int) async throws -> Dog {
        let url = "\(ViewModel.url)/\(id)"
        return try await HttpUtil.get(from: url, type: Dog.self)
    }

    func getDogs() async throws -> [Dog] {
        return try await HttpUtil.get(from: ViewModel.url, type: [Dog].self)
    }

    func postDog(_ dog: NewDog) async throws -> Dog {
        return try await HttpUtil.post(
            to: ViewModel.url,
            with: dog,
            type: Dog.self
        )
    }

    func putDog(_ dog: Dog) async throws -> Dog {
        let url = "\(ViewModel.url)/\(dog.id)"
        return try await HttpUtil.put(to: url, with: dog, type: Dog.self)
    }

    init() {
        Task(priority: .medium) {
            do {
                // Create a new dog.
                let newDog = try await postDog(
                    NewDog(name: "Clarice", breed: "Whippet")
                )
                print("created dog with id \(newDog.id)")

                // Get the dog with id 1.
                var dog = try await getDog(id: 1)
                print("first dog =", dog)

                // Update an existing dog.
                dog.name = "Moo"
                dog.breed = "Cow"
                _ = try await putDog(dog)

                // Delete an existing dog.
                try await deleteDog(id: 2)

                // Get all the dogs.
                let fetchedDogs = try await getDogs()
                for dog in fetchedDogs {
                    print("\(dog.name) is a \(dog.breed)")
                }

                // Update the published property dogs in the main thread.
                DispatchQueue.main.async { [weak self] in
                    self?.dogs = fetchedDogs
                }
            } catch {
                print("error =", error.localizedDescription)
            }
        }
    }
}
