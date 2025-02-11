<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Password Reset</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; text-align: center;">
    <div style="max-width: 600px; margin: 0 auto; background: #ffffff; padding: 30px; border-radius: 10px;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); text-align: center;">

        <h2 style="color: #D50032; font-size: 24px;">Password Reset Successful</h2>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Hi {{ $user->name }},</p>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Your password has been successfully reset. Below is your new temporary password:</p>

        <div style="background: #D50032; color: #ffffff; display: inline-block; padding: 10px 20px;
                    font-size: 18px; font-weight: bold; border-radius: 5px; margin: 20px 0;">
            {{ $newPassword }}
        </div>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">For security reasons, please log in and change your password immediately.</p>

        <a href="http://localhost:4200/account"
           style="display: inline-block; background-color: #D50032;
                  color: #ffffff; padding: 14px 28px; text-decoration: none;
                  font-size: 16px; font-weight: bold; border-radius: 50px; margin-top: 20px;
                  transition: all 0.3s ease-in-out; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);">
            Change Password
        </a>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">If you did not request this change,
            <a href="mailto:support@financial-advisor.com"
               style="color: #D50032; text-decoration: none;">
                contact support
            </a> immediately.
        </p>

        <p style="color: #888; font-size: 14px; margin-top: 20px; border-top: 1px solid #ddd; padding-top: 15px;">
            &copy; {{ date('Y') }} Financial Advisor. All rights reserved.
        </p>
    </div>
</body>
</html>
