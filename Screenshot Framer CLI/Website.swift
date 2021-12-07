//
//  Website.swift
//  Screenshot-Framer-CLI
//
//  Created by Patrick Kladek on 25.11.21.
//  Copyright © 2021 Patrick Kladek. All rights reserved.
//

import ArgumentParser
import Foundation
import SwiftSoup

final class Website: ParsableCommand {

    @Option(help: "Root Folder of export", completion: .file(), transform: URL.init(fileURLWithPath:))
    var exportFolder: URL

    // MARK: - Export

    func run() throws {
        //try self.makeHTML()
        try self.makeBody()
    }
}

// MARK: - Private

private extension Website {

    func makeHTML() throws {
        let string = WebsiteTemplate.template
        let doc: Document = try SwiftSoup.parse(string)

        guard let body = doc.body() else { fatalError("Template malformatted") }

        let language = try body.select("div")
        guard let languageTable = try language.select("table").first() else { fatalError("Template malformatted") }

        print(languageTable)

        let languageTable1 = try self.makeLanguageSection()
        try doc.normalise()
        print(try languageTable1.html())
    }

    func makeBody() throws {
        let body = Element(Tag("body"), "")

        // Make SortMenu
        let sort = try self.makeSortMenu()
        try body.addChildren(sort)

        // Make byLanguage
        let language = try self.makeLanguageSection()
        try body.addChildren(language)

        // Make byScreen

        // Make overlay

        // Make Script

        print(body)
    }

    func makeSortMenu() throws -> Element {
        let div = Element(Tag("div"), "")
        try div.attr("id", "sortMenu")

        let byLanguage = Element(Tag("button"), "")
        try byLanguage.attr("id", "defaultTab")
        try byLanguage.attr("class", "tabLink")
        try byLanguage.attr("onClick", "openTab(event, 'byLanguage')")
        try byLanguage.addChildren(TextNode("By Language", nil))
        try div.addChildren(byLanguage)

        let byScreen = Element(Tag("button"), "")
        try byScreen.attr("class", "tabLink")
        try byScreen.attr("onclick", "openTab(event, 'byScreen')")
        try byScreen.addChildren(TextNode("By Screen", nil))
        try div.addChildren(byScreen)

        return div
    }

    func makeLanguageSection() throws -> Element {
        let div = Element(Tag("div"), "")
        try div.attr("id", "byLanguage")
        try div.attr("class", "tabContent")

        let header1 = try div.appendElement("h1")
        try header1.attr("class", "tabTitle")
        try header1.addChildren(TextNode("By Language", nil))

        let imageParser = ImagesParser()
        let languages = try imageParser.languages(in: self.exportFolder)

        var index: Int = 0
        for language in languages {
            let header2 = try div.appendElement("h2")
            try header2.attr("id", language.language)
            try header2.appendText(language.language)

            try div.appendElement("hr")

            let table = try self.makeLanguageTable(language, offset: index)
            try div.addChildren(table.element)
            index = table.index
        }

        return div
    }

    func makeLanguageTable(_ language: ImagesParser.Language, offset: Int) throws -> (element: Element, index: Int) {
        let table = Element(Tag("table"), "")

        var index = offset
        for group in language.groups {
            let header = try self.makeTitleRow(for: group.name)
            try table.addChildren(header)

            let content = try self.makeContentRow(with: group.images.map { $0.url }, offset: index)
            try table.addChildren(content.element)
            index = content.index
        }

        return (table, index)
    }

    func makeTitleRow(for device: String) throws -> Element {
        let tableRow = Element(Tag("tr"), "")

        let tableHeader = Element(Tag("th"), "")
        try tableHeader.attr("colspan", "1")

        let content = Element(Tag("a"), "")
        try content.attr("id", device)
        try content.attr("class", "deviceName")
        try content.attr("href", "#\(device)")

        let text = TextNode(device, nil)

        try content.addChildren(text)
        try tableHeader.addChildren(content)
        try tableRow.addChildren(tableHeader)

        return tableRow
    }

    func makeContentRow(with images: [URL], offset: Int) throws -> (element: Element, index: Int) {
        let tableRow = Element(Tag("tr"), "")

        var index = offset
        for image in images {
            index += 1
            let tableData = try tableRow.appendElement("td")

            let content = try tableData.appendElement("a")
            try content.attr("href", "\(image.relativePath)")
            try content.attr("target", "_blank")
            try content.attr("class", "screenshotLink")

            let img = try content.appendElement("img")
            try img.attr("class", "screenshot")
            try img.attr("src", image.relativePath)
            try img.attr("style", "width: 100%;")
            try img.attr("alt", image.relativePath)
            try img.attr("data-tab", "1")
            try img.attr("data-counter", "\(index)")
        }

        return (tableRow, index)
    }
}
