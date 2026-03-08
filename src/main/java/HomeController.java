package com.v1w.app;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
public class HomeController {

    @GetMapping("/")
    public Map<String, String> home() {
        return Map.of(
            "app",     "V1W Application",
            "status",  "Running",
            "version", "1.0.0"
        );
    }

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of("message", "Hello from V1W App!");
    }
}

