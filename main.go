package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"

	"github.com/aws/aws-lambda-go/lambda"

	"github.com/silinternational/idp-id-broker-search/v2/shared"
)

type BrokerConfig struct {
	BaseURL string
	Token   string
	IDP     string
}

func main() {
	lambda.Start(handler)
}

func handler(query shared.Query) ([]shared.User, error) {
	config, err := loadConfig()
	if err != nil {
		return []shared.User{}, err
	}

	return search(config, query.Search)
}

func loadConfig() (BrokerConfig, error) {
	baseUrl := os.Getenv("BROKER_BASE_URL")
	if baseUrl == "" {
		return BrokerConfig{}, fmt.Errorf("required env var BROKER_BASE_URL is missing")
	}

	token := os.Getenv("BROKER_TOKEN")
	if token == "" {
		return BrokerConfig{}, fmt.Errorf("required env var BROKER_TOKEN is missing")
	}

	idpName := os.Getenv("IDP_NAME")
	if idpName == "" {
		return BrokerConfig{}, fmt.Errorf("required env var IDP_NAME is missing")
	}

	return BrokerConfig{
		BaseURL: baseUrl,
		Token:   token,
		IDP:     idpName,
	}, nil
}

func search(config BrokerConfig, query string) ([]shared.User, error) {
	client := &http.Client{}
	searchURL := fmt.Sprintf("%s/user?search=%s&mask=yes", config.BaseURL, url.QueryEscape(query))
	req, err := http.NewRequest(http.MethodGet, searchURL, nil)
	if err != nil {
		log.Println(err)
		return []shared.User{}, err
	}

	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", config.Token))

	resp, err := client.Do(req)
	if err != nil {
		log.Println(err)
		return []shared.User{}, err
	}

	if resp.StatusCode == http.StatusNoContent {
		return []shared.User{}, nil
	}

	var results []shared.User

	bodyText, err := io.ReadAll(resp.Body)
	if err != nil {
		return []shared.User{}, err
	}

	err = json.Unmarshal(bodyText, &results)
	if err != nil {
		log.Println("JSON parse error:", err)
		log.Println("API response body:", string(bodyText))
		log.Println("Calling API:", searchURL)
		return []shared.User{}, err
	}

	for i := range results {
		patchMfaCounts(results[i].Mfa.Options)
		results[i].IDP = config.IDP
	}

	return results, nil
}

// patchMfaCounts sets the "count" attribute on the MFA options struct. This is in lieu of the id-broker not providing
// this, but instead making "data" take on multiple data types, depending on the MFA type.
func patchMfaCounts(mfaOptions []shared.MfaOption) {
	for i, o := range mfaOptions {
		switch o.Type {
		case shared.MfaTypeBackupCode:
			data, _ := o.Data.(map[string]any)
			if o.Count == 0 && data["count"] != 0 {
				count, _ := data["count"].(float64)
				mfaOptions[i].Count = int(count)
			}

		case shared.MfaTypeTotp:
			// no data is included for TOTP

		case shared.MfaTypeWebauthn:
			data, _ := o.Data.([]any)
			if o.Count == 0 && len(data) != 0 {
				mfaOptions[i].Count = len(data)
			}
		}
	}
}
