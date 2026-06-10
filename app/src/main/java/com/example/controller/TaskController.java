package com.example.devopstaskmanager.controller;

import com.example.devopstaskmanager.model.Task;
import com.example.devopstaskmanager.service.TaskService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Controller
public class TaskController {

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @GetMapping("/")
    public String showHomePage(@RequestParam(value = "filter", defaultValue = "all") String filter,
                               Model model) {

        List<Task> tasksToShow;

        if (filter.equals("active")) {
            tasksToShow = taskService.getActiveTasks();
        } else if (filter.equals("completed")) {
            tasksToShow = taskService.getCompletedTasks();
        } else {
            tasksToShow = taskService.getAllTasks();
        }

        model.addAttribute("tasks", tasksToShow);
        model.addAttribute("filter", filter);
        model.addAttribute("activeCount", taskService.countActiveTasks());
        model.addAttribute("completedCount", taskService.countCompletedTasks());
        model.addAttribute("totalCount", taskService.getAllTasks().size());

        return "index";
    }

    @PostMapping("/tasks")
    public String addTask(@RequestParam("title") String title,
                          @RequestParam("description") String description,
                          @RequestParam("priority") String priority) {

        taskService.addTask(title, description, priority);

        return "redirect:/";
    }

    @PostMapping("/tasks/{id}/toggle")
    public String toggleTask(@PathVariable("id") Long id) {
        taskService.toggleTaskStatus(id);
        return "redirect:/";
    }

    @PostMapping("/tasks/{id}/delete")
    public String deleteTask(@PathVariable("id") Long id) {
        taskService.deleteTask(id);
        return "redirect:/";
    }
}