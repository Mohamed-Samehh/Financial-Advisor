<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class ResetPasswordMail extends Mailable
{
    use Queueable, SerializesModels;

    public $user;
    public $newPassword;

    public function __construct($user, $newPassword)
    {
        $this->user = $user;
        $this->newPassword = $newPassword;
    }

    public function build()
    {
        return $this->subject('Your Password Has Been Reset')
                    ->view('emails.reset-password')
                    ->with([
                        'user' => $this->user,
                        'newPassword' => $this->newPassword,
                    ]);
    }
}
