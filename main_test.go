package main

import (
	"fmt"
	"github.com/silinternational/idp-id-broker-search/shared"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"testing"
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
			},
			want: BrokerConfig{
				BaseURL: "https://example.com",
				Token:   "abc123",
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
				jsonResponse: ``,
			},
			want:    []shared.User{},
			wantErr: false,
		},
		{
			name: "one result",
			args: args{
				status:       http.StatusOK,
				query:        "single",
				jsonResponse: `[{"employee_id": "123456"}]`,
			},
			want: []shared.User{
				{
					EmployeeID: "123456",
				},
			},
			wantErr: false,
		},
		{
			name: "two result",
			args: args{
				status:       http.StatusOK,
				query:        "double",
				jsonResponse: `[{"employee_id": "123456"},{"employee_id": "098765"}]`,
			},
			want: []shared.User{
				{
					EmployeeID: "123456",
				},
				{
					EmployeeID: "098765",
				},
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
			}

			got, err := search(config, tt.args.query)
			if (err != nil) != tt.wantErr {
				t.Errorf("search() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("search() = %v, want %v", got, tt.want)
			}
		})
	}
}
