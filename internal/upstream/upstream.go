/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package upstream

import (
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/badgateway"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upload"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/urlprefix"
)

var (
	DefaultBackend         = helper.URLMustParse("http://localhost:8080")
	requestHeaderBlacklist = []string{
		upload.RewrittenFieldsHeader,
	}
)

type Config struct {
	Backend             *url.URL
	Version             string
	DocumentRoot        string
	DevelopmentMode     bool
	Socket              string
	ProxyHeadersTimeout time.Duration
	APILimit            uint
	APIQueueLimit       uint
	APIQueueTimeout     time.Duration
}

type Upstream struct {
	Config
	URLPrefix    urlprefix.Prefix
	Routes       []routeEntry
	RoundTripper *badgateway.RoundTripper
}

func NewUpstream(config Config) *Upstream {
	up := Upstream{
		Config: config,
	}
	if up.Backend == nil {
		up.Backend = DefaultBackend
	}
	up.RoundTripper = badgateway.NewRoundTripper(up.Backend, up.Socket, up.ProxyHeadersTimeout, config.DevelopmentMode)
	up.configureURLPrefix()
	up.configureRoutes()
	return &up
}

func (u *Upstream) configureURLPrefix() {
	relativeURLRoot := u.Backend.Path
	if !strings.HasSuffix(relativeURLRoot, "/") {
		relativeURLRoot += "/"
	}
	u.URLPrefix = urlprefix.Prefix(relativeURLRoot)
}

func (u *Upstream) ServeHTTP(ow http.ResponseWriter, r *http.Request) {
	w := helper.NewLoggingResponseWriter(ow)
	defer w.Log(r)

	helper.DisableResponseBuffering(w)

	// Drop RequestURI == "*" (FIXME: why?)
	if r.RequestURI == "*" {
		helper.HTTPError(w, r, "Connection upgrade not allowed", http.StatusBadRequest)
		return
	}

	// Disallow connect
	if r.Method == "CONNECT" {
		helper.HTTPError(w, r, "CONNECT not allowed", http.StatusBadRequest)
		return
	}

	// Check URL Root
	URIPath := urlprefix.CleanURIPath(r.URL.Path)
	prefix := u.URLPrefix
	if !prefix.Match(URIPath) {
		helper.HTTPError(w, r, fmt.Sprintf("Not found %q", URIPath), http.StatusNotFound)
		return
	}

	// Look for a matching route
	var route *routeEntry
	for _, ro := range u.Routes {
		if ro.isMatch(prefix.Strip(URIPath), r) {
			route = &ro
			break
		}
	}

	if route == nil {
		// The protocol spec in git/Documentation/technical/http-protocol.txt
		// says we must return 403 if no matching service is found.
		helper.HTTPError(w, r, "Forbidden", http.StatusForbidden)
		return
	}

	for _, h := range requestHeaderBlacklist {
		r.Header.Del(h)
	}

	route.handler.ServeHTTP(w, r)
}
