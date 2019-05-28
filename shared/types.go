package shared

// Query is expected payload to lambda function
type Query struct {
	Search string
}

// See UserResponse object defined in https://github.com/silinternational/idp-id-broker/blob/develop/api.raml
type User struct {
	IDP           string   `json:"idp"`
	EmployeeID    string   `json:"employee_id"`
	FirstName     string   `json:"first_name"`
	LastName      string   `json:"last_name"`
	DisplayName   string   `json:"display_name"`
	Username      string   `json:"username"`
	Email         string   `json:"email"`
	Active        string   `json:"active"`
	Locked        string   `json:"locked"`
	LastLoginUtc  string   `json:"last_login_utc"`
	ManagerEmail  string   `json:"manager_email"`
	PersonalEmail string   `json:"personal_email"`
	Hide          string   `json:"hide"`
	Groups        []string `json:"groups"`
	Mfa           struct {
		Prompt  string `json:"prompt"`
		Add     string `json:"add"`
		Options []struct {
			ID          int    `json:"id"`
			Type        string `json:"type"`
			Label       string `json:"label"`
			CreatedUtc  string `json:"created_utc"`
			LastUsedUtc string `json:"last_used_utc"`
			// Data        struct {
			// 	Count int `json:"count"`
			// } `json:"data"`
		} `json:"options"`
	} `json:"mfa"`
	Password struct {
		CreatedUtc string `json:"created_utc"`
		ExpiresOn  string `json:"expires_on"`
	} `json:"password"`
	Method struct {
		Add     string `json:"add"`
		Options []struct {
			ID       string `json:"id"`
			Value    string `json:"value"`
			Verified bool   `json:"verified"`
			Created  string `json:"created"`
		} `json:"options"`
	} `json:"method"`
}
