package com.example.devopstaskmanager.service;

import com.example.devopstaskmanager.model.Task;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class TaskService {

    private final List<Task> tasks = new ArrayList<>();
    private final AtomicLong idCounter = new AtomicLong();

    public TaskService() {
        addTask("Create GitHub repository", "Push the Java Spring Boot app to GitHub", "High");
        addTask("Build Docker image", "Use Jenkins to build the application image", "Medium");
        addTask("Deploy to Kubernetes", "Deploy the app using Kubernetes manifests", "High");
    }

    public List<Task> getAllTasks() {
        return tasks;
    }

    public List<Task> getActiveTasks() {
        return tasks.stream()
                .filter(task -> !task.isCompleted())
                .toList();
    }

    public List<Task> getCompletedTasks() {
        return tasks.stream()
                .filter(Task::isCompleted)
                .toList();
    }

    public void addTask(String title, String description, String priority) {
        Long id = idCounter.incrementAndGet();
        Task task = new Task(id, title, description, priority);
        tasks.add(task);
    }

    public void toggleTaskStatus(Long id) {
        tasks.stream()
                .filter(task -> task.getId().equals(id))
                .findFirst()
                .ifPresent(task -> task.setCompleted(!task.isCompleted()));
    }

    public void deleteTask(Long id) {
        tasks.removeIf(task -> task.getId().equals(id));
    }

    public long countCompletedTasks() {
        return tasks.stream()
                .filter(Task::isCompleted)
                .count();
    }

    public long countActiveTasks() {
        return tasks.stream()
                .filter(task -> !task.isCompleted())
                .count();
    }
}