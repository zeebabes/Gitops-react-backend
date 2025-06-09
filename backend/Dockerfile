FROM openjdk:17
WORKDIR /app

# Copy and compile
COPY src/main/java/Main.java .
RUN javac Main.java

# Expose backend port
EXPOSE 8090

# Run main class
CMD ["java", "Main"]
