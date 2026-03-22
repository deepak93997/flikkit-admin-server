package com.flikkit.adminserver;

import de.codecentric.boot.admin.server.config.EnableAdminServer;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@EnableAdminServer
@SpringBootApplication
public class FlikkitAdminServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(FlikkitAdminServerApplication.class, args);
    }
}
