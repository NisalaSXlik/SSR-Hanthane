-- DB/01_initial_schema.sql
-- Complete PostgreSQL schema matching your MySQL structure

-- Users table (enhanced with phone number)
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    bio TEXT,
    profile_picture VARCHAR(255),
    cover_photo VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    university VARCHAR(255),
    last_login TIMESTAMP,
    friends_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    date_of_birth DATE,
    location VARCHAR(255)
);

-- User Settings
CREATE TABLE UserSettings (
    user_id INTEGER PRIMARY KEY,
    push_notifications BOOLEAN DEFAULT TRUE,
    privacy_level VARCHAR(20) DEFAULT 'friends_only', -- public, friends_only, private
    show_online_status BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Friends table
CREATE TABLE Friends (
    friendship_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    friend_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, blocked
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, friend_id)
);

-- Blocked Users
CREATE TABLE BlockedUsers (
    blocker_id INTEGER NOT NULL,
    blocked_id INTEGER NOT NULL,
    blocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (blocker_id, blocked_id),
    FOREIGN KEY (blocker_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (blocked_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Groups (enhanced)
CREATE TABLE GroupsTable (
    group_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    tag VARCHAR(50) UNIQUE,
    description TEXT,
    display_picture VARCHAR(255),
    cover_image VARCHAR(255),
    privacy_status VARCHAR(20) DEFAULT 'public', -- public, private, secret
    focus VARCHAR(100),
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    member_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    rules TEXT,
    FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Group Members (clean version)
CREATE TABLE GroupMember (
    membership_id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role VARCHAR(20) DEFAULT 'member', -- admin, moderator, member
    status VARCHAR(20) DEFAULT 'active', -- active, banned, pending
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES GroupsTable(group_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    UNIQUE(group_id, user_id)
);

-- Group Join Requests (for private groups)
CREATE TABLE GroupJoinRequests (
    request_id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_by INTEGER,
    reviewed_at TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES GroupsTable(group_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES Users(user_id) ON DELETE SET NULL,
    UNIQUE(group_id, user_id)
);

-- Group Settings
CREATE TABLE GroupSettings (
    group_id INTEGER PRIMARY KEY,
    allow_member_posting BOOLEAN DEFAULT TRUE,
    require_post_approval BOOLEAN DEFAULT FALSE,
    allow_file_uploads BOOLEAN DEFAULT TRUE,
    max_file_size INTEGER DEFAULT 50, -- in MB
    updated_by INTEGER NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES GroupsTable(group_id) ON DELETE CASCADE,
    FOREIGN KEY (updated_by) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Channels (enhanced for group chats)
CREATE TABLE Channel (
    channel_id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES GroupsTable(group_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Posts table with vote counts
CREATE TABLE Post (
    post_id SERIAL PRIMARY KEY,
    content TEXT,
    post_type VARCHAR(20) DEFAULT 'text', -- text, image, video, event, poll, other
    visibility VARCHAR(20) DEFAULT 'public', -- public, friends_only, private, group
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_title VARCHAR(255),
    event_date DATE,
    event_location VARCHAR(255),
    is_group_post BOOLEAN DEFAULT FALSE,
    group_id INTEGER,
    author_id INTEGER NOT NULL,
    upvote_count INTEGER DEFAULT 0,
    downvote_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES GroupsTable(group_id) ON DELETE SET NULL,
    FOREIGN KEY (author_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Post Media
CREATE TABLE PostMedia (
    postmedia_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    uploader_id INTEGER NOT NULL,
    file_name VARCHAR(255),
    file_type VARCHAR(20), -- image, video, document, other
    file_url VARCHAR(255),
    file_size INTEGER,
    duration INTEGER,
    thumbnail_url VARCHAR(255),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (uploader_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Post Views Tracking
CREATE TABLE PostViews (
    view_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL
);

-- Comments (enhanced)
CREATE TABLE Comment (
    comment_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    commenter_id INTEGER NOT NULL,
    parent_comment_id INTEGER,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (commenter_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES Comment(comment_id) ON DELETE CASCADE
);

-- Vote table (replaces Like table)
CREATE TABLE Vote (
    vote_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    vote_type VARCHAR(20) NOT NULL, -- upvote, downvote
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Post(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    UNIQUE(post_id, user_id)
);

-- Chat Conversations (Direct Messages & Group Chats)
CREATE TABLE Conversations (
    conversation_id SERIAL PRIMARY KEY,
    conversation_type VARCHAR(20) DEFAULT 'direct', -- direct, group
    name VARCHAR(255),
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP,
    last_message_text TEXT,
    FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE SET NULL
);

-- Conversation Participants
CREATE TABLE ConversationParticipants (
    participant_id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    role VARCHAR(20) DEFAULT 'member', -- admin, member
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (conversation_id) REFERENCES Conversations(conversation_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    UNIQUE(conversation_id, user_id)
);

-- Messages
CREATE TABLE Messages (
    message_id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text', -- text, image, video, file, system
    content TEXT,
    file_url VARCHAR(255),
    file_name VARCHAR(255),
    file_size INTEGER,
    replied_to_message_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES Conversations(conversation_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (replied_to_message_id) REFERENCES Messages(message_id) ON DELETE SET NULL
);

-- Message Read Status
CREATE TABLE MessageReadStatus (
    message_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (message_id, user_id),
    FOREIGN KEY (message_id) REFERENCES Messages(message_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Notifications (enhanced)
CREATE TABLE Notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    triggered_by_user_id INTEGER,
    type VARCHAR(50) NOT NULL, -- friend_request, friend_request_accepted, post_upvote, etc.
    reference_id INTEGER,
    reference_type VARCHAR(50), -- post, comment, event, group, message, friend_request
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(255),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    priority VARCHAR(20) DEFAULT 'medium', -- low, medium, high
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (triggered_by_user_id) REFERENCES Users(user_id) ON DELETE SET NULL
);

-- Media Files
CREATE TABLE MediaFile (
    media_id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    uploader_id INTEGER NOT NULL,
    channel_id INTEGER,
    file_name VARCHAR(255),
    file_type VARCHAR(20), -- image, video, doc, pdf, other
    file_url VARCHAR(255),
    file_size INTEGER,
    requires_admin_approval BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'approved', -- approved, pending, rejected
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES GroupsTable(group_id) ON DELETE CASCADE,
    FOREIGN KEY (uploader_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (channel_id) REFERENCES Channel(channel_id) ON DELETE SET NULL
);

-- Bins
CREATE TABLE Bin (
    bin_id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    created_by INTEGER NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES GroupsTable(group_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- BinMedia
CREATE TABLE BinMedia (
    bin_id INTEGER NOT NULL,
    media_id INTEGER NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    added_by INTEGER NOT NULL,
    PRIMARY KEY(bin_id, media_id),
    FOREIGN KEY (bin_id) REFERENCES Bin(bin_id) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES MediaFile(media_id) ON DELETE CASCADE,
    FOREIGN KEY (added_by) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- Admin Actions
CREATE TABLE AdminActions (
    action_id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL,
    action_type VARCHAR(50) NOT NULL, -- user_ban, post_remove, comment_remove, group_remove, user_warn
    target_user_id INTEGER,
    target_post_id INTEGER,
    target_group_id INTEGER,
    reason TEXT,
    action_taken_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES Users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (target_post_id) REFERENCES Post(post_id) ON DELETE SET NULL,
    FOREIGN KEY (target_group_id) REFERENCES GroupsTable(group_id) ON DELETE SET NULL
);

-- Reports
CREATE TABLE Reports (
    report_id SERIAL PRIMARY KEY,
    reporter_id INTEGER NOT NULL,
    reported_user_id INTEGER,
    reported_post_id INTEGER,
    reported_comment_id INTEGER,
    reported_group_id INTEGER,
    report_type VARCHAR(50) NOT NULL, -- spam, harassment, inappropriate, other
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, reviewed, resolved
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_by INTEGER,
    reviewed_at TIMESTAMP,
    FOREIGN KEY (reporter_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reported_user_id) REFERENCES Users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (reported_post_id) REFERENCES Post(post_id) ON DELETE SET NULL,
    FOREIGN KEY (reported_comment_id) REFERENCES Comment(comment_id) ON DELETE SET NULL,
    FOREIGN KEY (reported_group_id) REFERENCES GroupsTable(group_id) ON DELETE SET NULL,
    FOREIGN KEY (reviewed_by) REFERENCES Users(user_id) ON DELETE SET NULL
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON Users(email);
CREATE INDEX idx_users_username ON Users(username);
CREATE INDEX idx_posts_author ON Post(author_id);
CREATE INDEX idx_posts_group ON Post(group_id);
CREATE INDEX idx_posts_created ON Post(created_at DESC);
CREATE INDEX idx_comments_post ON Comment(post_id);
CREATE INDEX idx_votes_post_user ON Vote(post_id, user_id);
CREATE INDEX idx_friends_user ON Friends(user_id);
CREATE INDEX idx_friends_friend ON Friends(friend_id);
CREATE INDEX idx_group_members_user ON GroupMember(user_id);
CREATE INDEX idx_group_members_group ON GroupMember(group_id);
CREATE INDEX idx_notifications_user ON Notifications(user_id, is_read);
CREATE INDEX idx_messages_conversation ON Messages(conversation_id, created_at);
CREATE INDEX idx_reports_status ON Reports(status);

-- PostgreSQL Functions and Triggers for maintaining counts
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON Users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groupstable_updated_at BEFORE UPDATE ON GroupsTable
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_post_updated_at BEFORE UPDATE ON Post
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comment_updated_at BEFORE UPDATE ON Comment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Vote count triggers (PostgreSQL version)
CREATE OR REPLACE FUNCTION update_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.vote_type = 'upvote' THEN
            UPDATE Post SET upvote_count = upvote_count + 1 WHERE post_id = NEW.post_id;
        ELSE
            UPDATE Post SET downvote_count = downvote_count + 1 WHERE post_id = NEW.post_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Remove old vote
        IF OLD.vote_type = 'upvote' THEN
            UPDATE Post SET upvote_count = upvote_count - 1 WHERE post_id = OLD.post_id;
        ELSE
            UPDATE Post SET downvote_count = downvote_count - 1 WHERE post_id = OLD.post_id;
        END IF;
        -- Add new vote
        IF NEW.vote_type = 'upvote' THEN
            UPDATE Post SET upvote_count = upvote_count + 1 WHERE post_id = NEW.post_id;
        ELSE
            UPDATE Post SET downvote_count = downvote_count + 1 WHERE post_id = NEW.post_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.vote_type = 'upvote' THEN
            UPDATE Post SET upvote_count = upvote_count - 1 WHERE post_id = OLD.post_id;
        ELSE
            UPDATE Post SET downvote_count = downvote_count - 1 WHERE post_id = OLD.post_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER vote_counts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON Vote
    FOR EACH ROW EXECUTE FUNCTION update_vote_counts();

-- Comment count triggers
CREATE OR REPLACE FUNCTION update_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Post SET comment_count = comment_count + 1 WHERE post_id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Post SET comment_count = comment_count - 1 WHERE post_id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER comment_count_trigger
    AFTER INSERT OR DELETE ON Comment
    FOR EACH ROW EXECUTE FUNCTION update_comment_count();

-- Group member count triggers
CREATE OR REPLACE FUNCTION update_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE GroupsTable SET member_count = member_count + 1 WHERE group_id = NEW.group_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE GroupsTable SET member_count = member_count - 1 WHERE group_id = OLD.group_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER member_count_trigger
    AFTER INSERT OR DELETE ON GroupMember
    FOR EACH ROW EXECUTE FUNCTION update_member_count();