//
//  FileSelectorView.swift
//  SwiftBeanCountApp
//
//  Created by Steffen Kötte on 2020-06-01.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

import SwiftUI

struct FileSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        FileSelectorView(allowedFileTypes: ["beancount"], url: .constant(nil))
    }
}

struct FileSelectorView: View {

    private let allowedFileTypes: [String]

    @Binding private var url: URL?

    var body: some View {
        VStack(alignment: .leading) {
            if url != nil {
                Text(url!.lastPathComponent).fixedSize()
            } else {
                Text("Please select...").italic()
            }
            Button("Choose file") {
                self.selectFile()
            }
        }
    }

    init(allowedFileTypes: [String], url: Binding<URL?>) {
        self.allowedFileTypes = allowedFileTypes
        self._url = url
    }

    private func selectFile() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = allowedFileTypes
        openPanel.begin { response in
            if response == .OK {
                self.url = openPanel.url
            }
        }
    }
}
