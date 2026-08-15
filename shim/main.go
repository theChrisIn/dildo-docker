// Command dildo-docker-shim is a minimal companion HTTP server run
// alongside ViperServer inside this image. ViperServer's own HTTP API
// has no version or health endpoint, so this exists purely to give
// go-dildo's Register(url) something to query for the version-matrix
// check.
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

var (
	imageVersion   = "dev"     // set via -ldflags at build time from the image's own git tag
	viperserverRef = "unknown" // set via -ldflags at build time from VIPERSERVER_REF
)

type versionResponse struct {
	ImageVersion   string `json:"image_version"`
	ViperserverRef string `json:"viperserver_ref"`
}

func main() {
	port := os.Getenv("DILDO_SHIM_PORT")
	if port == "" {
		port = "9191"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/dildo/version", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(versionResponse{
			ImageVersion:   imageVersion,
			ViperserverRef: viperserverRef,
		}); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
	})

	log.Printf("dildo-docker-shim %s (viperserver %s) listening on :%s", imageVersion, viperserverRef, port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}
