package com.cyat.backend;
 
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
 
@SpringBootApplication
@RestController
public class Main {
 
    public static void main(String[] args) {
        SpringApplication.run(Main.class, args);
    }
 
    @GetMapping("/")
    public String home() {
        return "Backend service for GitOps project running...";
    }
 
    @GetMapping("/api/hello")
    public String hello() {
        return "Hello from /api/hello!";
    }
 
}