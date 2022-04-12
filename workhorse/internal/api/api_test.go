package api

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

func TestGetGeoProxyDataForResponses(t *testing.T) {
	testCases := []struct {
		desc              string
		json              string
		expectedError     bool
		expectedURL       string
		expectedExtraData string
	}{
		{"when Geo secondary", `{"geo_proxy_url":"http://primary","geo_proxy_extra_data":"geo-data"}`, false, "http://primary", "geo-data"},
		{"when Geo secondary with explicit null data", `{"geo_proxy_url":"http://primary","geo_proxy_extra_data":null}`, false, "http://primary", ""},
		{"when Geo secondary without extra data", `{"geo_proxy_url":"http://primary"}`, false, "http://primary", ""},
		{"when Geo primary or no node", `{}`, false, "", ""},
		{"for malformed request", `non-json`, true, "", ""},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			geoProxyData, err := getGeoProxyDataGivenResponse(t, tc.json)

			if tc.expectedError {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				require.Equal(t, tc.expectedURL, geoProxyData.GeoProxyURL.String())
				require.Equal(t, tc.expectedExtraData, geoProxyData.GeoProxyExtraData)
			}
		})
	}
}

func getGeoProxyDataGivenResponse(t *testing.T, givenInternalApiResponse string) (*GeoProxyData, error) {
	t.Helper()
	ts := testRailsServer(regexp.MustCompile(`/api/v4/geo/proxy`), 200, givenInternalApiResponse)
	defer ts.Close()
	backend := helper.URLMustParse(ts.URL)
	version := "123"
	rt := roundtripper.NewTestBackendRoundTripper(backend)
	testhelper.ConfigureSecret()

	apiClient := NewAPI(backend, version, rt)

	geoProxyData, err := apiClient.GetGeoProxyData()

	return geoProxyData, err
}

func testRailsServer(url *regexp.Regexp, code int, body string) *httptest.Server {
	return testhelper.TestServerWithHandlerWithGeoPolling(url, func(w http.ResponseWriter, r *http.Request) {
		// return a 204 No Content response if we don't receive the JWT header
		if r.Header.Get(secret.RequestHeader) == "" {
			w.WriteHeader(204)
			return
		}

		w.Header().Set("Content-Type", ResponseContentType)

		logEntry := log.WithFields(log.Fields{
			"method": r.Method,
			"url":    r.URL,
		})
		logEntryWithCode := logEntry.WithField("code", code)

		// Write pure string
		logEntryWithCode.Info("UPSTREAM")

		w.WriteHeader(code)
		fmt.Fprint(w, body)
	})
}
