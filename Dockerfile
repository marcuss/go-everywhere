# Use an official Go runtime as a parent image
FROM golang:1.23-alpine AS builder

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy the Go modules files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code from the 'scr' directory
COPY scr/ .

# Build the Go app
RUN go build -o main .

# Use a smaller base image to reduce the size of the final image
FROM alpine:3.15

# Install CA certificates
RUN apk add --no-cache ca-certificates

# Set the Current Working Directory inside the container
WORKDIR /root/

# Copy the pre-built binary file from the previous stage
COPY --from=builder /app/main .

# Copy the entirety of the certs folder to ensure all needed certificates are available
COPY certs/ certs/

# Expose ports 80 and 443
EXPOSE 80
EXPOSE 443

# Command to run the executable
CMD ["./main"]