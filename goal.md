# 30-Day Blueprint — Building Hanthane Platform with Modern PHP Stack

## 🎯 Mission Statement
Transform from vanilla PHP/JS developer to full-stack architect by building **Hanthane** — a production-ready university academic collaboration platform using **Spiral Framework + RoadRunner + SvelteKit + PostgreSQL + Redis**. This plan integrates your existing project requirements and creates a complete, deployable system aligned with your proposal goals.

---

## 📋 Project Context

### **What We're Building: Hanthane Platform**
An academic social media platform for University of Colombo that enables:
- **User Management**: Registration, authentication, profile management for students/faculty/admins
- **Group Collaboration**: Create/join public/private academic groups with role-based access
- **Resource Sharing**: Upload, organize, and share files with folder structure and version tracking
- **Discussion Forums**: Posts, comments, likes, and threaded discussions within groups
- **Event Management**: Create, schedule, and track academic events with calendar integration
- **Real-time Features**: Live notifications, chat channels, and online presence
- **Interactive Tools**: Polls, quizzes, and surveys for academic engagement
- **Search & Discovery**: Find groups, posts, files, and users efficiently
- **Admin Dashboard**: Content moderation, user management, and analytics

### **Pre-Flight Checklist**
**What You Have:**
- ✅ Docker, Docker Compose, Composer, Git, Node.js
- ✅ WSL on Windows with PowerShell
- ✅ Solid C/C++ foundation (systems thinking advantage)
- ✅ Basic PHP, JS, HTML, CSS knowledge
- ✅ Complete requirements documentation (proposal.txt, report.txt)
- ✅ Vanilla PHP project structure as reference

**What You Need to Install:**
- [ ] PHP 8.3+ with JIT enabled
- [ ] PostgreSQL 15+ and pgAdmin
- [ ] Redis 7+
- [ ] VS Code extensions: PHP Intelephense, Svelte, Docker, PostgreSQL
- [ ] TablePlus or DBeaver (optional DB GUI)

---

## 🗓️ WEEK 1 — Foundation, Architecture & Core Setup (Days 1-7)

**Week Goal**: Master Docker orchestration, understand modern PHP architecture, and set up the complete development environment with database schema.

### **Day 1: Docker Deep Dive & PHP JIT Setup**
**Deliverables:**
- [ ] Multi-container setup (PHP, PostgreSQL, Redis, Nginx)
- [ ] PHP 8.3 with JIT enabled in docker-compose
- [ ] VS Code configured with Docker integration


---

### **Day 1: Docker Environment & Database Infrastructure**

**Morning: Multi-Container Docker Setup**

**Deliverables:**
- [ ] Complete `docker-compose.yml` with 5 services: PHP 8.3, PostgreSQL 15, Redis 7, Nginx, PgAdmin
- [ ] Custom PHP Dockerfile with JIT enabled (`opcache.jit=tracing`)
- [ ] Health checks for all services
- [ ] Named volumes for data persistence

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: hanthane_db
    environment:
      POSTGRES_DB: hanthane
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secure_pass
      POSTGRES_HOST_AUTH_METHOD: md5
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./DB:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: hanthane_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  php:
    build:
      context: ./docker/php
      dockerfile: Dockerfile
    container_name: hanthane_backend
    working_dir: /app
    volumes:
      - ./backend:/app
      - ./public/uploads:/app/public/uploads
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: hanthane
      DB_USER: admin
      DB_PASSWORD: secure_pass
      REDIS_HOST: redis
      REDIS_PORT: 6379

  nginx:
    image: nginx:alpine
    container_name: hanthane_web
    ports:
      - "80:80"
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./frontend/build:/var/www/frontend
    depends_on:
      - php

  pgadmin:
    image: dpage/pgadmin4
    container_name: hanthane_pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@hanthane.local
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - postgres

volumes:
  postgres_data:
  redis_data:
```

```dockerfile
# docker/php/Dockerfile
FROM php:8.3-cli-alpine

# Install system dependencies
RUN apk add --no-cache \
    postgresql-dev \
    linux-headers \
    $PHPIZE_DEPS

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql opcache

# Enable JIT compilation
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.jit=tracing" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.jit_buffer_size=100M" >> /usr/local/etc/php/conf.d/opcache.ini

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install RoadRunner
RUN wget https://github.com/roadrunner-server/roadrunner/releases/latest/download/roadrunner-linux-amd64.tar.gz \
    && tar -xzf roadrunner-linux-amd64.tar.gz \
    && mv rr /usr/local/bin/rr \
    && chmod +x /usr/local/bin/rr

WORKDIR /app

CMD ["rr", "serve", "-c", ".rr.yaml"]
```

**Afternoon: Database Schema Design**

**Tasks:**
- [ ] Translate ER diagram from proposal into PostgreSQL DDL
- [ ] Create migration file: `01_initial_schema.sql`
- [ ] Define all 15+ tables with constraints, indexes, and relationships

**Key Tables to Implement:**
```sql
-- 01_initial_schema.sql
-- Users and Authentication
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student', -- student, faculty, admin
    avatar_url VARCHAR(500),
    bio TEXT,
    department VARCHAR(100),
    batch VARCHAR(20),
    phone_number VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Groups
CREATE TABLE groups (
    group_id SERIAL PRIMARY KEY,
    group_name VARCHAR(200) NOT NULL,
    description TEXT,
    group_type VARCHAR(20) NOT NULL, -- public, private
    category VARCHAR(50), -- course, club, department, research
    cover_image VARCHAR(500),
    created_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_groups_type ON groups(group_type);
CREATE INDEX idx_groups_category ON groups(category);

-- Group Memberships
CREATE TABLE group_members (
    membership_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(group_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'member', -- admin, member
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, pending, banned
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(group_id, user_id)
);

CREATE INDEX idx_group_members_group ON group_members(group_id);
CREATE INDEX idx_group_members_user ON group_members(user_id);

-- Posts
CREATE TABLE posts (
    post_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(group_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    post_type VARCHAR(20) DEFAULT 'text', -- text, poll, quiz, event
    is_pinned BOOLEAN DEFAULT false,
    is_announcement BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_posts_group ON posts(group_id);
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);

-- Comments
CREATE TABLE comments (
    comment_id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    parent_comment_id INTEGER REFERENCES comments(comment_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);

-- Votes (Likes)
CREATE TABLE votes (
    vote_id SERIAL PRIMARY KEY,
    votable_type VARCHAR(20) NOT NULL, -- post, comment
    votable_id INTEGER NOT NULL,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    vote_type VARCHAR(10) DEFAULT 'like', -- like, upvote
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(votable_type, votable_id, user_id)
);

CREATE INDEX idx_votes_votable ON votes(votable_type, votable_id);

-- Files and Resources
CREATE TABLE files (
    file_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(group_id) ON DELETE CASCADE,
    folder_id INTEGER REFERENCES folders(folder_id) ON DELETE SET NULL,
    uploaded_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size BIGINT,
    mime_type VARCHAR(100),
    version INTEGER DEFAULT 1,
    description TEXT,
    download_count INTEGER DEFAULT 0,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE folders (
    folder_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(group_id) ON DELETE CASCADE,
    parent_folder_id INTEGER REFERENCES folders(folder_id) ON DELETE CASCADE,
    folder_name VARCHAR(255) NOT NULL,
    created_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events
CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(group_id) ON DELETE CASCADE,
    created_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_type VARCHAR(50), -- study_session, workshop, exam, deadline
    location VARCHAR(200),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    is_all_day BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_events_group ON events(group_id);
CREATE INDEX idx_events_time ON events(start_time);

-- Event Participants
CREATE TABLE event_participants (
    participant_id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(event_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'going', -- going, interested, not_going
    reminder_sent BOOLEAN DEFAULT false,
    UNIQUE(event_id, user_id)
);

-- Polls
CREATE TABLE polls (
    poll_id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(post_id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    is_multiple_choice BOOLEAN DEFAULT false,
    closes_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE poll_options (
    option_id SERIAL PRIMARY KEY,
    poll_id INTEGER REFERENCES polls(poll_id) ON DELETE CASCADE,
    option_text VARCHAR(200) NOT NULL,
    vote_count INTEGER DEFAULT 0
);

CREATE TABLE poll_votes (
    vote_id SERIAL PRIMARY KEY,
    poll_id INTEGER REFERENCES polls(poll_id) ON DELETE CASCADE,
    option_id INTEGER REFERENCES poll_options(option_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(poll_id, option_id, user_id)
);

-- Quizzes
CREATE TABLE quizzes (
    quiz_id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(post_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    time_limit INTEGER, -- in minutes
    pass_percentage INTEGER DEFAULT 70,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE quiz_questions (
    question_id SERIAL PRIMARY KEY,
    quiz_id INTEGER REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) DEFAULT 'multiple_choice', -- multiple_choice, true_false
    points INTEGER DEFAULT 1,
    order_number INTEGER NOT NULL
);

CREATE TABLE quiz_answers (
    answer_id SERIAL PRIMARY KEY,
    question_id INTEGER REFERENCES quiz_questions(question_id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT false
);

CREATE TABLE quiz_attempts (
    attempt_id SERIAL PRIMARY KEY,
    quiz_id INTEGER REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    total_points INTEGER NOT NULL,
    percentage DECIMAL(5,2),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Notifications
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    actor_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    notification_type VARCHAR(50) NOT NULL, -- post, comment, like, group_invite, event, etc.
    entity_type VARCHAR(50), -- post, comment, group, event
    entity_id INTEGER,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- Friend Requests (Social Feature)
CREATE TABLE friendships (
    friendship_id SERIAL PRIMARY KEY,
    requester_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected, blocked
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(requester_id, receiver_id)
);

CREATE INDEX idx_friendships_requester ON friendships(requester_id);
CREATE INDEX idx_friendships_receiver ON friendships(receiver_id);

-- Chat Channels (Group Messaging)
CREATE TABLE chat_channels (
    channel_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(group_id) ON DELETE CASCADE,
    channel_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chat_messages (
    message_id SERIAL PRIMARY KEY,
    channel_id INTEGER REFERENCES chat_channels(channel_id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    message_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_messages_channel ON chat_messages(channel_id, created_at);

-- Content Reports (Moderation)
CREATE TABLE reports (
    report_id SERIAL PRIMARY KEY,
    reported_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    entity_type VARCHAR(50) NOT NULL, -- post, comment, user
    entity_id INTEGER NOT NULL,
    reason VARCHAR(50) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, reviewed, resolved
    reviewed_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX idx_reports_status ON reports(status);

-- Audit Logs
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id INTEGER,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Functions and Triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groups_updated_at BEFORE UPDATE ON groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

**Evening: Testing & Documentation**

**Tasks:**
- [ ] Start all Docker containers: `docker-compose up -d`
- [ ] Verify PostgreSQL connection via pgAdmin
- [ ] Run migration: `docker exec -i hanthane_db psql -U admin -d hanthane < DB/01_initial_schema.sql`
- [ ] Test Redis connection: `docker exec -it hanthane_redis redis-cli ping`
- [ ] Document environment setup in `README.md`

**Learning Resources:**
- Docker Compose networking and service dependencies (30 min)
- PostgreSQL indexing strategies for social platforms (45 min)
- PHP 8.3 JIT benchmarking (30 min)

**Success Metrics:**
✅ All 5 containers running with green health checks  
✅ Database schema created with 20+ tables  
✅ Can connect to PostgreSQL and Redis from host machine  

---

---

### **Day 2: Spiral Framework Deep Dive & First Entity**

**Morning: Understanding Modern PHP Architecture (3 hours)**

**Core Concepts to Master:**
- **Dependency Injection (DI)**: Think of it like passing pointers to functions in C, but at the class level
- **Service Containers**: A registry that manages object creation (similar to factory pattern)
- **Bootloaders**: Initialize services when the app starts (like `main()` in C++)

**Learning Path:**
1. Read Spiral Framework docs: "Getting Started" (45 min)
2. Install Spiral skeleton:
   ```bash
   cd backend
   composer create-project spiral/app .
   ```
3. Explore folder structure and compare to MVC pattern (30 min)

**Hands-On Exercise:**
Create a simple "HelloController" to understand request flow:

```php
// backend/app/src/Endpoint/Web/HelloController.php
namespace App\Endpoint\Web;

use Spiral\Router\Annotation\Route;

class HelloController
{
    #[Route(route: '/hello', name: 'hello')]
    public function index(): string
    {
        return 'Hello from Spiral!';
    }
}
```

**Afternoon: Database Connection & First Migration (3 hours)**

**Tasks:**
- [ ] Configure `.env` file with PostgreSQL credentials
- [ ] Create first migration for `users` table
- [ ] Understand Cycle ORM vs raw PDO (you used PDO before)

**Migration Example:**
```bash
php app.php migrate:init
php app.php migrate:create users
```

**Evening: Seed Data & Testing (2 hours)**

**Deliverable:** Insert 5 test users via migration and query them through a controller

**Success Checkpoint:**
✅ Can visit `http://localhost:8080/hello` and see response  
✅ Database has `users` table with test data  
✅ Understand how Spiral routes requests → controllers → models

---

### **Day 3: Authentication System Foundation**

**Morning: Password Hashing & JWT Basics (2 hours)**

**C++ Connection:** You've used hashing functions (like SHA-256), now apply Argon2 in PHP:

```php
// backend/app/src/Service/AuthService.php
namespace App\Service;

class AuthService
{
    public function hashPassword(string $password): string
    {
        return password_hash($password, PASSWORD_ARGON2ID);
    }
    
    public function verifyPassword(string $password, string $hash): bool
    {
        return password_verify($password, $hash);
    }
}
```

**JWT Token Generation:**
```bash
composer require firebase/php-jwt
```

**Afternoon: Registration Endpoint (3 hours)**

**Build:**
- [ ] `POST /api/auth/register` endpoint
- [ ] Validate email format (regex)
- [ ] Check for duplicate emails
- [ ] Hash password before storing

**Request Flow Diagram:**
```
User Browser → Nginx → RoadRunner → AuthController::register()
                                          ↓
                                    UserRepository::create()
                                          ↓
                                    PostgreSQL (users table)
```

**Evening: Login Endpoint & Session Management (3 hours)**

**Tasks:**
- [ ] `POST /api/auth/login` endpoint
- [ ] Verify credentials
- [ ] Generate JWT token with user ID and role
- [ ] Return token to client

**Testing with cURL:**
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@ucsc.cmb.ac.lk","password":"Test123!","firstName":"John"}'
```

**Success Metrics:**
✅ User can register and receive confirmation  
✅ User can log in and receive JWT token  
✅ Token contains user_id and role in payload

---

### **Day 4-5: User Profile System**

**Day 4 Morning: Profile CRUD Backend (3 hours)**

**Entities to Create:**
```php
// backend/app/src/Entity/User.php
namespace App\Entity;

use Cycle\Annotated\Annotation as Cycle;

#[Cycle\Entity(table: 'users')]
class User
{
    #[Cycle\Column(type: 'primary')]
    public int $id;
    
    #[Cycle\Column(type: 'string')]
    public string $email;
    
    #[Cycle\Column(type: 'string')]
    public string $firstName;
    
    #[Cycle\Column(type: 'string', nullable: true)]
    public ?string $avatarUrl = null;
    
    #[Cycle\Column(type: 'datetime')]
    public \DateTimeImmutable $createdAt;
}
```

**Repository Pattern:**
```php
// backend/app/src/Repository/UserRepository.php
namespace App\Repository;

use Cycle\ORM\Select\Repository;

class UserRepository extends Repository
{
    public function findByEmail(string $email): ?User
    {
        return $this->findOne(['email' => $email]);
    }
    
    public function updateProfile(int $userId, array $data): void
    {
        // Update logic with validation
    }
}
```

**Day 4 Afternoon: Avatar Upload (4 hours)**

**File Upload Flow:**
1. Client sends multipart/form-data
2. Validate file type (jpg, png only) and size (<5MB)
3. Generate unique filename: `{user_id}_{timestamp}.jpg`
4. Store in `/public/uploads/avatars/`
5. Save URL in database

**Security Considerations:**
```php
$allowedTypes = ['image/jpeg', 'image/png'];
$maxSize = 5 * 1024 * 1024; // 5MB

if (!in_array($_FILES['avatar']['type'], $allowedTypes)) {
    throw new \Exception('Invalid file type');
}
```

**Day 5: Profile View & Edit Frontend**

**SvelteKit Page Structure:**
```
frontend/src/routes/
  ├── profile/
  │   ├── +page.svelte        # View own profile
  │   ├── edit/
  │   │   └── +page.svelte    # Edit form
  │   └── [id]/
  │       └── +page.svelte    # View other user's profile
```

**Profile Component Example:**
```svelte
<!-- frontend/src/routes/profile/+page.svelte -->
<script>
    import { onMount } from 'svelte';
    import { fetchAPI } from '$lib/api';
    
    let profile = null;
    
    onMount(async () => {
        profile = await fetchAPI('/api/profile/me');
    });
</script>

{#if profile}
    <div class="profile-card">
        <img src={profile.avatarUrl} alt={profile.firstName} />
        <h2>{profile.firstName} {profile.lastName}</h2>
        <p>{profile.department} - Batch {profile.batch}</p>
        <a href="/profile/edit">Edit Profile</a>
    </div>
{/if}
```

**Weekend Checkpoint:**
✅ Complete auth system (register, login, logout)  
✅ Users can view and edit their profiles  
✅ Avatar upload working  
✅ JWT tokens used for protected routes

---

## 🗓️ WEEK 2 — Group System & Content Management (Days 8-14)

### **Day 8: Group Entity & Database Relations**

**Morning: Understanding Group Architecture (2 hours)**

**Database Relationships Review:**
- `groups` ↔ `group_members` (1-to-many)
- `group_members` ↔ `users` (many-to-1)
- `groups` ↔ `posts` (1-to-many)

**Migration for Groups:**
```bash
php app.php migrate:create groups group_members
```

**Afternoon: Group CRUD Backend (4 hours)**

**GroupController Skeleton:**
```php
namespace App\Endpoint\Web;

class GroupController
{
    public function create(CreateGroupRequest $request): array
    {
        // Validate group name (required, 3-100 chars)
        // Check if user already has 10 groups (limit)
        // Set creator as admin
        // Return created group with ID
    }
    
    public function list(): array
    {
        // Return public groups + user's private groups
        // Paginate (20 per page)
    }
    
    public function join(int $groupId): array
    {
        // Public: add immediately
        // Private: create join request
    }
}
```

**Evening: Redis Caching for Group Lists (2 hours)**

**Why Cache?** Group lists don't change often, but are queried frequently

```php
use Predis\Client as RedisClient;

public function getCachedGroupList(): array
{
    $redis = new RedisClient();
    $cacheKey = 'groups:public:list';
    
    if ($cached = $redis->get($cacheKey)) {
        return json_decode($cached, true);
    }
    
    $groups = $this->groupRepository->findAll();
    $redis->setex($cacheKey, 3600, json_encode($groups)); // 1 hour TTL
    
    return $groups;
}
```

---

### **Day 9-10: Post System with Media**

**Day 9 Morning: Post Entity & Relationships (3 hours)**

**Post Types to Support:**
- Text-only
- Text + Images
- Poll
- Event announcement

**Cycle ORM Relation:**
```php
#[Cycle\Entity]
class Post
{
    #[Cycle\Column(type: 'primary')]
    public int $id;
    
    #[Cycle\Relation\BelongsTo(target: Group::class)]
    public Group $group;
    
    #[Cycle\Relation\BelongsTo(target: User::class)]
    public User $author;
    
    #[Cycle\Relation\HasMany(target: Comment::class)]
    public array $comments;
}
```

**Day 9 Afternoon: Create Post Endpoint (4 hours)**

**Request Validation:**
```php
class CreatePostRequest
{
    public string $content;      // Max 5000 chars
    public int $groupId;         // Must exist and user is member
    public ?string $postType = 'text';
    public array $mediaFiles = [];  // Max 5 files
}
```

**Day 10: Post Feed with Pagination**

**Infinite Scroll Backend:**
```php
public function getFeed(int $groupId, int $page = 1): array
{
    $perPage = 20;
    $offset = ($page - 1) * $perPage;
    
    return $this->postRepository
        ->findByGroup($groupId)
        ->orderBy('created_at', 'DESC')
        ->limit($perPage)
        ->offset($offset)
        ->fetchAll();
}
```

**Frontend Infinite Scroll:**
```svelte
<script>
    let posts = [];
    let page = 1;
    let loading = false;
    
    async function loadMore() {
        if (loading) return;
        loading = true;
        
        const newPosts = await fetchAPI(`/api/posts?group_id=${groupId}&page=${page}`);
        posts = [...posts, ...newPosts];
        page++;
        loading = false;
    }
    
    onMount(() => {
        window.addEventListener('scroll', handleScroll);
    });
</script>
```

---

### **Day 11-12: Comments & Voting System**

**Day 11: Threaded Comments**

**Comment Structure:**
- `parent_comment_id` allows nested replies
- Limit nesting to 3 levels for UI clarity

**Backend Logic:**
```php
public function addComment(AddCommentRequest $request): Comment
{
    $comment = new Comment();
    $comment->postId = $request->postId;
    $comment->authorId = $this->getCurrentUserId();
    $comment->content = $this->sanitize($request->content);
    $comment->parentId = $request->parentId; // null for top-level
    
    $this->commentRepository->save($comment);
    $this->notifyPostAuthor($comment);
    
    return $comment;
}
```

**Day 12: Vote System (Like/Upvote)**

**Polymorphic Votes:**
- Same `votes` table handles posts AND comments
- `votable_type` = 'post' or 'comment'
- `votable_id` = ID of the entity

**Toggle Vote Logic:**
```php
public function toggleVote(int $votableId, string $votableType): int
{
    $existingVote = $this->voteRepository->findOne([
        'user_id' => $this->userId,
        'votable_id' => $votableId,
        'votable_type' => $votableType
    ]);
    
    if ($existingVote) {
        $this->voteRepository->delete($existingVote);
        return -1; // Removed vote
    }
    
    $vote = new Vote($this->userId, $votableId, $votableType);
    $this->voteRepository->save($vote);
    return 1; // Added vote
}
```

---

### **Day 13-14: File Sharing System**

**Day 13: File Upload with Chunking (Advanced)**

**Why Chunking?** Large PDFs (>50MB) may timeout on slow connections

**Client-Side (Svelte):**
```javascript
async function uploadLargeFile(file) {
    const chunkSize = 1024 * 1024; // 1MB chunks
    const chunks = Math.ceil(file.size / chunkSize);
    
    for (let i = 0; i < chunks; i++) {
        const chunk = file.slice(i * chunkSize, (i + 1) * chunkSize);
        const formData = new FormData();
        formData.append('file', chunk);
        formData.append('chunkIndex', i);
        formData.append('totalChunks', chunks);
        
        await fetch('/api/files/upload-chunk', {
            method: 'POST',
            body: formData
        });
    }
}
```

**Server-Side Reassembly:**
```php
public function handleChunk(Request $request): void
{
    $chunkIndex = $request->get('chunkIndex');
    $totalChunks = $request->get('totalChunks');
    $file = $request->files->get('file');
    
    $tempPath = "/tmp/upload_{$sessionId}_{$chunkIndex}";
    move_uploaded_file($file->getPathname(), $tempPath);
    
    if ($this->allChunksReceived($sessionId, $totalChunks)) {
        $this->mergeChunks($sessionId, $totalChunks);
    }
}
```

**Day 14: Folder Organization**

**Folder CRUD:**
```php
class FolderController
{
    public function createFolder(int $groupId, string $name): Folder
    {
        $folder = new Folder();
        $folder->groupId = $groupId;
        $folder->name = $name;
        $folder->parentId = $request->parentId ?? null;
        
        return $this->folderRepository->save($folder);
    }
}
```

**File Metadata Storage:**
```sql
-- files table already created in Day 1, now populate it
INSERT INTO files (group_id, folder_id, uploaded_by, file_name, file_path, mime_type)
VALUES (1, 3, 42, 'lecture_notes.pdf', '/uploads/groups/1/notes/lecture_notes.pdf', 'application/pdf');
```

---

## 🎨 WEEK 3 — Frontend Polish & Real-Time Features (Days 15-21)

### **Day 15-16: SvelteKit Routing & State Management**

**Day 15: Understanding Svelte Stores (3 hours)**

**Why Stores?** Share state across components (like global variables in C++)

```javascript
// frontend/src/lib/stores/auth.js
import { writable } from 'svelte/store';

function createAuthStore() {
    const { subscribe, set, update } = writable({
        user: null,
        token: null,
        isAuthenticated: false
    });
    
    return {
        subscribe,
        login: (user, token) => {
            localStorage.setItem('auth_token', token);
            set({ user, token, isAuthenticated: true });
        },
        logout: () => {
            localStorage.removeItem('auth_token');
            set({ user: null, token: null, isAuthenticated: false });
        }
    };
}

export const auth = createAuthStore();
```

**Day 16: Building Reusable Components**

**Component Library to Create:**
- `Button.svelte` (primary, secondary, danger variants)
- `Modal.svelte` (for confirmations)
- `Dropdown.svelte` (for menus)
- `Avatar.svelte` (user profile pictures)

**Example Button Component:**
```svelte
<!-- frontend/src/lib/components/Button.svelte -->
<script>
    export let variant = 'primary'; // primary | secondary | danger
    export let disabled = false;
    export let loading = false;
</script>

<button 
    class="btn btn-{variant}" 
    {disabled}
    on:click
>
    {#if loading}
        <span class="spinner"></span>
    {:else}
        <slot></slot>
    {/if}
</button>

<style>
    .btn {
        padding: 0.5rem 1rem;
        border-radius: 0.25rem;
        cursor: pointer;
    }
    .btn-primary { background: #3b82f6; color: white; }
    .btn-secondary { background: #6b7280; color: white; }
    .btn-danger { background: #ef4444; color: white; }
</style>
```

---

### **Day 17-18: Group & Post UI Implementation**

**Day 17: Group Discovery Page**

**Layout:**
```svelte
<!-- frontend/src/routes/groups/+page.svelte -->
<script>
    import { onMount } from 'svelte';
    import GroupCard from '$lib/components/GroupCard.svelte';
    
    let groups = [];
    let searchQuery = '';
    let filter = 'all'; // all | public | private
    
    $: filteredGroups = groups.filter(g => {
        const matchesSearch = g.name.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesFilter = filter === 'all' || g.type === filter;
        return matchesSearch && matchesFilter;
    });
    
    onMount(async () => {
        groups = await fetchAPI('/api/groups');
    });
</script>

<div class="container">
    <input bind:value={searchQuery} placeholder="Search groups..." />
    
    <div class="filters">
        <button on:click={() => filter = 'all'}>All</button>
        <button on:click={() => filter = 'public'}>Public</button>
        <button on:click={() => filter = 'private'}>Private</button>
    </div>
    
    <div class="grid">
        {#each filteredGroups as group}
            <GroupCard {group} />
        {/each}
    </div>
</div>
```

**Day 18: Post Feed with Interactions**

**Real-Time UI Updates:**
```svelte
<script>
    async function handleVote(postId) {
        const result = await fetchAPI(`/api/posts/${postId}/vote`, { method: 'POST' });
        
        // Optimistic UI update
        posts = posts.map(p => 
            p.id === postId 
                ? { ...p, voteCount: p.voteCount + result.delta, userVoted: !p.userVoted }
                : p
        );
    }
</script>

{#each posts as post}
    <div class="post-card">
        <p>{post.content}</p>
        <button 
            class:voted={post.userVoted}
            on:click={() => handleVote(post.id)}
        >
            👍 {post.voteCount}
        </button>
    </div>
{/each}
```

---

### **Day 19-20: File Upload UI & Progress Tracking**

**Day 19: Drag-and-Drop File Upload**

```svelte
<script>
    let dragging = false;
    let uploadProgress = 0;
    
    function handleDrop(e) {
        dragging = false;
        const files = e.dataTransfer.files;
        uploadFiles(files);
    }
    
    async function uploadFiles(files) {
        for (const file of files) {
            const formData = new FormData();
            formData.append('file', file);
            
            const response = await fetch('/api/files/upload', {
                method: 'POST',
                body: formData,
                onUploadProgress: (e) => {
                    uploadProgress = (e.loaded / e.total) * 100;
                }
            });
        }
    }
</script>

<div 
    class="dropzone"
    class:dragging
    on:drop|preventDefault={handleDrop}
    on:dragover|preventDefault={() => dragging = true}
    on:dragleave={() => dragging = false}
>
    Drop files here or click to browse
    
    {#if uploadProgress > 0}
        <progress value={uploadProgress} max="100"></progress>
    {/if}
</div>
```

**Day 20: File Browser with Folders**

**Tree Structure Component:**
```svelte
<!-- frontend/src/lib/components/FileTree.svelte -->
<script>
    export let folders = [];
    export let files = [];
    export let onFileClick;
    
    let expandedFolders = new Set();
</script>

<ul class="file-tree">
    {#each folders as folder}
        <li>
            <button on:click={() => expandedFolders.has(folder.id) 
                ? expandedFolders.delete(folder.id) 
                : expandedFolders.add(folder.id)}>
                📁 {folder.name}
            </button>
            
            {#if expandedFolders.has(folder.id)}
                <svelte:self 
                    folders={folder.subfolders} 
                    files={folder.files}
                    {onFileClick}
                />
            {/if}
        </li>
    {/each}
    
    {#each files as file}
        <li>
            <button on:click={() => onFileClick(file)}>
                📄 {file.name}
            </button>
        </li>
    {/each}
</ul>
```

---

### **Day 21: Notifications System**

**Backend: Notification Queue**

```php
// backend/app/src/Service/NotificationService.php
public function notify(int $userId, string $type, array $data): void
{
    $notification = new Notification();
    $notification->userId = $userId;
    $notification->type = $type;
    $notification->message = $this->buildMessage($type, $data);
    $notification->entityType = $data['entity_type'] ?? null;
    $notification->entityId = $data['entity_id'] ?? null;
    
    $this->notificationRepository->save($notification);
    
    // Push to Redis for real-time delivery
    $this->redis->publish("notifications:user:$userId", json_encode($notification));
}
```

**Frontend: Notification Bell**

```svelte
<script>
    import { onMount, onDestroy } from 'svelte';
    
    let notifications = [];
    let unreadCount = 0;
    let ws;
    
    onMount(() => {
        // Fetch initial notifications
        fetchAPI('/api/notifications').then(data => {
            notifications = data;
            unreadCount = data.filter(n => !n.isRead).length;
        });
        
        // Connect to WebSocket for real-time updates
        ws = new WebSocket('ws://localhost:8080/notifications');
        ws.onmessage = (event) => {
            const newNotification = JSON.parse(event.data);
            notifications = [newNotification, ...notifications];
            unreadCount++;
        };
    });
    
    onDestroy(() => ws?.close());
</script>

<button class="notification-bell">
    🔔
    {#if unreadCount > 0}
        <span class="badge">{unreadCount}</span>
    {/if}
</button>
```

---

## 🚀 WEEK 4 — Production Deployment & Polish (Days 22-30)

### **Day 22-23: Background Jobs with RoadRunner**

**Configure Job Queue:**

```yaml
# backend/.rr.yaml
jobs:
  num_pollers: 2
  pipeline_size: 100
  pool:
    num_workers: 4
  
  pipelines:
    default:
      driver: memory
```

**Email Notification Job:**

```php
// backend/app/src/Job/SendEmailJob.php
namespace App\Job;

use Spiral\Queue\JobHandler;

class SendEmailJob extends JobHandler
{
    public function invoke(string $to, string $subject, string $body): void
    {
        // Using PHPMailer or SMTP
        $mail = new \PHPMailer\PHPMailer\PHPMailer();
        $mail->isSMTP();
        $mail->Host = $_ENV['SMTP_HOST'];
        $mail->Username = $_ENV['SMTP_USER'];
        $mail->Password = $_ENV['SMTP_PASS'];
        
        $mail->setFrom('noreply@hanthane.edu', 'Hanthane Platform');
        $mail->addAddress($to);
        $mail->Subject = $subject;
        $mail->Body = $body;
        
        $mail->send();
    }
}
```

**Dispatch Job:**

```php
$this->queue->push(SendEmailJob::class, [
    'to' => $user->email,
    'subject' => 'Welcome to Hanthane!',
    'body' => 'Your account has been created.'
]);
```

---

### **Day 24-25: Docker Production Setup**

**Day 24: Multi-Stage Dockerfile**

```dockerfile
# frontend/Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/build ./build
COPY --from=builder /app/package*.json ./
RUN npm ci --only=production
EXPOSE 3000
CMD ["node", "build"]
```

**Day 25: Nginx Configuration**

```nginx
# docker/nginx/nginx.conf
upstream backend {
    server php:8080;
}

upstream frontend {
    server frontend:3000;
}

server {
    listen 80;
    server_name hanthane.local;
    
    client_max_body_size 50M;
    
    location /api {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /uploads {
        alias /var/www/uploads;
        expires 30d;
    }
    
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
    }
}
```

---

### **Day 26-27: Testing & CI/CD**

**Day 26: PHPUnit Tests**

```php
// backend/tests/Unit/AuthServiceTest.php
namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use App\Service\AuthService;

class AuthServiceTest extends TestCase
{
    public function testPasswordHashing()
    {
        $auth = new AuthService();
        $password = 'Test123!';
        
        $hash = $auth->hashPassword($password);
        
        $this->assertNotEquals($password, $hash);
        $this->assertTrue($auth->verifyPassword($password, $hash));
    }
    
    public function testJWTTokenGeneration()
    {
        $auth = new AuthService();
        $token = $auth->generateToken(['user_id' => 1, 'role' => 'student']);
        
        $this->assertNotEmpty($token);
        $payload = $auth->verifyToken($token);
        $this->assertEquals(1, $payload['user_id']);
    }
}
```

**Day 27: GitHub Actions Workflow**

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
      
      - name: Run Tests
        run: |
          cd backend
          composer install
          vendor/bin/phpunit
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /var/www/hanthane
            git pull origin main
            docker-compose up -d --build
```

---

### **Day 28-29: Performance Optimization**

**Day 28: Database Query Optimization**

**N+1 Problem Detection:**

```php
// BAD: N+1 queries
$posts = $postRepository->findAll();
foreach ($posts as $post) {
    echo $post->author->name; // Triggers separate query per post
}

// GOOD: Eager loading
$posts = $postRepository->findAll()->with('author');
foreach ($posts as $post) {
    echo $post->author->name; // No extra queries
}
```

**Redis Full-Page Caching:**

```php
public function getCachedGroupPage(int $groupId): string
{
    $cacheKey = "group:page:$groupId";
    
    if ($cached = $this->redis->get($cacheKey)) {
        return $cached;
    }
    
    $html = $this->renderGroupPage($groupId);
    $this->redis->setex($cacheKey, 600, $html); // 10 min cache
    
    return $html;
}
```

**Day 29: Frontend Optimization**

**Code Splitting:**

```javascript
// frontend/src/routes/+layout.js
export const prerender = false;

// Lazy load heavy components
const GroupProfile = () => import('$lib/components/GroupProfile.svelte');
const FileUpload = () => import('$lib/components/FileUpload.svelte');
```

**Image Optimization:**

```bash
npm install @sveltejs/adapter-auto sharp
```

```javascript
// frontend/svelte.config.js
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

export default {
    preprocess: vitePreprocess(),
    kit: {
        adapter: adapter(),
        prerender: {
            entries: ['/']
        }
    }
};
```

---

### **Day 30: Launch & Documentation**

**Morning: Final Deployment Checklist**

- [ ] Environment variables configured (`.env.production`)
- [ ] Database migrations run on production
- [ ] SSL certificate installed (Let's Encrypt)
- [ ] Backups configured (daily PostgreSQL dumps)
- [ ] Monitoring setup (Sentry for errors, Grafana for metrics)

**Afternoon: Documentation**

**README.md Structure:**

```markdown
# Hanthane Platform

## Quick Start
```bash
# Clone repository
git clone https://github.com/your-username/hanthane.git
cd hanthane

# Start all services
docker-compose up -d

# Run migrations
docker exec hanthane_backend php app.php migrate

# Seed demo data
docker exec hanthane_backend php app.php db:seed
```

## Architecture
- **Backend**: Spiral Framework + RoadRunner (PHP 8.3)
- **Frontend**: SvelteKit + TailwindCSS
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Web Server**: Nginx

## API Documentation
[View OpenAPI Spec](docs/api.yaml)

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md)
```

**Evening: Video Demo & Presentation**

**Demo Script (10 minutes):**
1. User registration & login (1 min)
2. Create academic group (1 min)
3. Upload study materials (2 min)
4. Create post with poll (2 min)
5. Real-time notifications (1 min)
6. Admin moderation dashboard (2 min)
7. Performance metrics showcase (1 min)

**Deployment Evidence:**
- Live URL: `https://hanthane.yourdomain.com`
- Load test results: 1000 concurrent users
- Lighthouse score: 90+ performance

---

## 📊 Final Success Metrics

**By Day 30 You Will Have:**
1. ✅ Fully functional university social platform
2. ✅ 20+ API endpoints with JWT authentication
3. ✅ Real-time notifications via WebSockets
4. ✅ Production-grade Docker setup with CI/CD
5. ✅ Comprehensive test suite (unit + e2e)
6. ✅ Complete documentation (user + developer guides)
7. ✅ Performance benchmarks: <50ms API response, <2.5s LCP

**Portfolio-Ready Evidence:**
- [ ] GitHub repository with 100+ commits
- [ ] Live deployed application
- [ ] Architecture diagram (draw.io)
- [ ] 3-minute video demo
- [ ] Blog post: "Building a University Social Platform"

---

## 🧠 Learning Milestones Tracker

**Week 1: Foundation**
- [x] Docker orchestration mastery
- [x] PostgreSQL schema design
- [x] Modern PHP (Spiral) understanding
- [x] JWT authentication implementation

**Week 2: Backend Mastery**
- [x] RESTful API design
- [x] ORM relationships (Cycle)
- [x] File upload handling
- [x] Redis caching strategies

**Week 3: Frontend Skills**
- [x] SvelteKit routing
- [x] Component architecture
- [x] State management (stores)
- [x] WebSocket integration

**Week 4: DevOps**
- [x] Docker Compose orchestration
- [x] Nginx reverse proxy
- [x] CI/CD pipeline (GitHub Actions)
- [x] Performance optimization

---

## 🎯 Post-30-Day Action Plan

**Month 2 (Days 31-60): Feature Expansion**
- [ ] Add event calendar (FullCalendar.js)
- [ ] Implement private messaging (1-on-1 chat)
- [ ] Build admin analytics dashboard
- [ ] Add email notification system
- [ ] Integrate markdown editor (for posts)

**Month 3 (Days 61-90): Scale & Refine**
- [ ] Add search with Elasticsearch
- [ ] Implement rate limiting (prevent spam)
- [ ] Add user blocking/reporting
- [ ] Create mobile-responsive PWA
- [ ] Launch closed beta (50 users)

**Month 4-6: Startup Phase**
- [ ] Open beta at University of Colombo (500 users)
- [ ] Gather feedback and iterate
- [ ] Recruit 2-3 developers (show this project as proof)
- [ ] Apply for university incubation programs
- [ ] Plan monetization (premium features or institutional licensing)

---

## 🛠️ Daily Learning Routine

**Every Morning (30 min):**
1. Review yesterday's code
2. Read 1 section of official docs:
   - Spiral Framework docs
   - SvelteKit tutorial
   - PostgreSQL performance tips

**Every Evening (30 min):**
1. Git commit with descriptive messages
2. Update `NOTES.md` with:
   - 3 things learned
   - 1 challenge faced
   - 1 solution discovered

**Weekend Reviews:**
- Refactor messy code
- Write tests for critical paths
- Deploy to staging environment

---

## 💡 Debugging Philosophy (From Your C++ Background)

**When Stuck (>30 min):**
1. **Isolate the problem**: Create minimal reproducible example
2. **Print debug**: Use `var_dump()` (PHP) or `console.log()` (JS)
3. **Check data flow**: Verify API request → controller → model → database
4. **Search GitHub Issues**: Someone likely faced this before
5. **Ask AI assistant**: Explain error message + share code snippet

**Common Pitfalls to Avoid:**
- ❌ Forgetting to restart RoadRunner after code changes
- ❌ Not clearing Redis cache after data updates
- ❌ CORS errors (configure Nginx properly)
- ❌ SQL N+1 queries (use eager loading)
- ❌ Large file uploads timing out (implement chunking)

---

## 🎓 Learning Resources Reference

**Official Docs (Prioritize These):**
- [Spiral Framework](https://spiral.dev/docs)
- [RoadRunner](https://roadrunner.dev/docs)
- [SvelteKit](https://kit.svelte.dev/docs)
- [PostgreSQL](https://www.postgresql.org/docs/)
- [Redis](https://redis.io/docs/)

**YouTube Channels (15-min learning breaks):**
- Traversy Media (web dev fundamentals)
- Fireship (tech comparisons in 100 seconds)
- The Net Ninja (SvelteKit tutorials)

**When You Need Help:**
- Discord: [Spiral Framework Community](https://discord.gg/spiral)
- Reddit: r/PHP, r/sveltejs
- Stack Overflow (search before asking)

---

## 🚀 Final Motivation

**Remember:**
- You're not just learning a stack—you're building a startup-ready product
- Your C/C++ systems thinking gives you an edge in performance optimization
- Every bug you fix makes you a better engineer
- By Day 30, you'll have a portfolio project that impresses recruiters and investors

**Your GitHub profile will show:**
- 100+ commits over 30 days
- Multi-container Docker setup
- Production deployment
- Real users (beta testers)

**This is your proof of "I can build and ship."**

Now execute. 🔥

---

**End of 30-Day Blueprint**