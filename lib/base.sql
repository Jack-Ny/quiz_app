-- LES DONNEES DE LA BASE DE DONNEES --

-- Table users --
create table
  public.users (
    id uuid not null,
    email text not null,
    user_type text not null,
    name text null,
    profile_picture text null,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    updated_at timestamp with time zone not null default timezone ('utc'::text, now()),
    is_active boolean null default true,
    constraint users_pkey primary key (id),
    constraint users_email_key unique (email),
    constraint users_id_fkey foreign key (id) references auth.users (id),
    constraint users_user_type_check check (
      (
        user_type = any (
          array[
            'admin'::text,
            'student'::text,
            'teacher'::text,
            'parent'::text
          ]
        )
      )
    )
  ) tablespace pg_default;

create trigger handle_users_updated_at before
update on users for each row
execute function handle_updated_at ();

-- table TPS --
create table
  public.tps (
    id uuid not null default extensions.uuid_generate_v4 (),
    module_id uuid null,
    title text not null,
    description text not null,
    due_date timestamp with time zone null,
    max_points integer null,
    is_active boolean null default true,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    file_urls text[] null default '{}'::text[],
    constraint tps_pkey primary key (id),
    constraint tps_module_id_fkey foreign key (module_id) references modules (id) on delete cascade
  ) tablespace pg_default;

-- table TPSUBMISSIONS --
create table
  public.tp_submissions (
    id uuid not null default extensions.uuid_generate_v4 (),
    tp_id uuid null,
    student_id uuid null,
    submitted_files jsonb not null,
    comment text null,
    submission_date timestamp with time zone not null default timezone ('utc'::text, now()),
    grade integer null,
    graded_by uuid null,
    graded_at timestamp with time zone null,
    constraint tp_submissions_pkey primary key (id),
    constraint tp_submissions_tp_id_student_id_key unique (tp_id, student_id),
    constraint tp_submissions_graded_by_fkey foreign key (graded_by) references teachers (id) on delete set null,
    constraint tp_submissions_student_id_fkey foreign key (student_id) references students (id) on delete cascade,
    constraint tp_submissions_tp_id_fkey foreign key (tp_id) references tps (id) on delete cascade
  ) tablespace pg_default;

-- table TEACHERS --
create table
  public.teachers (
    id uuid not null default extensions.uuid_generate_v4 (),
    user_id uuid null,
    specialization text not null,
    constraint teachers_pkey primary key (id),
    constraint teachers_user_id_key unique (user_id),
    constraint teachers_user_id_fkey foreign key (user_id) references users (id) on delete cascade
  ) tablespace pg_default;

-- table TEACHERS_COURSES --
create table
  public.teacher_courses (
    teacher_id uuid not null,
    course_id uuid not null,
    constraint teacher_courses_pkey primary key (teacher_id, course_id),
    constraint teacher_courses_course_id_fkey foreign key (course_id) references courses (id) on delete cascade,
    constraint teacher_courses_teacher_id_fkey foreign key (teacher_id) references teachers (id) on delete cascade
  ) tablespace pg_default;

-- table STUDENTS --
create table
  public.students (
    id uuid not null default extensions.uuid_generate_v4 (),
    user_id uuid null,
    registration_number text not null,
    class_level text not null,
    parent_id uuid null,
    constraint students_pkey primary key (id),
    constraint students_registration_number_key unique (registration_number),
    constraint students_user_id_key unique (user_id),
    constraint students_parent_id_fkey foreign key (parent_id) references users (id) on delete set null,
    constraint students_user_id_fkey foreign key (user_id) references users (id) on delete cascade
  ) tablespace pg_default;

-- table STUDENT_PARENTS --
create table
  public.student_parents (
    parent_id uuid not null,
    student_id uuid not null,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    constraint student_parents_pkey primary key (parent_id, student_id),
    constraint student_parents_parent_id_fkey foreign key (parent_id) references parents (id) on delete cascade,
    constraint student_parents_student_id_fkey foreign key (student_id) references students (id) on delete cascade
  ) tablespace pg_default;

-- table QUIZZES --
create table
  public.quizzes (
    id uuid not null default extensions.uuid_generate_v4 (),
    module_id uuid null,
    title text not null,
    time_limit integer not null,
    time_unit text not null,
    passing_score integer null default 75,
    is_active boolean null default true,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    constraint quizzes_pkey primary key (id),
    constraint quizzes_module_id_fkey foreign key (module_id) references modules (id) on delete cascade
  ) tablespace pg_default;

-- table QUIZ_ATTEMPTS --
create table
  public.quiz_attempts (
    id uuid not null default extensions.uuid_generate_v4 (),
    student_id uuid null,
    quiz_id uuid null,
    start_time timestamp with time zone not null default timezone ('utc'::text, now()),
    end_time timestamp with time zone null,
    score integer null,
    is_completed boolean null default false,
    constraint quiz_attempts_pkey primary key (id),
    constraint quiz_attempts_student_id_quiz_id_key unique (student_id, quiz_id),
    constraint quiz_attempts_quiz_id_fkey foreign key (quiz_id) references quizzes (id) on delete cascade,
    constraint quiz_attempts_student_id_fkey foreign key (student_id) references students (id) on delete cascade
  ) tablespace pg_default;

-- table QUESTIONS --
create table
  public.questions (
    id uuid not null default extensions.uuid_generate_v4 (),
    quiz_id uuid null,
    question_text text not null,
    question_type text not null,
    answer text not null,
    points integer not null,
    choices jsonb null,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    constraint questions_pkey primary key (id),
    constraint questions_quiz_id_fkey foreign key (quiz_id) references quizzes (id) on delete cascade,
    constraint questions_question_type_check check (
      (
        question_type = any (
          array[
            'trueFalse'::text,
            'singleAnswer'::text,
            'selection'::text
          ]
        )
      )
    )
  ) tablespace pg_default;

-- table QUESTION_RESPONSES --
create table
  public.question_responses (
    id uuid not null default extensions.uuid_generate_v4 (),
    attempt_id uuid null,
    question_id uuid null,
    student_answer text not null,
    is_correct boolean not null,
    points_earned integer not null,
    constraint question_responses_pkey primary key (id),
    constraint question_responses_attempt_id_fkey foreign key (attempt_id) references quiz_attempts (id) on delete cascade,
    constraint question_responses_question_id_fkey foreign key (question_id) references questions (id) on delete cascade
  ) tablespace pg_default;

-- table PARENTS --
create table
  public.parents (
    id uuid not null default extensions.uuid_generate_v4 (),
    user_id uuid null,
    phone_number text null,
    constraint parents_pkey primary key (id),
    constraint parents_user_id_key unique (user_id),
    constraint parents_user_id_fkey foreign key (user_id) references users (id) on delete cascade
  ) tablespace pg_default;

-- table MODULES --
create table
  public.modules (
    id uuid not null default extensions.uuid_generate_v4 (),
    course_id uuid null,
    name text not null,
    description text null,
    order_index integer null default 0,
    is_active boolean null default true,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    updated_at timestamp with time zone not null default timezone ('utc'::text, now()),
    constraint modules_pkey primary key (id),
    constraint modules_course_id_fkey foreign key (course_id) references courses (id) on delete cascade
  ) tablespace pg_default;

create trigger handle_modules_updated_at before
update on modules for each row
execute function handle_updated_at ();

-- table COURSES --
create table
  public.modules (
    id uuid not null default extensions.uuid_generate_v4 (),
    course_id uuid null,
    name text not null,
    description text null,
    order_index integer null default 0,
    is_active boolean null default true,
    created_at timestamp with time zone not null default timezone ('utc'::text, now()),
    updated_at timestamp with time zone not null default timezone ('utc'::text, now()),
    constraint modules_pkey primary key (id),
    constraint modules_course_id_fkey foreign key (course_id) references courses (id) on delete cascade
  ) tablespace pg_default;

create trigger handle_modules_updated_at before
update on modules for each row
execute function handle_updated_at ();

-- table COURSE_ENROLLMENTS --
create table
  public.course_enrollments (
    id uuid not null default extensions.uuid_generate_v4 (),
    student_id uuid null,
    course_id uuid null,
    enrolled_date timestamp with time zone not null default timezone ('utc'::text, now()),
    completed boolean null default false,
    completion_date timestamp with time zone null,
    constraint course_enrollments_pkey primary key (id),
    constraint course_enrollments_student_id_course_id_key unique (student_id, course_id),
    constraint course_enrollments_course_id_fkey foreign key (course_id) references courses (id) on delete cascade,
    constraint course_enrollments_student_id_fkey foreign key (student_id) references students (id) on delete cascade
  ) tablespace pg_default;

-- POLICY --
--
CREATE POLICY "Permettre l'upload aux étudiants authentifiés"
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'tp-submissions');

CREATE POLICY "Permettre la lecture à tous"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'tp-submissions');

--
CREATE POLICY "Seuls les admins peuvent insérer des étudiants" 
ON public.teachers 
FOR INSERT 
WITH CHECK (
  auth.uid() IN (
    SELECT id FROM public.users WHERE user_type = 'admin'
  )
);

--
-- Créer une fonction PostgreSQL pour calculer les rangs
create or replace function calculate_student_rankings()
returns table (
  student_id uuid,
  full_name text,
  total_points bigint,
  rank bigint
) language sql as $$
  WITH student_points AS (
    SELECT 
      s.id as student_id,
      u.name,
      COALESCE(
        (SELECT SUM(qr.points_earned)
         FROM question_responses qr
         JOIN quiz_attempts qa ON qr.attempt_id = qa.id
         WHERE qa.student_id = s.id), 0
      ) +
      COALESCE(
        (SELECT SUM(ts.grade)
         FROM tp_submissions ts
         WHERE ts.student_id = s.id), 0
      ) as total_points
    FROM students s
    JOIN users u ON s.user_id = u.id
  )
  SELECT 
    student_id,
    name,
    total_points,
    RANK() OVER (ORDER BY total_points DESC) as rank
  FROM student_points
  ORDER BY rank ASC;
$$;

--
-- Politique pour les comptages
create policy "Enable read for authenticated users"
on "public"."users"
for select 
to authenticated
using (true);

create policy "Enable read for authenticated users"
on "public"."courses"
for select 
to authenticated
using (true);

--
-- Politiques pour la table users
create policy "Users can view their own data"
on public.users for select
using (auth.uid() = id);

create policy "Users can update their own data"
on public.users for update
using (auth.uid() = id);

create policy "Admin can view all users"
on public.users for select
using (
  exists (
    select 1 from public.users where id = auth.uid() and user_type = 'admin'
  )
);

create policy "Admin can update all users"
on public.users for update
using (
  exists (
    select 1 from public.users where id = auth.uid() and user_type = 'admin'
  )
);

-- Politiques pour la table students
create policy "Students can view their own profile"
on public.students for select
using (user_id = auth.uid());

create policy "Teachers can view their students"
on public.students for select
using (
  exists (
    select 1 from public.teachers t
    join public.teacher_courses tc on t.id = tc.teacher_id
    join public.course_enrollments ce on tc.course_id = ce.course_id
    where t.user_id = auth.uid() and ce.student_id = students.id
  )
);

create policy "Parents can view their children"
on public.students for select
using (
  exists (
    select 1 from public.parents where user_id = auth.uid() and id = students.parent_id
  )
);

-- Politiques pour les courses
create policy "Anyone can view active courses"
on public.courses for select
using (is_active = true);

create policy "Teachers can create courses"
on public.courses for insert
with check (
  exists (
    select 1 from public.teachers where user_id = auth.uid()
  )
);

create policy "Teachers can update their own courses"
on public.courses for update
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    where tc.course_id = courses.id and t.user_id = auth.uid()
  )
);

-- Politiques pour les modules
create policy "Anyone can view active modules"
on public.modules for select
using (is_active = true);

create policy "Teachers can manage their course modules"
on public.modules for all
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    where tc.course_id = modules.course_id and t.user_id = auth.uid()
  )
);

-- Politiques pour les quiz
create policy "Students can view available quizzes"
on public.quizzes for select
using (
  exists (
    select 1 from public.course_enrollments ce
    join public.modules m on m.course_id = ce.course_id
    join public.students s on s.id = ce.student_id
    where m.id = quizzes.module_id 
    and s.user_id = auth.uid()
    and quizzes.is_active = true
  )
);

create policy "Teachers can manage their quizzes"
on public.quizzes for all
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    join public.modules m on m.course_id = tc.course_id
    where m.id = quizzes.module_id and t.user_id = auth.uid()
  )
);

-- Politiques pour les questions
create policy "Questions visible with quiz access"
on public.questions for select
using (
  exists (
    select 1 from public.quizzes q
    where q.id = questions.quiz_id and q.is_active = true
  )
);

create policy "Teachers can manage questions"
on public.questions for all
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    join public.modules m on m.course_id = tc.course_id
    join public.quizzes q on q.module_id = m.id
    where q.id = questions.quiz_id and t.user_id = auth.uid()
  )
);

-- Politiques pour les quiz_attempts
create policy "Students can view their own attempts"
on public.quiz_attempts for select
using (
  exists (
    select 1 from public.students s
    where s.id = quiz_attempts.student_id and s.user_id = auth.uid()
  )
);

create policy "Students can create quiz attempts"
on public.quiz_attempts for insert
with check (
  exists (
    select 1 from public.students s
    where s.id = quiz_attempts.student_id and s.user_id = auth.uid()
  )
);

create policy "Teachers can view their students' attempts"
on public.quiz_attempts for select
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    join public.modules m on m.course_id = tc.course_id
    join public.quizzes q on q.module_id = m.id
    where q.id = quiz_attempts.quiz_id and t.user_id = auth.uid()
  )
);

-- Politiques pour les TPs
create policy "Students can view available TPs"
on public.tps for select
using (
  exists (
    select 1 from public.course_enrollments ce
    join public.modules m on m.course_id = ce.course_id
    join public.students s on s.id = ce.student_id
    where m.id = tps.module_id 
    and s.user_id = auth.uid()
    and tps.is_active = true
  )
);

create policy "Teachers can manage TPs"
on public.tps for all
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    join public.modules m on m.course_id = tc.course_id
    where m.id = tps.module_id and t.user_id = auth.uid()
  )
);

-- Politiques pour les TP submissions
create policy "Students can manage their own submissions"
on public.tp_submissions for all
using (
  exists (
    select 1 from public.students s
    where s.id = tp_submissions.student_id and s.user_id = auth.uid()
  )
);

create policy "Teachers can view and grade submissions"
on public.tp_submissions for all
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    join public.modules m on m.course_id = tc.course_id
    join public.tps tp on tp.module_id = m.id
    where tp.id = tp_submissions.tp_id and t.user_id = auth.uid()
  )
);

-- Politiques pour les storage buckets
create policy "Students can upload their TP files"
on storage.objects for insert
with check (
  bucket_id = 'tp_files' and
  exists (
    select 1 from public.students where user_id = auth.uid()
  )
);

create policy "Users can read their own files"
on storage.objects for select
using (
  bucket_id = 'tp_files' and
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- Politiques pour course_enrollments
create policy "Students can view their enrollments"
on public.course_enrollments for select
using (
  exists (
    select 1 from public.students s
    where s.id = course_enrollments.student_id and s.user_id = auth.uid()
  )
);

create policy "Teachers can view their course enrollments"
on public.course_enrollments for select
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    where tc.course_id = course_enrollments.course_id and t.user_id = auth.uid()
  )
);

-- Politiques pour question_responses
create policy "Students can manage their own responses"
on public.question_responses for all
using (
  exists (
    select 1 from public.quiz_attempts qa
    join public.students s on s.id = qa.student_id
    where qa.id = question_responses.attempt_id and s.user_id = auth.uid()
  )
);

create policy "Teachers can view responses for their quizzes"
on public.question_responses for select
using (
  exists (
    select 1 from public.teacher_courses tc
    join public.teachers t on t.id = tc.teacher_id
    join public.modules m on m.course_id = tc.course_id
    join public.quizzes q on q.module_id = m.id
    join public.quiz_attempts qa on qa.quiz_id = q.id
    where qa.id = question_responses.attempt_id and t.user_id = auth.uid()
  )
);
