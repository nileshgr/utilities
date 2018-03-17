package ispinfo

import (
	"fmt"
	"net/http"
	"net/url"
	"time"

	"google.golang.org/appengine"
	"google.golang.org/appengine/socket"
	"google.golang.org/appengine/urlfetch"
)

type ISPInfo struct {
	Name       string
	IPAddress  string
	PortNumber uint16
	State      bool
	LastCheck  time.Time
}

func (i *ISPInfo) Check(r *http.Request) {
	ctx := appengine.NewContext(r)

	host := fmt.Sprintf("%s:%d", i.IPAddress, i.PortNumber)
	timeout, _ := time.ParseDuration("5s")
	conn, err := socket.DialTimeout(ctx, "tcp", host, timeout)
	i.LastCheck = time.Now()

	if err == nil {
		i.State = true
	} else {
		i.State = false
	}

	conn.Close()
}

func (i *ISPInfo) SendAlert(r *http.Request, w http.ResponseWriter) {
	ctx := appengine.NewContext(r)
	client := urlfetch.Client(ctx)

	message := fmt.Sprintf("%s is %s", i.Name, i.Status())
	params := url.Values{}
	url := "<<<telegram api url>>>"

	params.Add("chat_id", "<<<chat id>>>")
	params.Add("text", message)

	response, err := client.PostForm(url, params)

	if err != nil {
		fmt.Fprintln(w, "Error sending message ", err.Error())
		return
	}

	response.Body.Close()
}

func (i *ISPInfo) Status() string {
	if i.State {
		return "UP"
	}

	return "DOWN"
}
