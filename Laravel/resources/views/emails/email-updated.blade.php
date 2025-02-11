<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Email Updated</title>
</head>
<body style="font-family: Arial, sans-serif !important; background-color: #f4f4f4 !important; margin: 0 !important; padding: 0 !important;">

    <div style="max-width: 600px !important; margin: 30px auto !important; background: #ffffff !important; padding: 30px !important; border-radius: 10px !important; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1) !important; text-align: center !important;">

        <div style="font-size: 22px !important; font-weight: bold !important; color: #333 !important; padding-bottom: 15px !important; border-bottom: 2px solid #007BFF !important;">
            Your Email Has Been Updated
        </div>

        <div style="color: #555 !important; font-size: 16px !important; line-height: 1.6 !important; padding: 20px !important;">
            <p>Hi {{ $user->name }},</p>
            <p>Your account email has been successfully updated from <b>{{ $oldEmail }}</b> to <b>{{ $user->email }}</b>.</p>
            <p>If you did not request this change, please contact support immediately.</p>

            <a href="mailto:support@financial-advisor.com"
               style="display: inline-block !important; background-color: #007BFF !important;
                      color: #ffffff !important; padding: 14px 28px !important; text-decoration: none !important;
                      font-size: 16px !important; font-weight: bold !important; border-radius: 50px !important; margin-top: 20px !important;
                      transition: all 0.3s ease-in-out !important; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2) !important;
                      text-align: center !important; border: none !important;">
                Contact Support
            </a>

            <p>If you changed your email, you can ignore this email.</p>
        </div>

        <div style="margin-top: 20px !important; font-size: 14px !important; color: #888 !important; padding-top: 15px !important; border-top: 1px solid #ddd !important;">
            &copy; {{ date('Y') }} Financial Advisor. All rights reserved.
        </div>

    </div>

</body>
</html>
