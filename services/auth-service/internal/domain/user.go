package domain

import (
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// User represents a user in the system
type User struct {
	ID          uuid.UUID  `json:"id" db:"id"`
	Email       string     `json:"email" db:"email"`
	Password    string     `json:"-" db:"password_hash"`
	FirstName   string     `json:"first_name" db:"first_name"`
	LastName    string     `json:"last_name" db:"last_name"`
	CampusID    *string    `json:"campus_id,omitempty" db:"campus_id"`
	Role        Role       `json:"role" db:"role"`
	IsActive    bool       `json:"is_active" db:"is_active"`
	IsVerified  bool       `json:"is_verified" db:"is_verified"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
	LastLoginAt *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
}

// Role represents user roles in the system
type Role string

const (
	RoleStudent Role = "student"
	RoleAdmin   Role = "admin"
	RoleModerator Role = "moderator"
)

// UserRegistration represents user registration data
type UserRegistration struct {
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required,min=8"`
	FirstName string `json:"first_name" validate:"required,min=2,max=50"`
	LastName  string `json:"last_name" validate:"required,min=2,max=50"`
	CampusID  string `json:"campus_id" validate:"required"`
}

// UserLogin represents login credentials
type UserLogin struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

// UserProfile represents user profile update data
type UserProfile struct {
	FirstName string  `json:"first_name,omitempty" validate:"omitempty,min=2,max=50"`
	LastName  string  `json:"last_name,omitempty" validate:"omitempty,min=2,max=50"`
	CampusID  *string `json:"campus_id,omitempty"`
}

// TokenPair represents JWT tokens
type TokenPair struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
}

// Session represents a user session
type Session struct {
	ID           uuid.UUID `json:"id" db:"id"`
	UserID       uuid.UUID `json:"user_id" db:"user_id"`
	RefreshToken string    `json:"-" db:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at" db:"expires_at"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	LastUsedAt   time.Time `json:"last_used_at" db:"last_used_at"`
	IPAddress    string    `json:"ip_address" db:"ip_address"`
	UserAgent    string    `json:"user_agent" db:"user_agent"`
	IsRevoked    bool      `json:"is_revoked" db:"is_revoked"`
}

// NewUser creates a new user with hashed password
func NewUser(reg UserRegistration) (*User, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(reg.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	return &User{
		ID:         uuid.New(),
		Email:      reg.Email,
		Password:   string(hashedPassword),
		FirstName:  reg.FirstName,
		LastName:   reg.LastName,
		CampusID:   &reg.CampusID,
		Role:       RoleStudent,
		IsActive:   true,
		IsVerified: false,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}, nil
}

// CheckPassword verifies the password against the hash
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	return err == nil
}

// UpdateLastLogin updates the last login timestamp
func (u *User) UpdateLastLogin() {
	now := time.Now()
	u.LastLoginAt = &now
	u.UpdatedAt = now
}

// UpdateProfile updates user profile information
func (u *User) UpdateProfile(profile UserProfile) {
	if profile.FirstName != "" {
		u.FirstName = profile.FirstName
	}
	if profile.LastName != "" {
		u.LastName = profile.LastName
	}
	if profile.CampusID != nil {
		u.CampusID = profile.CampusID
	}
	u.UpdatedAt = time.Now()
}

// Deactivate marks the user as inactive
func (u *User) Deactivate() {
	u.IsActive = false
	u.UpdatedAt = time.Now()
}

// Verify marks the user as verified
func (u *User) Verify() {
	u.IsVerified = true
	u.UpdatedAt = time.Now()
}

// NewSession creates a new session for the user
func NewSession(userID uuid.UUID, refreshToken, ipAddress, userAgent string, expiresAt time.Time) *Session {
	return &Session{
		ID:           uuid.New(),
		UserID:       userID,
		RefreshToken: refreshToken,
		ExpiresAt:    expiresAt,
		CreatedAt:    time.Now(),
		LastUsedAt:   time.Now(),
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
		IsRevoked:    false,
	}
}

// IsExpired checks if the session is expired
func (s *Session) IsExpired() bool {
	return time.Now().After(s.ExpiresAt)
}

// Revoke marks the session as revoked
func (s *Session) Revoke() {
	s.IsRevoked = true
}

// UpdateLastUsed updates the last used timestamp
func (s *Session) UpdateLastUsed() {
	s.LastUsedAt = time.Now()
}

// UserRepository defines the interface for user persistence
type UserRepository interface {
	Create(user *User) error
	GetByID(id uuid.UUID) (*User, error)
	GetByEmail(email string) (*User, error)
	Update(user *User) error
	Delete(id uuid.UUID) error
	List(limit, offset int) ([]*User, error)
}

// SessionRepository defines the interface for session persistence
type SessionRepository interface {
	Create(session *Session) error
	GetByRefreshToken(token string) (*Session, error)
	GetByUserID(userID uuid.UUID) ([]*Session, error)
	Update(session *Session) error
	Delete(id uuid.UUID) error
	RevokeAllByUserID(userID uuid.UUID) error
}
