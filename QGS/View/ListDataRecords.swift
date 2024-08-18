//
//  ContentView.swift
//  test
//
//  Created by Edin Martinez on 8/13/24.
//

import SwiftUI
import CoreData

struct ListDataRecords: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordEntity.date, ascending: true)],
        animation: .default)
    private var items: FetchedResults<RecordEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.times!)")
//                        Text("Item at \(item.date!)")
//                    } label: {
//                        Text(item.time!)
//                        Text(item.date!, formatter: itemFormatter)
//                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = RecordEntity(context: viewContext)
            newItem.date = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
   // formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ListDataRecords().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

