# Deployment Automation

This project implements deployment automation, aiming to simplify and automate the deployment process for both application code and associated database management. The process assumes the existence of a backup mechanism and an archive folder for storing backups.

## Scope

The deployment automation process includes the following steps:

1. **Backup**: Create a backup of the current deployment by copying the relevant files. The user specifies the directories for backup.
2. **Compression**: Compress the backup into a zip file for easier storage and move it to the designated archive folder.
3. **Deployment**: Unzip and move the new release to the deployment folder to prepare it for deployment.
4. **Validation**: Perform manual validation of the deployed release to ensure proper functionality and identify any issues or bugs.
5. **Revert**: Allow for reverting the deployment and re-deploying the last release from the backup in case of issues. This step involves restoring the backup files and configuring the environment accordingly.
6. **Logging**: Generate and maintain logs throughout the deployment process to track the steps performed, changes made, and encountered issues.

## Prerequisites / Assumptions

- Data in the source file should be in the format of `name.zip`, and there should be only one `.zip` file in the source folder.
- Open PowerShell as an administrator.
- The deployment folder should be empty for a backup file to be created.
- The website should be stopped on IIS before deploying a new release.

## How to Start?

1. Input the username.
2. Enter the backup path (e.g., `D:\projectDotnet\book`).
3. Enter the website path.
4. Enter the source file path.

**Exceptions**: If a user wants to revert, they will be prompted with the option to revert the deployment. If there are any pop-ups, click "Yes to All."

## Validations

- If the entered path does not exist, the user will be prompted with an error and asked to enter the correct path.
- If the source folder is empty, the user will be asked to enter the path again where the file is located.
- While reverting, if the name of the backup file is incorrect, the user will be prompted again to enter the correct file name from the list of given zip files.
- If the deployment folder does not contain any files, no backup will be created.
- If the backup folder does not contain any zip files, the user will be asked again to enter the folder where the backup file is stored.

## Overall Goal

### Tasks

**Scope Definition**

- Manually Deployment
  - Take backup and move it into a separate folder
  - Deploy the new release
  - Execute any required scripts
  - Perform manual validation of the new changes

**Automate the Deployment**

**1st Part**

1. Take the backup of the existing deployment.
2. Zip the backup and move it into the archive folder.
3. Unzip the new release.
4. Deploy the release.
5. Manually validate the deployed release.
6. Revert the deployment and deploy the release from the backup if needed.

**2nd Part**

1. Take the database schema and data of the affected table.
2. Execute the database scripts.
3. Revert the database scripts in case of release revert.
4. Create the new website and deploy the release.
5. Maintain logs for backtracking.

