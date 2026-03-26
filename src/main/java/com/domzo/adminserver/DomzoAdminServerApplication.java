package com.domzo.adminserver;

import de.codecentric.boot.admin.server.config.EnableAdminServer;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@EnableAdminServer
@SpringBootApplication
public class DomzoAdminServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(DomzoAdminServerApplication.class, args);
    }
}
