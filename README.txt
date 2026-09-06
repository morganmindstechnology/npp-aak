
NPP A.A.K. DATABASE V3
=======================

WHAT THIS PACKAGE DOES
----------------------
This creates the database foundation for the NPP A.A.K. Abura–Asebu Kwamankese
constituency app:

- PostgreSQL database in Supabase
- Membership applications
- Electoral areas
- Branches
- Leadership
- News
- Events
- Policies
- Photo/video media records
- Notifications
- Contact messages
- Admin roles
- Audit-log table
- Row Level Security (RLS)
- Admin dashboard login
- Public web/mobile-friendly front end

FILES
-----
1. database.sql
   Run this in Supabase SQL Editor.

2. config.example.js
   Copy to config.js and enter your Supabase URL and publishable key.

3. index.html
   Public app/website front end.

4. admin.html
   Secure admin dashboard front end.

5. logo.jpg
   NPP A.A.K. logo used by the front end.

SETUP
-----
A. Create a Supabase project.
B. Open SQL Editor and run database.sql.
C. In Authentication -> Users, create your first administrator user.
D. Copy that user's UUID.
E. In SQL Editor run:

   INSERT INTO public.admin_roles (user_id, role)
   VALUES ('PASTE-UUID-HERE', 'admin');

F. Copy config.example.js to config.js and replace:
   YOUR-PROJECT
   YOUR-PUBLISHABLE-KEY

G. Host the folder on a web host.
H. Put the public URL into AppCreator24 as a Web section.

IMPORTANT SECURITY
------------------
- NEVER put the Supabase service-role/secret key in HTML or JavaScript.
- Only use the publishable/anon key in the browser.
- RLS is enabled in the SQL.
- Membership records are not publicly readable.
- Political-affiliation/membership information is sensitive. Limit administrator
  access, collect only what is necessary, publish a privacy notice, and establish
  a lawful basis/consent process appropriate to your operation.
- Add CAPTCHA/rate limiting before public launch to reduce spam.
- Back up and test recovery.
- Use HTTPS hosting.

APP CREATOR 24
--------------
Use AppCreator24's Web section to open the hosted public index.html.
The native AppCreator24 Users/Chat features can remain separate for community
interaction. Do not try to use browser localStorage as the membership database.

NEXT PRODUCTION STEP
--------------------
Add:
- document/photo storage bucket
- secure Edge Function for membership submissions
- CAPTCHA/rate limiting
- admin CRUD for all tables
- CSV export restricted to admins
- audit logging on sensitive admin actions
- privacy policy and retention/deletion workflow
- notification delivery
