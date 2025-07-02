-- BookSwap Hub: PostgreSQL initial schema setup
-- This script sets up the schema for users, books, swap requests, and notifications.

-- USERS table: Each user has a unique username and email.
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    full_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_email_unique UNIQUE (email)
);

-- BOOKS table: Each book is owned by one user. Indexed by (owner_id).
CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(150),
    description TEXT,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_books_owner_id ON books(owner_id);

-- SWAP REQUESTS table: Track the lifecycle of swapping books between two users.
-- requester_id: user who initiates swap
-- responder_id: user who owns the book requested
-- book_id: the book being requested for swap
CREATE TABLE IF NOT EXISTS swap_requests (
    id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    requester_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    responder_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL DEFAULT 'pending', -- pending, accepted, declined, cancelled, completed
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_swap_requests_requester_id ON swap_requests(requester_id);
CREATE INDEX idx_swap_requests_responder_id ON swap_requests(responder_id);
CREATE INDEX idx_swap_requests_status ON swap_requests(status);

-- NOTIFICATIONS table: Notifications for users about swap requests, status changes, etc.
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    related_swap_id INTEGER REFERENCES swap_requests(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Automatically update 'updated_at' timestamps
CREATE OR REPLACE FUNCTION set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach triggers to update 'updated_at' on relevant tables
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_users'
    ) THEN
        CREATE TRIGGER set_timestamp_users
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE PROCEDURE set_timestamp();
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_books'
    ) THEN
        CREATE TRIGGER set_timestamp_books
        BEFORE UPDATE ON books
        FOR EACH ROW
        EXECUTE PROCEDURE set_timestamp();
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_timestamp_swap_requests'
    ) THEN
        CREATE TRIGGER set_timestamp_swap_requests
        BEFORE UPDATE ON swap_requests
        FOR EACH ROW
        EXECUTE PROCEDURE set_timestamp();
    END IF;
END $$;

-- Demo data block (uncomment below for sample/test entries)
-- INSERT INTO users (username, email, password_hash, full_name) VALUES
--   ('alice', 'alice@example.com', '<hash>', 'Alice Example'),
--   ('bob', 'bob@example.com', '<hash>', 'Bob Example');
