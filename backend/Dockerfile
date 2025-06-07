FROM openjdk:17
WORKDIR /app

# Copy only the necessary file
COPY src/main/java/Main.java .

# Compile Main.java
RUN javac Main.java

# Expose the port the app listens on
EXPOSE 8090

# Run the app
CMD ["java", "Main"]
