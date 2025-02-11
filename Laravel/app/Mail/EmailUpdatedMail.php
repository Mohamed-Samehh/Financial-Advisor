<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class EmailUpdatedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $user;
    public $oldEmail;

    public function __construct($user, $oldEmail)
    {
        $this->user = $user;
        $this->oldEmail = $oldEmail;
    }

    public function build()
    {
        return $this->subject('Your Email Has Been Updated')
                    ->view('emails.email-updated')
                    ->with([
                        'user' => $this->user,
                        'oldEmail' => $this->oldEmail
                    ]);
    }
}

