package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	// Register the play handler for the /play/ path
	http.HandleFunc("/play/", play)

	// Create HTTP server
	httpServer := &http.Server{
		Addr: ":80",
	}

	// Create HTTPS server with HTTP/2 support and ReadTimeout for added security
	httpsServer := &http.Server{
		Addr: ":443",
		TLSConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
		},
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	// Channel to listen for shutdown signals
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	// Start the HTTP server
	go func() {
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			fmt.Printf("Failed to start HTTP server: %v\n", err)
		}
	}()

	// Start the HTTPS server
	go func() {
		if err := httpsServer.ListenAndServeTLS("certs/cert.pem", "certs/key.pem"); err != nil && err != http.ErrServerClosed {
			fmt.Printf("Failed to start HTTPS server: %v\n", err)
		}
	}()

	// Wait for shutdown signal
	<-stop

	// Gracefully shut down servers
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := httpServer.Shutdown(ctx); err != nil {
		fmt.Printf("HTTP server shutdown failed: %v\n", err)
	} else {
		fmt.Println("HTTP server stopped")
	}

	if err := httpsServer.Shutdown(ctx); err != nil {
		fmt.Printf("HTTPS server shutdown failed: %v\n", err)
	} else {
		fmt.Println("HTTPS server stopped")
	}
}
