-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Marie', 'katelyn.nettles@gmail.com', 'Marie', 'f333ba2f-e584-467e-9535-b828c4ba13a8'),
  ('kate nettles', 'katelyn_nett06@yahoo.com', 'katenettles', '04fae33c-a228-41d4-9a21-f3a76b6f0ce3');
  ('Steven Universe', 'SUniverse23@magiccity.com', 'StevenUniverse', 'f4d45a29-af5a-4db6-bf5b-8e2036e0424d
');


INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'Marie' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )