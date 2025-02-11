<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Goodbye from Financial Advisor</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; text-align: center;">

    <div style="max-width: 600px; margin: 0 auto; background: #ffffff; padding: 30px; border-radius: 10px;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); text-align: center;">

        <h2 style="color: #008080; font-size: 24px;">Goodbye from Financial Advisor</h2>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Hi {{ $user->name }},</p>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">We're sad to see you go, but we respect your decision.</p>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Thank you for being part of our community. If you ever decide to come back, we’d love to welcome you again.</p>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">If you have any feedback, feel free to let us know.</p>

        <a href="mailto:support@financial-advisor.com"
           style="display: inline-block; background-color: #008080;
                  color: #ffffff; padding: 14px 28px; text-decoration: none;
                  font-size: 16px; font-weight: bold; border-radius: 50px; margin-top: 20px;
                  transition: all 0.3s ease-in-out; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);">
            Share Feedback
        </a>

        <p style="color: #555; font-size: 16px; line-height: 1.6;">Wishing you all the best!</p>

        <p style="color: #888; font-size: 14px; margin-top: 20px; border-top: 1px solid #ddd; padding-top: 15px;">
            &copy; {{ date('Y') }} Financial Advisor. All rights reserved.
        </p>
    </div>

</body>
</html>
