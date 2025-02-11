<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Welcome to Financial Advisor</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; text-align: center;">

    <div style="max-width: 600px; margin: 0 auto; background: #ffffff; padding: 30px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); text-align: center;">
        <h2 style="color: #007BFF; font-size: 24px;">Welcome to Financial Advisor</h2>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Hi {{ $user->name }},</p>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">We’re excited to have you on board! Financial Advisor helps you take control of your finances with powerful insights and planning tools.</p>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Start by exploring your dashboard:</p>

        <a href="http://localhost:4200/dashboard" style="display: inline-block; background-color: #007BFF; color: #ffffff; padding: 14px 24px; text-decoration: none; font-size: 16px; font-weight: bold; border-radius: 50px; margin-top: 20px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);">Go to Dashboard</a>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Need help? <a href="mailto:support@financial-advisor.com" style="color: #007BFF; text-decoration: none;">Contact Support</a></p>

        <p style="color: #888; font-size: 14px; margin-top: 20px; border-top: 1px solid #ddd; padding-top: 15px;">&copy; {{ date('Y') }} Financial Advisor. All rights reserved.</p>
    </div>

</body>
</html>
