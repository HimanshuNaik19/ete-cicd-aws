package com.example.cicd.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@WebMvcTest(ApiController.class)
class ApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testWelcomeEndpoint() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Welcome to AWS CI/CD Pipeline Demo"))
                .andExpect(jsonPath("$.version").value("1.0.0"))
                .andExpect(jsonPath("$.technology").value("Java Spring Boot + Angular"));
    }

    @Test
    void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("healthy"))
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.uptime").exists())
                .andExpect(jsonPath("$.memory").exists());
    }

    @Test
    void testInfoEndpoint() throws Exception {
        mockMvc.perform(get("/api/info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.application").value("AWS CI/CD Demo App"))
                .andExpect(jsonPath("$.backend").value("Spring Boot 3.2 with Undertow"))
                .andExpect(jsonPath("$.frontend").value("Angular 17"))
                .andExpect(jsonPath("$.platform").value("AWS EC2 (t2.micro)"))
                .andExpect(jsonPath("$.services").isArray())
                .andExpect(jsonPath("$.services", hasSize(3)));
    }

    @Test
    void testHealthMemoryInfo() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.memory.max").exists())
                .andExpect(jsonPath("$.memory.used").exists())
                .andExpect(jsonPath("$.memory.free").exists());
    }
}
