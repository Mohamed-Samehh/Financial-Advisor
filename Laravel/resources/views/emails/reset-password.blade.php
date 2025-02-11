<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Password Reset</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0;">
    <div style="max-width: 600px; margin: 30px auto; background: #ffffff; padding: 30px; border-radius: 10px;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); text-align: center;">

        <div style="font-size: 22px; font-weight: bold; color: #333; padding-bottom: 15px;
                    border-bottom: 2px solid #C70039;">
            Password Reset Successful
        </div>

        <div style="color: #555; font-size: 16px; line-height: 1.6; padding: 20px;">
            <p>Hi {{ $user->name }},</p>
            <p>Your password has been successfully reset. Below is your new temporary password:</p>

            <div style="background: #C70039; color: #ffffff; display: inline-block; padding: 10px 20px;
                        font-size: 18px; font-weight: bold; border-radius: 5px; margin: 20px 0;">
                {{ $newPassword }}
            </div>

            <p>For security reasons, please log in and change your password immediately.</p>

            <a href="http://localhost:4200/account"
               style="display: inline-block; background-color: #C70039;
                      color: #ffffff !important; padding: 14px 28px; text-decoration: none;
                      font-size: 16px; font-weight: bold; border-radius: 50px; margin-top: 20px;
                      transition: all 0.3s ease-in-out; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
                      text-align: center; border: none;">
                Change Password
            </a>

            <p>If you did not request this change,
                <a href="mailto:support@financial-advisor.com"
                   style="color: #C70039; text-decoration: none;">
                    contact support
                </a> immediately.
            </p>
        </div>

        <div style="margin-top: 20px; font-size: 14px; color: #888; padding-top: 15px; border-top: 1px solid #ddd;">
            &copy; {{ date('Y') }} Financial Advisor. All rights reserved.
        </div>
    </div>
</body>
</html>
