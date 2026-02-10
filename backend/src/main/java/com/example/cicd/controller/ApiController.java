package com.example.cicd.controller;

import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.*;

@RestController
@CrossOrigin(origins = "*")
public class ApiController {

    private final Instant startTime = Instant.now();

    @GetMapping("/")
    public Map<String, Object> welcome() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Welcome to AWS CI/CD Pipeline Demo");
        response.put("version", "1.0.0");
        response.put("environment", "production");
        response.put("technology", "Java Spring Boot + Angular");
        return response;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("timestamp", Instant.now().toString());
        response.put("uptime", getUptime());
        response.put("memory", getMemoryInfo());
        return response;
    }

    @GetMapping("/api/info")
    public Map<String, Object> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", "AWS CI/CD Demo App");
        response.put("description", "Java Spring Boot backend with Angular frontend deployed via AWS CodePipeline");
        response.put("backend", "Spring Boot 3.2 with Undertow");
        response.put("frontend", "Angular 17");
        response.put("services", Arrays.asList("CodePipeline", "CodeBuild", "CodeDeploy"));
        response.put("platform", "AWS EC2 (t2.micro)");
        response.put("database", "None (stateless API)");
        return response;
    }

    private double getUptime() {
        return (Instant.now().toEpochMilli() - startTime.toEpochMilli()) / 1000.0;
    }

    private Map<String, String> getMemoryInfo() {
        Runtime runtime = Runtime.getRuntime();
        long maxMemory = runtime.maxMemory() / 1024 / 1024;
        long totalMemory = runtime.totalMemory() / 1024 / 1024;
        long freeMemory = runtime.freeMemory() / 1024 / 1024;
        long usedMemory = totalMemory - freeMemory;

        Map<String, String> memory = new HashMap<>();
        memory.put("max", maxMemory + " MB");
        memory.put("used", usedMemory + " MB");
        memory.put("free", freeMemory + " MB");
        return memory;
    }
}
