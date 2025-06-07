FROM openjdk:17
WORKDIR /app

# Copy Main.java from Maven-style path
COPY src/main/java/Main.java .

# Compile without package
RUN javac Main.java

# Expose the port your app uses
EXPOSE 8090

# Run Main class from root of classpath
CMD ["java", "Main"]
