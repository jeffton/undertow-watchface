# Use the official Golang image to create a build artifact.
# This is known as a builder image.
FROM golang:1.24.3-alpine as builder

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source code
COPY . .

# Build the Go app
# -o proxy will output a binary named "proxy"
# -ldflags="-w -s" reduces the size of the binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o proxy .

# Start a new, fresh stage from the scratch image, which is a minimalist image
FROM alpine:latest

RUN apk --no-cache add ca-certificates

# Set the Current Working Directory inside the container
WORKDIR /root/

# Copy the Pre-built binary file from the previous stage
COPY --from=builder /app/proxy .

# Command to run the executable
CMD ["./proxy"] 