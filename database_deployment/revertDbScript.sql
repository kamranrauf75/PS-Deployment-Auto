UPDATE logk SET phone = '022244' WHERE computerName = 'testcomp';
DELETE FROM logk WHERE appName = '9' AND computerName = 'testcomp' AND CAST(details AS nvarchar(max)) = 'testdetails';
DELETE FROM logk WHERE appName = '8' AND computerName = 'testcomp34' AND CAST(details AS nvarchar(max)) = 'testdetails54';
DELETE FROM logk WHERE appName = '12' AND computerName = 'testcom435p' AND CAST(details AS nvarchar(max)) = 'testdetails643';
