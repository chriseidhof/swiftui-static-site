import SwiftUI
import SwiftUISSG
import Swim
import HTML

func staticSite1() {
    write("Hello, world", to: "index.html")
    blog()
}

func blog1() {
    readDir1 { files in
        forEach(files) { file in
            post(file)
        }
    }
}

func post(_ file: String) {
    readFile1(file) { content in
        write1(content.markdown(),
              to: file.baseName + ".html")
    }
}

func readFile1(_ name: String, process: @escaping (String) -> ()) {
    fatalError()
}

func forEach(_ files: [String], process: @escaping (String) -> ()) {
    fatalError()
}

func readDir1(_ process: @escaping ([String]) -> ()) {
    fatalError()
}

func write1(_ input: String, to: String) {
    fatalError()
}

func write1(_ input: Node, to: String) {
    fatalError()
}
