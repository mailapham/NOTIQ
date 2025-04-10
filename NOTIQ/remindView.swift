//
//  remindView.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import SwiftUI

struct remindView: View {
    @ObservedObject var RemindInfo: remindInfo
    
    @State private var isDeleting = false
    @State private var taskToDelete: remindModel?
    @State private var showDeleteAlert = false
    @State private var showingAddTaskSheet = false
    @State private var taskToEdit: remindModel?
    
    var body: some View {
        NavigationView {
            VStack {
                if RemindInfo.tasks.isEmpty && RemindInfo.completedTasks.isEmpty {
                    Text("No Tasks")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        // section for current tasks
                        if !RemindInfo.tasks.isEmpty {
                            Section(header: Text("Tasks")) {
                                ForEach(RemindInfo.tasks) { task in
                                    RemindRowView(task: task, isDeleting: $isDeleting, onDelete: {
                                        taskToDelete = task
                                        showDeleteAlert = true
                                    }, onEdit: {
                                        taskToEdit = task
                                        showingAddTaskSheet = true
                                    }, onToggleComplete: {
                                        RemindInfo.markTaskAsDone(task: task)
                                    })
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            taskToDelete = task
                                            showDeleteAlert = true
                                        }) {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        .tint(.red)

                                        Button(action: {
                                            taskToEdit = task
                                            showingAddTaskSheet = true
                                        }) {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                        
                        // section for completedTasks
                        if !RemindInfo.completedTasks.isEmpty {
                            Section(header: Text("Completed Tasks")) {
                                ForEach(RemindInfo.completedTasks) { task in
                                    RemindRowView(task: task, isDeleting: $isDeleting, onDelete: {
                                        taskToDelete = task
                                        showDeleteAlert = true
                                    }, onEdit: {
                                        taskToEdit = task
                                        showingAddTaskSheet = true
                                    }, onToggleComplete: {
                                        RemindInfo.markTaskAsUndone(task: task)
                                    })
                                    .swipeActions {
                                        Button(role: .destructive, action: {
                                            taskToDelete = task
                                            showDeleteAlert = true
                                        }) {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        .tint(.red)

                                        Button(action: {
                                            taskToEdit = task
                                            showingAddTaskSheet = true
                                        }) {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    Button(action: {
                        taskToEdit = nil
                        showingAddTaskSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "#3C5E95"))
                            .padding(.vertical)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .alert("Deleting Task", isPresented: $showDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {}
                Button("OK", role: .destructive) {
                    if let task = taskToDelete {
                        RemindInfo.deleteTask(id: task.id)
                    }
                    taskToDelete = nil
                }
            }, message: {
                Text("Are you sure you want to delete this task?")
            })
            .sheet(isPresented: $showingAddTaskSheet) {
                addRemind(RemindInfo: RemindInfo, taskToEdit: taskToEdit)
            }
            .background(Color(UIColor.systemGray6))
        }
    }

    private func deleteTask(at offsets: IndexSet) {
        offsets.forEach { index in
            let task = RemindInfo.tasks[index]
            RemindInfo.deleteTask(id: task.id)
        }
    }
}

// creating the tableView lists for reminders/tasks
struct RemindRowView: View {
    let task: remindModel
    @Binding var isDeleting: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onToggleComplete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? Color(UIColor(hex: "#FCD12A")) : .gray)
                    .font(.system(size: 22))
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.trailing, 5)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                Text(task.course)
                    .font(.subheadline)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(task.isCompleted ? .gray : .gray)
                
                Text("Due: \(task.dueDate, style: .date) at \(task.dueDate, style: .time)")
                    .font(.subheadline)
                    .foregroundColor(task.isCompleted ? .gray : (isOverdue() ? .red : .gray))
                
                if let location = task.location {
                    Text("Location: \(location)")
                        .font(.subheadline)
                        .foregroundColor(task.isCompleted ? .gray : .gray)
                }
            }
            
            Spacer()
            
            if task.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundColor(task.isCompleted ? .gray : .red)
            }
        }
    }
    
    private func isOverdue() -> Bool {
        return !task.isCompleted && task.dueDate < Date()
    }
    
    private func formattedDate() -> String {
        let calendar = Calendar.current
            
        if calendar.isDateInToday(task.dueDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(task.dueDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: task.dueDate)
        }
    }
}
