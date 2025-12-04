//
//  NiftiTest2App.swift
//  NiftiTest2
//
//  Created by Zaher Rezai on 02/12/2025.
//

import SwiftUI

@main
struct NiftiTest2App: App {
	@StateObject var VM = viewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
				.environmentObject(VM)
        }
    }
}
