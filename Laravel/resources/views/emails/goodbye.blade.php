<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Goodbye from Financial Advisor</title>
</head>
<body style="font-family: Arial, sans-serif !important; background-color: #f4f4f4 !important; margin: 0 !important; padding: 0 !important;">

    <div style="max-width: 600px !important; margin: 30px auto !important; background: #ffffff !important; padding: 30px !important; border-radius: 10px !important; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1) !important; text-align: center !important;">

        <div style="font-size: 22px !important; font-weight: bold !important; color: #333 !important; padding-bottom: 15px !important; border-bottom: 2px solid #008080 !important;">
            Goodbye from Financial Advisor
        </div>

        <div style="color: #555 !important; font-size: 16px !important; line-height: 1.6 !important; padding: 20px !important;">
            <p>Hi {{ $user->name }},</p>
            <p>We're sad to see you go, but we respect your decision.</p>
            <p>Thank you for being part of our community. If you ever decide to come back, we’d love to welcome you again.</p>
            <p>If you have any feedback, feel free to let us know.</p>

            <a href="mailto:support@financial-advisor.com"
               style="display: inline-block !important; background-color: #008080 !important;
                      color: #ffffff !important; padding: 14px 28px !important; text-decoration: none !important;
                      font-size: 16px !important; font-weight: bold !important; border-radius: 50px !important; margin-top: 20px !important;
                      transition: all 0.3s ease-in-out !important; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2) !important;
                      text-align: center !important; border: none !important;">
                Share Feedback
            </a>

            <p>Wishing you all the best!</p>
        </div>

        <div style="margin-top: 20px !important; font-size: 14px !important; color: #888 !important; padding-top: 15px !important; border-top: 1px solid #ddd !important;">
            &copy; {{ date('Y') }} Financial Advisor. All rights reserved.
        </div>

    </div>

</body>
</html>
