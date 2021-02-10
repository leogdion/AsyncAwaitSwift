import Foundation

struct AsyncDemo {
    var text = "Hello, World!"
}

struct EmptyError : Error {
  static public let shared = EmptyError()
}

extension Optional {
  func unwrap<Failure>(_ failure: @autoclosure @escaping () -> Failure) -> Result<Wrapped, Failure> {
    switch self {
    case .some(let value):
      return .success(value)
    case .none:
      return .failure(failure())
    }
  }
}

extension Result {
  
  
  init(_ success: Success?, _ error: Failure?, _ empty: @autoclosure @escaping () -> Failure) {
    if let error = error {
      self = .failure(error)
    } else if let success = success {
      self = .success(success)
    } else {
      self = .failure( empty())
    }
  }
}

extension CheckedThrowingContinuation {
  func resume(with result: Result<T,Error>) {
    switch result {
    case .success(let value):
      return self.resume(returning: value)
    case .failure(let error):
      return self.resume(throwing: error)
    }
  }
}

 func markdown() async throws  -> String {
  let url = URL(string:
   "https://jaspervdj.be/lorem-markdownum/markdown.txt")!

  
  return try await withCheckedThrowingContinuation { continuation in
    URLSession.shared.dataTask(with: url) {
     (data, response, error) in
      
      let data : Result<Data, Error> = Result<Data, Error>.init(data, error, EmptyError.shared)

      let string = data.flatMap { data in
        String(bytes: data, encoding: .utf8).unwrap(EmptyError.shared)
      }
    
      continuation.resume(with: string)
    }.resume()
  }

}

func value(withValue value: Int) async  -> Int {

 
 return await withCheckedContinuation { continuation in
  sleep(.random(in: 5...10))
  
  continuation.resume(returning: value)
  }
 

}

func values(withCount count: Int) async throws -> [Int] {
  return try await Task.withGroup(resultType: Int.self, returning: [Int].self) { group in
    for index in 0...count {
      await group.add {
        await value(withValue: index)
      }
    }
    var collected = [Int]()
    while let value = try await group.next() {
      collected.append(value)
    }
    return collected
  }
}

func markdowns () async throws -> [String] {
  return try await Task.withGroup(resultType: String.self, returning: [String].self) { group in
    for _ in 0...9 {
      await group.add {
        try await markdown()
      }
    }
    var collected = [String]()
    while let value = try await group.next() {
      collected.append(value)
    }
    return collected
  }
}


runAsyncAndBlock {
  let valueArray : [Int]
  do {
    valueArray = try await values(withCount: 10)
  } catch {
    debugPrint(error)
    return
  }
  debugPrint(valueArray)
}


