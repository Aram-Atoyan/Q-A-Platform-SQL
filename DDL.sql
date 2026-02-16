DROP TYPE IF EXISTS user_status CASCADE;
DROP TYPE IF EXISTS question_status CASCADE;
DROP TYPE IF EXISTS badge_tier CASCADE;
DROP TABLE IF EXISTS question_tags CASCADE;
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS favoriteQuestions CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS answers CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS badges CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS users CASCADE;
CREATE TYPE user_status AS ENUM ('active', 'suspended');
CREATE TYPE question_status AS ENUM ('open', 'closed');
CREATE TYPE badge_tier AS ENUM ('bronze', 'silver', 'gold');
CREATE TABLE users (
    user_id      BIGSERIAL PRIMARY KEY,
    first_name   TEXT NOT NULL,
    last_name    TEXT NOT NULL,
    email        TEXT UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'), 
    username     TEXT UNIQUE NOT NULL,
    password     TEXT NOT NULL, 
    phone_number TEXT,
    address      TEXT,
    city         TEXT,
    country      TEXT,
    birth_date   DATE,
    gender       CHAR(1) CHECK IN ('M', 'F', 'O'),
    bio          TEXT CHECK (length(bio) <= 500), 
    joined_at    TIMESTAMPTZ DEFAULT now(),
    status       user_status DEFAULT 'active' 
);

CREATE TABLE questions (
    question_id  BIGSERIAL PRIMARY KEY,
    author_id    BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    title        TEXT NOT NULL,
    body         TEXT NOT NULL,
    status       question_status DEFAULT 'open', 
    created_at   TIMESTAMPTZ DEFAULT now(),
    updated_at   TIMESTAMPTZ
);

CREATE TABLE answers (
    answer_id    BIGSERIAL PRIMARY KEY,
    question_id  BIGINT REFERENCES questions(question_id) ON DELETE CASCADE,
    author_id    BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    body         TEXT NOT NULL,
    is_accepted  BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMPTZ DEFAULT now(),
    updated_at   TIMESTAMPTZ
);

CREATE TABLE comments (
    comment_id   BIGSERIAL PRIMARY KEY,
    author_id    BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    question_id  BIGINT REFERENCES questions(question_id) ON DELETE CASCADE,
    answer_id    BIGINT REFERENCES answers(answer_id) ON DELETE CASCADE,
    body         TEXT NOT NULL,
    created_at   TIMESTAMPTZ DEFAULT now(),
    CHECK ((question_id IS NOT NULL) <> (answer_id IS NOT NULL))  
);


CREATE TABLE votes (
    vote_id      BIGSERIAL PRIMARY KEY,
    voter_id     BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    question_id  BIGINT REFERENCES questions(question_id) ON DELETE CASCADE,
    answer_id    BIGINT REFERENCES answers(answer_id) ON DELETE CASCADE,
    vote         SMALLINT CHECK (vote IN (-1, 1)),
    created_at   TIMESTAMPTZ DEFAULT now(),
    CHECK ((question_id IS NOT NULL) <> (answer_id IS NOT NULL))  
);

CREATE UNIQUE INDEX unique_question_vote_idx ON votes (voter_id, question_id) WHERE question_id IS NOT NULL;
CREATE UNIQUE INDEX unique_answer_vote_idx ON votes (voter_id, answer_id) WHERE answer_id IS NOT NULL;

CREATE TABLE tags (
    tag_id       BIGSERIAL PRIMARY KEY,
    name         TEXT UNIQUE NOT NULL,
    description  TEXT
);


CREATE TABLE question_tags (
    question_id  BIGINT REFERENCES questions(question_id) ON DELETE CASCADE,
    tag_id       BIGINT REFERENCES tags(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, tag_id)
);


CREATE TABLE badges (
    badge_id     BIGSERIAL PRIMARY KEY,
    name         TEXT UNIQUE NOT NULL,
    description  TEXT,
    tier         badge_tier NOT NULL, 
    created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE user_badges (
    user_id      BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    badge_id     BIGINT REFERENCES badges(badge_id) ON DELETE RESTRICT,
    awarded_at   TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, badge_id)
);

CREATE TABLE favoriteQuestions (
    user_id      BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    question_id  BIGINT REFERENCES questions(question_id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, question_id)
);