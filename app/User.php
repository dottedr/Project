<?php

namespace App;

use Illuminate\Notifications\Notifiable;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    use Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     *
     */
    protected $guard = 'web';
    protected $fillable = [
        'isadmin','verified','name',  'email', 'password', 'holiday_allowance', 'holidays_taken', 'comment', 'role'
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'password', 'remember_token',
    ];
    public function holidayRequest()
    {
        return $this->hasMany('App\HolidayRequest', "id", "created_by");
    }
    public function verifyUser()
    {
        return $this->hasOne('App\VerifyUser');
    }

}
