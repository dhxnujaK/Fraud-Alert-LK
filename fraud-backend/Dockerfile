# Use the official Ballerina runtime image
FROM ballerina/ballerina:2201.10.0

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Create uploads directory
RUN mkdir -p uploads

# Expose port
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV UPLOAD_PATH=./uploads

# Run the Ballerina application
CMD ["bal", "run"]
