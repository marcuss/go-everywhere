package main

import (
	"fmt"
	"net/http"
	"strings"
)

// Handler function for the /play/{word} path
func play(w http.ResponseWriter, req *http.Request) {
	// Extract the word from the URL path
	word := strings.TrimPrefix(req.URL.Path, "/play/")

	// Case-insensitive comparison
	if strings.EqualFold(word, "marco") {
		fmt.Fprintf(w, "Nico\n")
	} else {
		// Return error code 400 and the same word as body
		http.Error(w, word, http.StatusBadRequest)
	}
}
