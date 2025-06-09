FROM openjdk:17
WORKDIR /app

# Copy source and compile it
COPY src/main/java/Main.java Main.java
RUN javac Main.java

# Set container port
EXPOSE 8090

# Run Main class
CMD ["java", "Main"]
