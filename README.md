# Automatic Account Creatino AD

A script that reads users from a text file, applies optional custom attributes, validates entries to prevent duplicates, and creates Active Directory users with generated email addresses and logon names.

## Features

- Fetches users from a text list.
- Allows custom values for each user:  
**USER:Department=VALUE:Description=VALUE**
- Creates a custom email address and logon name for each user.
- Displays all users before creation and skips duplicate users.
- Creates an AD user for each entry, when no errors are detected.

## Setup
## 1. Clone the repository
```bash
git clone https://github.com/SinRise-Git/powershell-automatic-account-creation-AD.git
```
## 2. Move to the repository 
```bash
cd powershell-automatic-account-creation-ad
```

## 3. Add users to userlist.txt 
Add as many users as you want to ```userlist.txt```. If you want to set specific values for a user, define them like this: <br>**USER:Department=VALUE:Description=VALUE**<br>
Any value inside ```$userData``` can be changed in this manner. 

## 4. Change values in script
Change the values inside ```$Defaults [PSCustomObject]@``` to match your AD setup, and update  ```$fullDomain``` to match your domain. Set the OU in ```OU=Example``` to the organizational unit where you want the users to be created. The remaining values can be changed as needed. You can also add additional properties to. You can also add more values inside  ```$Defaults[PSCustomObject]@```, ```$userData[ordered]@``` and ```New-ADUser``` if you want to apply more settings when an account is being created.

## 5. Run the script
In the terminal run:
```bash
.\createUsersAD.ps1
```
The script will attempt to create all users listed in its input.

If a user already exists or another error occurs, it will display an error message for that user and skip creating that account, continuing with the rest.