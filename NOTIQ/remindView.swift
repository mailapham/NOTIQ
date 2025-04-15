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
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    if RemindInfo.tasks.isEmpty && RemindInfo.completedTasks.isEmpty {
                        // default view for no tasks
                        VStack(spacing: 20) {
                            Spacer()
                                .frame(height: 200)
                            
                            Image(systemName: "checklist")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Tasks")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Text("Add tasks to keep track of your to-dos")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                    } else {
                        List {
                            // uncompleted tasks section
                            if !RemindInfo.tasks.isEmpty {
                                Text("Tasks")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.top, 9)
                                    .listRowSeparator(.hidden)
                                
                                ForEach(sortedTasks) { task in
                                    taskCard(task: task)
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                        .padding(.vertical, 4)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                taskToDelete = task
                                                showDeleteAlert = true
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                            
                                            Button {
                                                taskToEdit = task
                                                showingAddTaskSheet = true
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                        .listRowBackground(Color.clear)
                                }
                            }
                            
                            // completed tasks section
                            if !RemindInfo.completedTasks.isEmpty {
                                Text("Completed Tasks")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.top)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ForEach(sortedCompletedTasks) { task in
                                    completedTaskCard(task: task)
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                        .padding(.vertical, 4)
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                taskToDelete = task
                                                showDeleteAlert = true
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                        }
                                        .listRowBackground(Color.clear)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                // add task button
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
        }
    }
    
    // uncompleted task card view
    private func taskCard(task: remindModel) -> some View {
        HStack {
            Button(action: {
                RemindInfo.markTaskAsDone(task: task)
            }) {
                Image(systemName: task.isCompleted ? "circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? Color(UIColor(hex: "#FCD12A")) : .gray)
                    .font(.system(size: 22))
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.trailing, 5)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if task.isFlagged {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                }
                
                Text(task.course)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !task.descriptionText.isEmpty {
                    Text(task.descriptionText)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatTime(task.dueDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if isOverdue(task) {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                if let location = task.location, !location.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            
                            if let address = task.address, !address.isEmpty {
                                Text(address)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .frame(height: 125)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }

    // completed task card view
    private func completedTaskCard(task: remindModel) -> some View {
        HStack {
            Button(action: {
                RemindInfo.markTaskAsUndone(task: task)
            }) {
                Image(systemName: "circle.fill")
                    .foregroundColor(Color(UIColor(hex: "#FCD12A")))
                    .font(.system(size: 22))
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.trailing, 5)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    if task.isFlagged {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                    }
                }
                
                Text(task.course)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                if !task.descriptionText.isEmpty {
                    Text(task.descriptionText)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatTime(task.dueDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let location = task.location, !location.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                            
                            if let address = task.address, !address.isEmpty {
                                Text(address)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .frame(height: 125)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // uncompleted: flagged -> earliest date
    private var sortedTasks: [remindModel] {
        RemindInfo.tasks.sorted {
            if $0.isFlagged != $1.isFlagged {
                return $0.isFlagged
            }
            return $0.dueDate < $1.dueDate
        }
    }

    // completed: flagged -> earliest date
    private var sortedCompletedTasks: [remindModel] {
         RemindInfo.completedTasks.sorted {
            if $0.isFlagged != $1.isFlagged {
                return $0.isFlagged
            }
            return $0.dueDate < $1.dueDate
        }
    }
    
    // check if task is overdue
    private func isOverdue(_ task: remindModel) -> Bool {
        return !task.isCompleted && task.dueDate < Date()
    }
    
    // formatting time
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()

        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "h:mm a"
            return "Today at \(dateFormatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            dateFormatter.dateFormat = "h:mm a"
            return "Tomorrow at \(dateFormatter.string(from: date))"
        } else {
            dateFormatter.dateFormat = "EEE, MMM d 'at' h:mm a"
            return dateFormatter.string(from: date)
        }
    }
}
