import SwiftUI
import SwiftUISSG
import Swim
import HTML

func staticSite() {
    write("Hello, world", to: "index.html")
    blog()
}

func blog() {
    let files = readDir()
    for file in files {
        let content = readFile(file)
        write(content.markdown(),
              to: file.baseName + ".html")
    }
}

func readFile(_ name: String) -> String {
    fatalError()
}

func readDir() -> [String] {
    fatalError()
}

func write(_ input: String, to: String) {
    fatalError()
}

func write(_ input: Node, to: String) {
    fatalError()
}
