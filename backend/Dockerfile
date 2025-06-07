FROM openjdk:17
WORKDIR /app

# Copy source
COPY . .

# Compile Main.java
RUN javac src/Main.java

# Expose port 8090 for container access
EXPOSE 8090

# Run the Java app
CMD ["java", "src.Main"]
