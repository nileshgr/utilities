package main

import (
	"fmt"
	"ispinfo"
	"net/http"
	"time"

	"google.golang.org/appengine"
)

var isps = [2]ispinfo.ISPInfo{
	ispinfo.ISPInfo{
		Name:       "ISP1",
		IPAddress:  "x.x.x.x",
		PortNumber: 80,
	},
	ispinfo.ISPInfo{
		Name:       "ISP2",
		IPAddress:  "y.y.y.y",
		PortNumber: 443,
	},
}

func main() {
	http.HandleFunc("/", handle)
	http.HandleFunc("/checkisps", checkisps)

	for index := range isps {
		isps[index].State = false
		isps[index].LastCheck = time.Now()
	}

	appengine.Main()
}

func handle(w http.ResponseWriter, r *http.Request) {
	location := time.FixedZone("IST", 19800)
	w.Header().Add("Content-Type", "text/plain")

	for _, isp := range isps {
		fmt.Fprintln(w, "ISP", isp.Name, "is", isp.Status(), ". Last Checked at", isp.LastCheck.In(location).Format(time.RFC822))
	}
}

func checkisps(w http.ResponseWriter, r *http.Request) {
	for idx := range isps {
		oldstate := isps[idx].State
		isps[idx].Check(r)

		if oldstate != isps[idx].State {
			defer isps[idx].SendAlert(r, w)
		}
	}
}
