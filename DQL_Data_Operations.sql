-- user registration

create or replace function register(
	p_first_name text, 
	p_last_name text,
	p_email text,
	p_username text,
	p_password text,
	p_phone_number text,
	p_address text,
	p_city text,
	p_country text,
	p_birth_date date,
	p_gender char(1),
	p_bio text,
	p_status user_status
) 
returns boolean as $$
begin
	insert into users (first_name, last_name, email, username, password, phone_number, address, city, country, birth_date, gender, bio, status, joined_at)
	values (p_first_name, p_last_name, p_email, p_username, p_password, p_phone_number, p_address, p_city, p_country, p_birth_date, p_gender, p_bio, p_status, CURRENT_TIMESTAMP);
	
	return true;
end;
$$ language plpgsql;

-- posting a question

create or replace function post_question(
	p_author_id bigint,
	p_title text,
	p_body text,
	p_status public.question_status
)
returns boolean as $$
begin
	
	if (select status from users where user_id = p_author_id) = 'active' then
		insert into questions (
			author_id, title, body, status, created_at
		) values (
			p_author_id, p_title, p_body, p_status, CURRENT_TIMESTAMP
		);
		return true;
	end if;
	return false;
end;
$$ language plpgsql;

----------------------

-- deleting a question

create or replace function delete_question(p_question_id bigint)
returns boolean as $$
begin
	delete from questions where question_id = p_question_id;
	return true;
end;
$$ language plpgsql;

-- updating a question

create or replace function update_question(
	p_id bigint, p_title text, p_body text, p_status public.question_status
)
returns boolean as $$
begin
	update questions set title = p_title, body = p_body, status = p_status, updated_at = CURRENT_TIMESTAMP where question_id = p_id;
	return true;
end;
$$ language plpgsql;

-- posting an answer

create or replace function post_answer(
	p_question_id bigint,
	p_author_id bigint,
	p_body text
)
returns boolean as $$
begin
	insert into answers (question_id, author_id, body, is_accepted, created_at, updated_at)
	values (p_question_id, p_author_id, p_body, false, CURRENT_TIMESTAMP, null);
	return true;
end;
$$ language plpgsql;

-- accepting an answer

create or replace function accept_answer(
	p_answer_id bigint, p_author_id bigint
)
returns boolean as $$
begin
	update answers set is_accepted = true, updated_at = CURRENT_TIMESTAMP
	from answers a inner join questions q on a.question_id = q.question_id and a.answer_id = p_answer_id and q.author_id = p_author_id;
	return true;
end;
$$ language plpgsql;

-- commenting on question or answer

create or replace function make_comment (
	p_author_id bigint,
	p_question_id bigint,
	p_answer_id bigint,
	p_body text
)
returns boolean as $$
begin
	if p_question_id is not null and p_answer_id is not null then return false;
	end if;
	if p_question_id is null and p_answer_id is null then return false;
	end if;

	insert into comments (
		author_id, question_id, answer_id, body, created_at
	) values (
		p_author_id, p_question_id, p_answer_id, p_body, CURRENT_TIMESTAMP
	);
	return true;
end;
$$ language plpgsql;

-- voting on questions or answers

create or replace function make_vote(
	p_voter_id bigint,
	p_question_id bigint,
	p_answer_id bigint,
	p_vote smallint
)
returns boolean as $$
begin
	if p_answer_id is not null and p_question_id is not null then return false; end if;
	if p_answer_id is null and p_question_id is null then return false; end if;
	if exists (select * from votes where voter_id = p_voter_id and vote = p_vote and (question_id = p_question_id or answer_id = p_answer_id)) then return false; end if;	

	insert into votes (voter_id, question_id, answer_id, vote, created_at)
	values (p_voter_id, p_question_id, p_answer_id, p_vote, CURRENT_TIMESTAMP);

	return true;
end;
$$ language plpgsql;

-- adding tags to questions
create or replace function add_tag_to_question(
	p_question_id bigint,
	p_tag_name text,
	p_tag_description text
)
returns boolean as $$
declare p_tag_id bigint;
begin
	select tag_id into p_tag_id from tags where tag_name = p_tag_name;
	if p_tag_id is null then 
		insert into tags (name, description) values (p_tag_name, p_tag_description);
	end if;
	select tag_id into p_tag_id from tags where tag_name = p_tag_name;
	insert into question_tags (question_id, tag_id) values (p_question_id, p_tag_id);
	return true;	
end;
$$ language plpgsql;

-- earning a badge
-- todo, criteria need to be discussed

-- favoriting a question
create or replace function bookmark_question (p_user_id bigint, p_question_id bigint)
returns boolean as $$
begin
	insert into favoriteQuestions (user_id, question_id, created_at) values (p_user_id, p_question_id, CURRENT_TIMESTAMP);
	return true;
end;
$$ language plpgsql;

-- deactivating an account
create or replace function deactivate_account(p_user_id bigint)
returns boolean as $$
begin
	delete from users where user_id = p_user_id;
	return true;
end;
$$ language plpgsql;

-- tested, working
-- when a user joins the community, they get a badge 'Pioneer'
create or replace function assign_pioneer_badge()
returns trigger as $$

begin
	insert into user_badges (user_id, badge_id, awarded_at) values (new.user_id, 401, CURRENT_TIMESTAMP);
	return new;
end;
$$ language plpgsql;

create or replace trigger assign_pineer_badge_trigger
after insert on users
for each row
execute function assign_pioneer_badge();

-- tested, working
-- when a user edits 10 posts, he gets a badge editor
create or replace function assign_editor_badge()
returns trigger as $$
declare c bigint;
begin
	select count(*) into c from questions where updated_at is not null and author_id = old.author_id;
	if c = 10
		then insert into user_badges (user_id, badge_id, awarded_at) values (old.author_id, 402, CURRENT_TIMESTAMP);
	end if;
	return old;
end;
$$ language plpgsql;

create or replace trigger assign_editor_badge_trigger
after update of updated_at on questions
for each row
execute function assign_editor_badge();

-- working, tested
-- for each answer with 10 or more upvotes user receives a good answer badge
create or replace function assign_good_answer_badge()
returns trigger as $$
declare c bigint;
begin
	select count(*) into c from votes where answer_id = new.answer_id and vote = 1;
	if c = 10 then 
		insert into user_badges (user_id, badge_id, awarded_at) 
		select a.author_id, 403, CURRENT_TIMESTAMP
		from answers a where a.answer_id = new.answer_id;
	end if;
	return new;
end;
$$ language plpgsql;

create or replace trigger assign_good_answer_badge
after insert on votes
for each row
execute function assign_good_answer_badge();

-- working, tested
-- for each question with 17+ upvotes the question author receives a badge stellar author
create or replace function assign_stellar_author_badge()
returns trigger as $$
declare c bigint;
begin
	select count(*) into c from votes where question_id = new.question_id and vote = 1;
	if c = 17 then
		insert into user_badges (user_id, badge_id, awarded_at)
		select q.author_id, 405, CURRENT_TIMESTAMP
		from questions q where q.question_id = new.question_id;
	end if;
	return new;
end;
$$ language plpgsql;

create or replace trigger assign_stellar_author_badge_trigger
after insert on votes
for each row
execute function assign_stellar_author_badge();

-- working, tested
-- for each question which was favorited 10 or more times, the user receives a badge eminent
create or replace function assign_eminent_badge()
returns trigger as $$
declare c bigint;
begin
	select count(*) into c from favoriteQuestions where question_id = new.question_id;
	if c = 10 then
		insert into user_badges (user_id, badge_id, awarded_at)
		select q.author_id, 404, CURRENT_TIMESTAMP
		from questions q where q.question_id = new.question_id;
	end if;
	return new;
end;
$$ language plpgsql;

create or replace trigger assign_eminent_badge_trigger
after insert on favoriteQuestions
for each row
execute function assign_eminent_badge();