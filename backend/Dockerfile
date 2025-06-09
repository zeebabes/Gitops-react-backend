FROM openjdk:17
WORKDIR /app

# Copy Main.java to /app
COPY src/main/java/Main.java .

# Compile Main.java to Main.class
RUN javac Main.java

# Expose the backend port
EXPOSE 8090

# Run the compiled Main class
CMD ["java", "Main"]
