import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

public class Main {
    public static void main(String[] args) throws IOException {
        int port = 8090;
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        // Register endpoints
        server.createContext("/", new MyHandler());
        server.createContext("/actuator", new ActuatorHandler());
        server.createContext("/actuator/prometheus", new PrometheusHandler());

        server.setExecutor(null); // Use default executor
        server.start();
        System.out.println("Java backend running on http://localhost:" + port);
    }

    // Root handler
    static class MyHandler implements HttpHandler {
        public void handle(HttpExchange exchange) throws IOException {
            String response = "GitOps Java backend is running!";
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }

    // Actuator health handler
    static class ActuatorHandler implements HttpHandler {
        public void handle(HttpExchange exchange) throws IOException {
            String response = "{\"status\":\"UP\",\"service\":\"GitOps Java backend\"}";
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }

    // Prometheus metrics handler
    static class PrometheusHandler implements HttpHandler {
        public void handle(HttpExchange exchange) throws IOException {
            String metrics =
                "# HELP app_status Application status\n" +
                "# TYPE app_status gauge\n" +
                "app_status 1\n" +
                "# HELP app_requests_total Total number of requests handled\n" +
                "# TYPE app_requests_total counter\n" +
                "app_requests_total 42\n";

            exchange.getResponseHeaders().set("Content-Type", "text/plain; version=0.0.4");
            exchange.sendResponseHeaders(200, metrics.length());
            OutputStream os = exchange.getResponseBody();
            os.write(metrics.getBytes());
            os.close();
        }
    }
}
