NPP A.A.K. DATABASE V4

Supabase connection is embedded directly in index.html and admin.html, so config.js is not required.

IMPORTANT:
- The browser key must be a Supabase publishable/anon public key.
- Never put a service-role/secret key in browser code.
- Run database.sql in Supabase SQL Editor before testing.
- Create an Auth user and add its UUID to public.admin_roles.
- Host these files on HTTPS and use the hosted public URL in AppCreator24 Web section.
