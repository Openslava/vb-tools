package com.example;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class HelloServlet extends HttpServlet {
    private String version = "unknown";
    
    @Override
    public void init() throws ServletException {
        super.init();
        try (InputStream input = getClass().getClassLoader().getResourceAsStream("application.properties")) {
            if (input != null) {
                Properties props = new Properties();
                props.load(input);
                version = props.getProperty("version", "unknown");
            }
        } catch (IOException e) {
            getServletContext().log("Could not load version from properties", e);
        }
    }
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("text/html");
        resp.getWriter().println("<h1>Hello, WebLogic!</h1>");
        resp.getWriter().println("<p><strong>Application Version:</strong> " + version + "</p>");
        resp.getWriter().println("<p><strong>Build Date:</strong> " + java.time.LocalDateTime.now() + "</p>");
        resp.getWriter().println("<p><strong>Java Version:</strong> " + System.getProperty("java.version") + "</p>");
        resp.getWriter().println("<p><strong>Server Info:</strong> " + getServletContext().getServerInfo() + "</p>");
    }
}
