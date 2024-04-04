package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/silinternational/idp-id-broker-search/shared"
)

const (
	idp   = "OurIDP"
	user1 = 1
	user2 = 2
)

func Test_loadConfig(t *testing.T) {
	tests := []struct {
		name    string
		env     map[string]string
		want    BrokerConfig
		wantErr bool
	}{
		{
			name:    "no env vars set",
			env:     map[string]string{},
			want:    BrokerConfig{},
			wantErr: true,
		},
		{
			name: "missing token",
			env: map[string]string{
				"BROKER_BASE_URL": "https://example.com",
			},
			want:    BrokerConfig{},
			wantErr: true,
		},
		{
			name: "missing base url",
			env: map[string]string{
				"BROKER_TOKEN": "abc123",
			},
			want:    BrokerConfig{},
			wantErr: true,
		},
		{
			name: "valid config",
			env: map[string]string{
				"BROKER_BASE_URL": "https://example.com",
				"BROKER_TOKEN":    "abc123",
				"IDP_NAME":        idp,
			},
			want: BrokerConfig{
				BaseURL: "https://example.com",
				Token:   "abc123",
				IDP:     idp,
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_ = os.Setenv("BROKER_BASE_URL", "")
			_ = os.Setenv("BROKER_TOKEN", "")
			for name, val := range tt.env {
				_ = os.Setenv(name, val)
			}
			got, err := loadConfig()
			if (err != nil) != tt.wantErr {
				t.Errorf("loadConfig() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("loadConfig() = %v, want %v", got, tt.want)
			}
		})
	}
}

func Test_search(t *testing.T) {
	type args struct {
		status       int
		query        string
		jsonResponse string
	}
	tests := []struct {
		name         string
		query        string
		jsonResponse string
		args         args
		want         []shared.User
		wantErr      bool
	}{
		{
			name: "no results",
			args: args{
				status:       http.StatusNoContent,
				query:        "nobody",
				jsonResponse: `[]`,
			},
			want:    []shared.User{},
			wantErr: false,
		},
		{
			name: "one result",
			args: args{
				status:       http.StatusOK,
				query:        "single",
				jsonResponse: fmt.Sprintf("[%s]", fakeResponse(user1)),
			},
			want:    []shared.User{fakeUser(user1)},
			wantErr: false,
		},
		{
			name: "two results",
			args: args{
				status:       http.StatusOK,
				query:        "double",
				jsonResponse: fmt.Sprintf("[%s,%s]", fakeResponse(user1), fakeResponse(user2)),
			},
			want: []shared.User{
				fakeUser(user1),
				fakeUser(user2),
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mux := http.NewServeMux()
			server := httptest.NewServer(mux)
			mux.HandleFunc("/user", func(w http.ResponseWriter, req *http.Request) {
				w.WriteHeader(tt.args.status)
				w.Header().Set("content-type", "application/json")
				fmt.Fprintf(w, tt.args.jsonResponse)
			})

			config := BrokerConfig{
				BaseURL: server.URL,
				Token:   "ignored",
				IDP:     idp,
			}

			got, err := search(config, "")
			if tt.wantErr {
				require.Error(t, err)
				return
			}
			require.NoError(t, err)

			require.Equal(t, len(tt.want), len(got))

			if len(tt.want) == 0 {
				return
			}

			// spot check a few fields because DeepEqual is touchy with this
			require.Equal(t, tt.want[0].IDP, got[0].IDP)
			require.Equal(t, tt.want[0].EmployeeID, got[0].EmployeeID)
			require.Equal(t, tt.want[0].DisplayName, got[0].DisplayName)
			require.Equal(t, tt.want[0].Mfa.Options[0].Label, got[0].Mfa.Options[0].Label)
			require.Equal(t, tt.want[0].Method.Options[0].Value, got[0].Method.Options[0].Value)
		})
	}
}

func fakeResponse(userID int) string {
	switch userID {
	case 1:
		return `{
		"uuid": "1f93d396-8140-49c0-843e-47dae5291123",
		"employee_id": "123456",
		"first_name": "Lisa",
		"last_name": "VanNote",
		"display_name": "Lisa VanNote",
		"username": "lisa_vannote",
		"email": "lisa_vannote@example.org",
		"active": "yes",
		"locked": "no",
		"last_login_utc": null,
		"created_utc": "2024-04-01T18:27:02Z",
		"deactivated_utc": null,
		"manager_email": null,
		"personal_email": "",
		"hide": "no",
		"member": [
			"dev"
		],
		"mfa": {
			"prompt": "no",
			"add": "no",
			"active": "yes",
			"options": [
				{
					"id": 1,
					"type": "webauthn",
					"label": "Yubikey",
					"created_utc": "2024-04-03T18:27:44Z",
					"last_used_utc": "2024-04-04T12:27:45Z",
					"data": [
						{
							"id": 1,
							"label": "1",
							"last_used_utc": "2024-04-04 18:28:24",
							"created_utc": "2024-04-04 12:28:24"
						}
					]
				},
				{
					"id": 2,
					"type": "totp",
					"label": "Authy",
					"created_utc": "2024-04-04T18:32:27Z",
					"last_used_utc": null,
					"data": []
				},
				{
					"id": 3,
					"type": "backupcode",
					"label": null,
					"created_utc": "2024-04-04T18:32:47Z",
					"last_used_utc": null,
					"data": {
						"count": 10
					}
				}
			]
		},
		"method": {
			"add": "no",
			"options": [
				{
					"id": "_BC9GEpZeIqbXoBiLdhrRAwkNUlz7scg",
					"value": "l***_v*****e@e******.c**",
					"verified": false,
					"created": "2024-04-04T19:30:34Z"
				}
			]
		},
        "profile_review": "no",
		"require_mfa": "no"
	}`
	case 2:
		return `{"employee_id": "098765"}`
	}
	return "{}"
}

func fakeUser(userID int) shared.User {
	switch userID {
	case 1:
		return shared.User{
			IDP:            "OurIDP",
			EmployeeID:     "123456",
			FirstName:      "Lisa",
			LastName:       "VanNote",
			DisplayName:    "Lisa VanNote",
			Username:       "lisa_vannote",
			Email:          "lisa_vannote@example.org",
			Active:         "yes",
			Locked:         "no",
			LastLoginUtc:   "",
			CreatedUtc:     "2024-04-01T18:27:02Z",
			DeactivatedUtc: "",
			ManagerEmail:   "",
			PersonalEmail:  "",
			Hide:           "no",
			RequireMFA:     "no",
			Member:         []string{"dev"},
			Mfa: shared.Mfa{
				Prompt: "no",
				Add:    "no",
				Options: []shared.MfaOption{
					{
						ID:          1,
						Type:        "webauthn",
						Label:       "Yubikey",
						CreatedUtc:  "2024-04-03T18:27:44Z",
						LastUsedUtc: "2024-04-04T12:27:45Z",
						Data: []shared.WebauthnData{
							{
								ID:          1,
								Label:       "1",
								CreatedUtc:  "2024-04-04 12:28:24",
								LastUsedUtc: "2024-04-04 18:28:24",
							},
						},
					},
					{
						ID:          2,
						Type:        "totp",
						Label:       "Authy",
						CreatedUtc:  "2024-04-04T18:32:27Z",
						LastUsedUtc: "",
						Data:        []string{},
					},
					{
						ID:          3,
						Type:        "backupcode",
						Label:       "",
						CreatedUtc:  "2024-04-04T18:32:47Z",
						LastUsedUtc: "",
						Data: shared.BackupCodeData{
							Count: 10,
						},
					},
				},
			},
			Password: shared.Password{
				CreatedUtc: "",
				ExpiresOn:  "",
			},
			Method: shared.Method{
				Add: "no",
				Options: []shared.MethodOption{
					{
						ID:    "_BC9GEpZeIqbXoBiLdhrRAwkNUlz7scg",
						Value: "l***_v*****e@e******.c**", Verified: false, Created: "2024-04-04T19:30:34Z",
					},
				},
			},
		}

	case 2:
		return shared.User{
			EmployeeID: "098765",
			IDP:        idp,
		}
	}
	return shared.User{}
}
