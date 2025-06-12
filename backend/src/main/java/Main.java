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

        // Register root context
        server.createContext("/", new MyHandler());

        // Register /actuator context
        server.createContext("/actuator", new ActuatorHandler());

        server.setExecutor(null); // Use default executor
        server.start();
        System.out.println("Java backend running on http://localhost:" + port);
    }

    // Handler for "/"
    static class MyHandler implements HttpHandler {
        public void handle(HttpExchange exchange) throws IOException {
            String response = "GitOps Java backend is running!";
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }

    // Handler for "/actuator"
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
}
