<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Welcome to Financial Advisor</title>
</head>
<body style="font-family: 'Arial', sans-serif; background-color: #f4f4f4; margin: 0; padding: 0;">
    <div style="max-width: 600px; margin: 30px auto; background: #ffffff; padding: 30px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);">
        <div style="text-align: center; font-size: 22px; font-weight: bold; color: #333; padding-bottom: 15px; border-bottom: 2px solid #007BFF;">
            Welcome to Financial Advisor
        </div>
        <div style="text-align: center; color: #555; font-size: 16px; line-height: 1.6; padding: 20px;">
            <p>Hi {{ $user->name }},</p>
            <p>We’re excited to have you on board! Financial Advisor helps you take control of your finances with powerful insights and planning tools.</p>
            <p>Start by exploring your dashboard:</p>
            <a href="http://localhost:4200/dashboard"
               style="display: inline-block; background-color: #007BFF; color: #ffffff; padding: 14px 24px; text-decoration: none;
                      font-size: 16px; font-weight: bold; border-radius: 50px; margin-top: 20px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
                      text-align: center;">
                Go to Dashboard
            </a>
            <p>Need help? <a href="mailto:support@financial-advisor.com" style="color: #007BFF; text-decoration: none;">Contact Support</a></p>
        </div>
        <div style="margin-top: 20px; font-size: 14px; text-align: center; color: #888; padding-top: 15px; border-top: 1px solid #ddd;">
            &copy; {{ date('Y') }} Financial Advisor. All rights reserved.
        </div>
    </div>
</body>
</html>
